import axios from "axios";
import store from "../store/store";
import { logout, setToken } from "../slice/auth/authSlice";

/** Run refresh every 12 min so access token (e.g. 15m) never expires during use */
const PROACTIVE_REFRESH_INTERVAL_MS = 12 * 60 * 1000;
/** Delay first refresh after login/hydrate so refresh cookie is attached (avoids intermittent 401) */
const FIRST_REFRESH_DELAY_MS = 3000;

/**
 * True for RFC1918 / typical LAN hostnames so admin opened at http://192.168.x.x:5173
 * talks to the same machine's API at http://192.168.x.x:5050 (not the phone's localhost).
 */
function isLikelyLanHostname(hostname) {
  if (!hostname) return false;
  const h = String(hostname).toLowerCase();
  if (h === "localhost" || h === "127.0.0.1") return false;
  if (h.endsWith(".local")) return true;
  if (/^192\.168\.\d{1,3}\.\d{1,3}$/.test(h)) return true;
  if (/^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(h)) return true;
  if (/^172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}$/.test(h)) return true;
  return false;
}

/**
 * API base URL: يختار تلقائياً حسب المكان (محلي أو لايف) بدون تغيير يدوي
 * - من localhost → http://localhost:5050
 * - من نفس الـ IP على الشبكة (مثلاً فتح الأدمن من الموبايل) → http://THAT_IP:5050
 * - من orderzhouse.com → https://orderzhouse-backend.onrender.com
 * - override: VITE_APP_API_URL (أولوية عند التعريف)
 */
export function getApiBaseURL() {
  const fromEnv = import.meta.env.VITE_APP_API_URL;
  if (typeof fromEnv === "string" && fromEnv.trim()) {
    return fromEnv.trim().replace(/\/$/, "");
  }

  if (typeof window !== "undefined") {
    const host = window.location.hostname;
    if (host === "localhost" || host === "127.0.0.1") return "http://localhost:5050";
    if (host === "orderzhouse.com" || host === "www.orderzhouse.com") {
      return "https://orderzhouse-backend.onrender.com";
    }
    if (isLikelyLanHostname(host)) {
      const apiPort = import.meta.env.VITE_APP_API_PORT || "5050";
      return `http://${host}:${apiPort}`;
    }
  }
  return "http://localhost:5050";
}

const baseURL = getApiBaseURL();

/** للـ WebSocket: نفس الـ host لكن بروتوكول ws/wss (يُستورد حيث يُحتاج) */
export function getWebSocketBaseURL() {
  const base = getApiBaseURL();
  return base.replace(/^http/, "ws");
}

const API = axios.create({
  baseURL,
  withCredentials: true,
  headers: { "Content-Type": "application/json" },
});

let refreshPromise = null;
let proactiveRefreshTimerId = null;
let proactiveRefreshTimeoutId = null;

async function doOneRefresh() {
  const hasSession = !!store.getState()?.auth?.isAuthenticated;
  if (!hasSession) return;
  try {
    const { data } = await API.post("/users/refresh");
    if (data?.token) store.dispatch(setToken(data.token));
  } catch (err) {
    const msg = err?.response?.data?.message || "";
    if (msg.toLowerCase().includes("missing") && err?.response?.status === 401) {
      await new Promise((r) => setTimeout(r, 1000));
      try {
        const { data: retryData } = await API.post("/users/refresh");
        if (retryData?.token) store.dispatch(setToken(retryData.token));
      } catch {
        // ignore
      }
    }
  }
}

/** Start background refresh so user is not logged out after token expiry. Call on login/hydrate. */
export function startProactiveRefresh() {
  clearProactiveRefresh();
  proactiveRefreshTimeoutId = setTimeout(() => {
    proactiveRefreshTimeoutId = null;
    doOneRefresh();
    proactiveRefreshTimerId = setInterval(doOneRefresh, PROACTIVE_REFRESH_INTERVAL_MS);
  }, FIRST_REFRESH_DELAY_MS);
}

export function clearProactiveRefresh() {
  if (proactiveRefreshTimeoutId) {
    clearTimeout(proactiveRefreshTimeoutId);
    proactiveRefreshTimeoutId = null;
  }
  if (proactiveRefreshTimerId) {
    clearInterval(proactiveRefreshTimerId);
    proactiveRefreshTimerId = null;
  }
}

