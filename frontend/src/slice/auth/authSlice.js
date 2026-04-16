import { createSlice } from "@reduxjs/toolkit";

const STORAGE_KEYS = {
  USER_INFO: "userInfo",
};

function readFromStorage() {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.USER_INFO);
    let userInfo = null;
    if (raw && raw !== "undefined" && raw !== "null") {
      userInfo = JSON.parse(raw);
    }
    return { token: null, userInfo };
  } catch (e) {
    console.error("authSlice readFromStorage:", e);
    return { token: null, userInfo: null };
  }
}

const { token: initialToken, userInfo: initialUser } = readFromStorage();

const initialState = {
  token: initialToken,
  user: initialUser,
  isAuthenticated: !!initialToken,
  isAuthReady: false,
  // Backward compatibility (derived from user)
  userData: initialUser,
  userId: initialUser?.id ?? initialUser?.userId ?? initialUser?.user_id ?? null,
  roleId: initialUser?.role_id ?? initialUser?.roleId ?? initialUser?.role ?? null,
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    loginSuccess(state, action) {
      const { token, userInfo } = action.payload;
      if (!token) return;
      state.token = token;
      state.user = userInfo ?? state.user;
      state.isAuthenticated = true;
      state.isAuthReady = true;
      state.userData = state.user;
      state.userId = state.user?.id ?? state.user?.userId ?? state.user?.user_id ?? null;
      state.roleId = state.user?.role_id ?? state.user?.roleId ?? state.user?.role ?? null;
      if (userInfo != null) {
        localStorage.setItem(STORAGE_KEYS.USER_INFO, JSON.stringify(userInfo));
      }
    },

    logout(state) {
      state.token = null;
      state.user = null;
      state.isAuthenticated = false;
      state.userData = null;
      state.userId = null;
      state.roleId = null;
      localStorage.removeItem(STORAGE_KEYS.USER_INFO);
    },

    setAuthFromStorage(state, action) {
      const { token, userInfo } = action.payload ?? {};
      state.token = token ?? null;
      state.user = userInfo ?? null;
      state.isAuthenticated = !!(state.token);
      state.isAuthReady = true;
      state.userData = state.user;
      state.userId = state.user?.id ?? state.user?.userId ?? state.user?.user_id ?? null;
      state.roleId = state.user?.role_id ?? state.user?.roleId ?? state.user?.role ?? null;
    },

    setToken(state, action) {
      const t = action.payload;
      state.token = t ?? null;
      state.isAuthenticated = !!state.token;
    },

    setUserData(state, action) {
      const userInfo = action.payload;
      state.user = userInfo ?? null;
      state.userData = state.user;
      state.userId = state.user?.id ?? state.user?.userId ?? state.user?.user_id ?? null;
      state.roleId = state.user?.role_id ?? state.user?.roleId ?? state.user?.role ?? null;
      if (userInfo != null) {
        localStorage.setItem(STORAGE_KEYS.USER_INFO, JSON.stringify(userInfo));
      } else {
        localStorage.removeItem(STORAGE_KEYS.USER_INFO);
      }
    },
  },
});

export const {
  loginSuccess,
  logout,
  setAuthFromStorage,
  setToken,
  setUserData,
} = authSlice.actions;


/** Call on app mount to sync Redux from localStorage (and log for debug). */
export function hydrateFromStorage() {
  return (dispatch) => {
    const { userInfo } = readFromStorage();
    console.log("HYDRATE", { tokenFromStorage: false, userFromStorage: !!userInfo });
    dispatch(setAuthFromStorage({ token: null, userInfo }));
  };
}

export default authSlice.reducer;
