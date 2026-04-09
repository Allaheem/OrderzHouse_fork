/**
 * Partner referral tracking: capture ref/UTM params, store 30 days, log visit once per session, attach to signup.
 * Visit logging is idempotent: pre-request lock + done key prevent duplicate POSTs (e.g. React StrictMode).
 */

const STORAGE_KEY = "oh_partner_attribution";
const STORAGE_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days
const CLIENT_SESSION_KEY = "oh_ref_sid_client";

/** Per-source lock: set BEFORE network call so concurrent runs (e.g. StrictMode) don't send duplicate requests. */
function getVisitLockKey(sourceLower) {
  return `oh_visit_lock_${sourceLower}`;
}

/**
 * Get or create a stable client-side session_id (localStorage) so backend receives same session_id
 * even when cookie is not sent (e.g. cross-port). Backend uses cookie first, then body.session_id.
 */
function getOrCreateClientSessionId() {
  if (typeof window === "undefined") return null;
  try {
    let sid = localStorage.getItem(CLIENT_SESSION_KEY);
    if (!sid || typeof sid !== "string" || sid.length < 8) {
      sid = Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");
      localStorage.setItem(CLIENT_SESSION_KEY, sid);
    }
    return sid;
  } catch (e) {
    return null;
  }
}

/**
 * Read ref + UTM from URL (window.location or passed search string).
 * @param {string} [search] - Optional search string (e.g. location.search)
 * @returns {{ source: string|null, medium: string|null, campaign: string|null, ref: string|null, landing_path: string }}
 */
export function getAttributionFromUrl(search = typeof window !== "undefined" ? window.location.search : "") {
  const params = new URLSearchParams(search);
  const ref = params.get("ref")?.trim() || null;
  const source = params.get("utm_source")?.trim() || ref || null;
  const medium = params.get("utm_medium")?.trim() || null;
  const campaign = params.get("utm_campaign")?.trim() || null;
  const landing_path =
    typeof window !== "undefined" ? window.location.pathname + window.location.search : "";
  return { source, medium, campaign, ref, landing_path };
}

/**
 * Persist attribution in localStorage with 30-day expiry. Only stores if source or ref present.
 */
export function storeAttribution(attribution) {
  if (typeof window === "undefined") return;
  const { source, ref } = attribution;
  if (!source && !ref) return;
  try {
    const payload = {
      ...attribution,
      storedAt: Date.now(),
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch (e) {
    console.warn("partnerReferral: storeAttribution failed", e);
  }
}

/**
 * Get stored attribution if still valid (within 30 days). Returns null if expired or missing.
 */
export function getStoredAttribution() {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const data = JSON.parse(raw);
    const age = Date.now() - (data.storedAt || 0);
    if (age > STORAGE_TTL_MS) {
      localStorage.removeItem(STORAGE_KEY);
      return null;
    }
    return {
      signup_source: data.source ?? null,
      signup_medium: data.medium ?? null,
      signup_campaign: data.campaign ?? null,
      signup_ref: data.ref ?? null,
      signup_landing_path: data.landing_path ?? null,
    };
  } catch (e) {
    return null;
  }
}

/**
 * Call POST /referrals/visit on every relevant page load (including refresh). Backend records
 * each call in referral_pageviews (total visits) and referral_visits only when session is new (unique visits).
 * - lockKey: set BEFORE the network call; if set, another request is in flight (e.g. StrictMode) → skip.
 * - No "done" key: we send on every load so refresh adds a pageview.
 * - Sends session_id in body so backend can reuse it when cookie is missing (cross-port).
 * - Caller must pass apiPost with withCredentials: true so cookies are sent.
 */
export function logPartnerVisitIfNeeded(attribution, apiPost) {
  if (typeof window === "undefined") return;
  const { source, ref } = attribution;
  const rawSource = source || ref || "unknown";
  if (!source && !ref) return;

  const sourceLower = String(rawSource).trim().toLowerCase();
  const lockKey = getVisitLockKey(sourceLower);

  if (sessionStorage.getItem(lockKey)) return; // request already in flight (e.g. StrictMode double mount)

  try {
    sessionStorage.setItem(lockKey, "1");
  } catch (e) {
    return;
  }

  let baseURL = import.meta.env.VITE_APP_API_URL || "http://localhost:5050";
  if (typeof window !== "undefined") {
    const h = window.location.hostname;
    if (h === "localhost" || h === "127.0.0.1") baseURL = "http://localhost:5050";
    else if (h === "orderzhouse.com" || h === "www.orderzhouse.com") baseURL = "https://orderzhouse-backend.onrender.com";
  }
  const post =
    apiPost ||
    (async (url, body) => {
      const res = await fetch(baseURL + url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        credentials: "include",
      });
      return res.json();
    });

  const clientSessionId = getOrCreateClientSessionId();
  const payload = {
    source: rawSource,
    medium: attribution.medium ?? undefined,
    campaign: attribution.campaign ?? undefined,
    ref: attribution.ref ?? undefined,
    landing_path: attribution.landing_path || (window.location?.pathname + window.location?.search) || "",
  };
  if (clientSessionId) payload.session_id = clientSessionId;

  post("/referrals/visit", payload)
    .catch(() => {})
    .finally(() => {
      try {
        sessionStorage.removeItem(lockKey);
      } catch (e) {}
    });
}

/**
 * One-shot: read URL params, store attribution, and optionally log visit (once per session per source).
 * Call only from ONE place (App.jsx on route/search change). Do not call from Register or elsewhere.
 */
export function captureAndLogReferral(search, apiPost) {
  const attribution = getAttributionFromUrl(search);
  if (attribution.source || attribution.ref) {
    storeAttribution(attribution);
    logPartnerVisitIfNeeded(attribution, apiPost);
  }
}