// Request interceptor: always read accessToken from localStorage first so it's set before Redux updates
API.interceptors.request.use(
  (config) => {
    const token = store.getState()?.auth?.token || null;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // If FormData is being sent, remove Content-Type header to let axios/browser set it automatically
    // This ensures multipart/form-data includes the correct boundary
    if (config.data instanceof FormData) {
      delete config.headers["Content-Type"];
    }
    
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor: Handle 401 (refresh token) and 403 (terms not accepted)
API.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // Handle 403 TERMS_NOT_ACCEPTED - redirect to accept-terms page
    if (error.response?.status === 403 && error.response?.data?.code === "TERMS_NOT_ACCEPTED") {
      // Only redirect if not already on accept-terms page to avoid redirect loop
      if (typeof window !== "undefined") {
        const currentPath = window.location.pathname;
        if (currentPath !== "/accept-terms" && !currentPath.startsWith("/accept-terms")) {
          // Use replace to avoid adding to browser history
          window.location.replace("/accept-terms");
        }
      }
      return Promise.reject(error);
    }

    // Only handle 401 errors for token refresh
    if (error.response?.status !== 401) {
      return Promise.reject(error);
    }

    const isRefreshRequest = originalRequest.url?.includes("/users/refresh");
    
    // If refresh endpoint itself returns 401, check if it's due to missing cookie or invalid token
    if (isRefreshRequest) {
      refreshPromise = null;
      const errorMessage = error.response?.data?.message || "";
      
      // Only logout if refresh token is truly invalid/expired, not if it's just missing
      // This prevents logout on first 401 when cookie might not be sent yet
      if (errorMessage.includes("Invalid or expired") || errorMessage.includes("expired")) {
        if (process.env.NODE_ENV === "development") {
          console.warn("🔄 Refresh token invalid/expired, logging out");
        }
        clearProactiveRefresh();
        store.dispatch(logout());
      } else if (process.env.NODE_ENV === "development") {
        console.warn("🔄 Refresh token missing, but not logging out (might be cookie issue)");
      }
      return Promise.reject(error);
    }

    // Prevent infinite retry loops
    if (originalRequest._retryAfterRefresh) {
      if (process.env.NODE_ENV === "development") {
        console.warn("🔄 Already retried after refresh, not retrying again");
      }
      clearProactiveRefresh();
      store.dispatch(logout());
      return Promise.reject(error);
    }

    // Attempt to refresh token
    try {
      if (!refreshPromise) {
        refreshPromise = API.post("/users/refresh");
      }
      const { data } = await refreshPromise;
      refreshPromise = null;
      const newToken = data?.token;

      if (newToken) {
        store.dispatch(setToken(newToken));
        startProactiveRefresh();
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        originalRequest._retryAfterRefresh = true;

        if (process.env.NODE_ENV === "development") {
          console.log("✅ Token refreshed, retrying original request");
        }

        return API(originalRequest);
      } else {
        throw new Error("No token in refresh response");
      }
    } catch (refreshError) {
      const refreshErrorMessage = String(refreshError.response?.data?.message || "").toLowerCase();
      const isMissing = refreshErrorMessage.includes("missing");

      if (isMissing) {
        refreshPromise = null;
        await new Promise((r) => setTimeout(r, 1000));
        try {
          const retryRes = await API.post("/users/refresh");
          const newToken = retryRes?.data?.token;
          if (newToken) {
            store.dispatch(setToken(newToken));
            startProactiveRefresh();
            originalRequest.headers.Authorization = `Bearer ${newToken}`;
            originalRequest._retryAfterRefresh = true;
            return API(originalRequest);
          }
        } catch (_) {}
      }

      refreshPromise = null;
      // Only logout if refresh truly failed (invalid/expired token), not on "missing" after retry
      if (
        refreshErrorMessage.includes("invalid or expired") ||
        refreshErrorMessage.includes("expired")
      ) {
        if (process.env.NODE_ENV === "development") {
          console.warn("🔄 Refresh failed with invalid token, logging out");
        }
        clearProactiveRefresh();
        store.dispatch(logout());
      } else if (process.env.NODE_ENV === "development") {
        console.warn("🔄 Refresh failed but not logging out (might be temporary):", refreshErrorMessage);
      }
    }

    return Promise.reject(error);
  }
);

export default API;
