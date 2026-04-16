// src/components/login/Login.jsx
import React, { useState } from "react";
import { useDispatch } from "react-redux";
import { GoogleLogin } from "@react-oauth/google";
import { jwtDecode } from "jwt-decode";
import API, { startProactiveRefresh } from "../../api/client.js";

import { useNavigate, Link } from "react-router-dom";
import { loginSuccess, setUserData } from "../../slice/auth/authSlice";
import { connectSocket } from "../../services/socketService";
import { useToast } from "../toast/ToastProvider";
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  LogIn,
  ArrowRight,
  Shield,
  KeyRound,
} from "lucide-react";
import PageMeta from "../PageMeta.jsx";
import AuthSplitLayout from "../auth/AuthSplitLayout.jsx";
import { useAuthTransition } from "../auth/useAuthTransition.js";

/** غيّر إلى true عند تفعيل تسجيل الدخول بـ Google — حالياً مخفي */
const ENABLE_GOOGLE_LOGIN = false;

export const getDashboardPath = (roleId) => {
  switch (Number(roleId)) {
    case 1: return "/admin/dashboard";
    case 2: return "/client/dashboard";
    case 3: return "/freelancer/dashboard";
    case 4: return "/apm";
    case 5: return "/partner";
    default: return "/dashboard";
  }
};

export const applyLoginSuccess = async (dispatch, data, navigate, connectSocket) => {
  const token = data.token;
  let decoded;
  try {
    decoded = jwtDecode(token);
  } catch (_) {
    decoded = {};
  }
  let userInfo = data.userInfo ?? {
    id: decoded.userId ?? decoded.sub,
    role_id: decoded.role ?? decoded.role_id,
    username: decoded.username,
    email: decoded.email,
  };
  let roleId = userInfo.role_id ?? decoded.role ?? decoded.role_id;

  dispatch(loginSuccess({ token, userInfo }));
  startProactiveRefresh();

  if (roleId == null || roleId === "" || Number.isNaN(Number(roleId))) {
    try {
      const res = await API.get("/users/getUserdata", {
        headers: { Authorization: `Bearer ${token}` },
      });
      const fetched = res?.data?.user ?? res?.data?.data ?? res?.data?.result ?? res?.data;
      if (fetched && (fetched.role_id != null || fetched.roleId != null)) {
        const fullUser = { ...userInfo, ...fetched, role_id: fetched.role_id ?? fetched.roleId };
        dispatch(setUserData(fullUser));
        userInfo = fullUser;
        roleId = fullUser.role_id ?? fullUser.roleId;
      }
    } catch (_) {
      // Keep login flow resilient without exposing internals in console.
    }
  }

  connectSocket(token, userInfo?.id ?? decoded?.userId ?? decoded?.sub);
  // عدم إظهار لوحة قبول الشروط بعد تسجيل الدخول — التوجيه مباشرة للداشبورد
  const path = getDashboardPath(roleId);
  navigate(path, { replace: true });
};

const inputPill =
  "w-full h-12 rounded-xl bg-neutral-100 border border-transparent px-4 text-sm outline-none focus:ring-2 focus:ring-[#C2410C]/25 focus:border-[#C2410C]/30 placeholder:text-neutral-400 transition-colors";

const Login = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const toast = useToast();
  const { containerClass, go } = useAuthTransition();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [otp, setOtp] = useState("");
  const [otpMode, setOtpMode] = useState(null); // 'email' | 'app' | null
  const [tempToken, setTempToken] = useState("");

  const [message, setMessage] = useState("");
  const [status, setStatus] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const isOtpStep = otpMode !== null;

  const handleLogin = (e) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage("");

    API
      .post("/users/login", {
        email: email.toLowerCase(),
        password,
      })
      .then(async (res) => {
        setIsLoading(false);
        const data = res.data;

        // ===== 2FA (Authenticator App) =====
        if (data.requires_2fa && data.temp_token) {
          setStatus(true);
          toast.info("Enter the 6-digit code from your authenticator app.");
          setOtp("");
          setOtpMode("app");
          setTempToken(data.temp_token);
          return;
        }

        // ===== Email OTP (محاولات كثيرة أو باسورد غلط 3 مرات) =====
        if (data.requires_email_otp || (data.user_id && !data.token)) {
          setStatus(true);
          setOtp("");
          setOtpMode("email");
          return;
        }

        // ===== Login مباشر (بدون أي خطوة إضافية) =====
        if (data.token) {
          setStatus(true);
          toast.success("Login successful! Redirecting...");
          await applyLoginSuccess(dispatch, data, navigate, connectSocket);
          return;
        }

        // fallback
        setStatus(false);
        toast.error(data.message || "Unexpected response from server.");
      })
      .catch((err) => {
        setIsLoading(false);
        setStatus(false);
        const errorMessage =
          err.response?.data?.message ||
          "Login failed. Please check your credentials.";
        
        // Special handling for email verification error
        if (err.response?.status === 403 && (err.response?.data?.error === "EMAIL_NOT_VERIFIED" || errorMessage.includes("verify your email"))) {
          const userEmail = err.response?.data?.email || email;
          // Redirect to verify email page with email in URL (no toast about OTP sent)
          navigate(`/register?email=${encodeURIComponent(userEmail)}&verify=true`);
        } else {
          toast.error(errorMessage);
        }
        setOtpMode(null);
      });
  };

  const handleVerifyOtp = (e) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage("");

    // Email OTP
    if (otpMode === "email") {
      API
        .post("/users/verify-otp", {
          email: email.toLowerCase(),
          otp,
        })
        .then(async (res) => {
          setIsLoading(false);
          const data = res.data;
          setStatus(true);
          toast.success("Login successful! Redirecting...");
          await applyLoginSuccess(dispatch, data, navigate, connectSocket);
        })
        .catch((err) => {
          setIsLoading(false);
          setStatus(false);
          const errorMessage =
            err.response?.data?.message || "Invalid or expired OTP.";
          toast.error(errorMessage);
          setOtp("");
        });
      return;
    }

    // 2FA App (TOTP)
    if (otpMode === "app") {
      API
        .post("/auth/2fa/verify-login", {
          temp_token: tempToken,
          code: otp,
        })
        .then(async (res) => {
          setIsLoading(false);
          const data = res.data;
          setStatus(true);
          toast.success("Login successful! Redirecting...");
          await applyLoginSuccess(dispatch, data, navigate, connectSocket);
        })
        .catch((err) => {
          setIsLoading(false);
          setStatus(false);
          const errorMessage =
            err.response?.data?.message || "Invalid 2FA code.";
          toast.error(errorMessage);
          setOtp("");
        });
    }
  };

  const handleSubmit = (e) => {
    if (isOtpStep) {
      handleVerifyOtp(e);
    } else {
      handleLogin(e);
    }
  };


  const resetToLogin = () => {
    setOtpMode(null);
    setPassword("");
    setOtp("");
    setMessage("");
    setTempToken("");
  };

  const handleGoogleSuccess = async (credentialResponse) => {
    try {
      const idToken = credentialResponse.credential;
      const res = await API.post("/auth/google", { idToken });
      const data = res.data;

      if (!data.token || !data.userInfo) {
        toast.error(data.message || "Google login failed.");
        return;
      }

      dispatch(loginSuccess({ token: data.token, userInfo: data.userInfo }));
      dispatch(setUserData(data.userInfo));
      startProactiveRefresh();

      if (data.needs_profile_completion) {
        toast.success("Account created. Complete your profile.");
        navigate("/complete-profile", { replace: true });
        return;
      }

      // عدم إظهار لوحة قبول الشروط بعد تسجيل الدخول — التوجيه مباشرة للداشبورد
      connectSocket(data.token, data.userInfo.id);
      toast.success("Google login successful! Redirecting...");
      const path = getDashboardPath(data.userInfo.role_id);
      navigate(path, { replace: true });
    } catch (error) {
      const msg = error.response?.data?.message || "Google login failed. Please try again.";
      toast.error(msg);
    }
  };

  const handleGoogleError = () => {
    setStatus(false);
    toast.error("Google login failed. Please try again.");
  };

  return (
    <>
      <PageMeta title="Log in – OrderzHouse" description="Log in to your OrderzHouse account to manage projects and connect with freelancers." />
      <AuthSplitLayout
        cardClassName={containerClass}
        title="Welcome back"
        subtitle="Sign in to continue to ORDERZHOUSE"
        footer={
          !isOtpStep ? (
            <p className="text-center text-sm text-neutral-600">
              Don&apos;t have an account?{" "}
              <button
                type="button"
                onClick={() => go("/register")}
                className="font-medium text-[#C2410C] hover:underline inline-flex items-center focus:outline-none focus-visible:ring-2 focus-visible:ring-[#C2410C] focus-visible:ring-offset-2 rounded"
              >
                Sign up now <ArrowRight className="ml-1 h-4 w-4" />
              </button>
            </p>
          ) : null
        }
      >
        <div className="mb-6 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-neutral-200 text-slate-600 bg-neutral-50">
            {isOtpStep ? <Shield className="w-4 h-4" /> : <LogIn className="w-4 h-4" />}
            <span className="text-sm">{isOtpStep ? "Verify Your Identity" : "Sign in"}</span>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {!isOtpStep && (
            <>
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-slate-700 mb-1">Email Address</label>
                <div className="relative">
                  <Mail className="w-5 h-5 text-neutral-400 absolute left-4 top-1/2 -translate-y-1/2" aria-hidden />
                  <input
                    type="email"
                    id="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    disabled={isLoading}
                    className={`${inputPill} pl-11`}
                  />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1">
                  <label htmlFor="password" className="block text-sm font-medium text-slate-700">Password</label>
                  <Link to="/forgot-password" className="text-sm text-[#C2410C] hover:underline font-medium">
                    Forgot password?
                  </Link>
                </div>
                <div className="relative">
                  <Lock className="w-5 h-5 text-neutral-400 absolute left-4 top-1/2 -translate-y-1/2" aria-hidden />
                  <input
                    type={showPassword ? "text" : "password"}
                    id="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    disabled={isLoading}
                    className={`${inputPill} pl-11 pr-12`}
                  />
                  <button
                    type="button"
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-[#C2410C] focus:outline-none"
                    onClick={() => setShowPassword(!showPassword)}
                    disabled={isLoading}
                    aria-label={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>
            </>
          )}

          {isOtpStep && (
            <div className="animate-fadeIn space-y-5">
              <div>
                <label htmlFor="otp" className="block text-sm font-medium text-slate-700 mb-1">
                  {otpMode === "app" ? "Authenticator Code" : "Verification Code"}
                </label>
                <div className="relative">
                  <Shield className="w-5 h-5 text-neutral-400 absolute left-4 top-1/2 -translate-y-1/2" aria-hidden />
                  <input
                    type="text"
                    id="otp"
                    placeholder="6-digit code"
                    value={otp}
                    onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    maxLength={6}
                    required
                    autoFocus
                    disabled={isLoading}
                    className={`${inputPill} pl-11 text-center tracking-widest`}
                  />
                </div>
                <p className="text-xs text-neutral-500 mt-2 text-center">
                  {otpMode === "app"
                    ? "Open your authenticator app and enter the 6-digit code."
                    : "Enter the 6-digit code sent to your email."}
                </p>
              </div>
            </div>
          )}

          <div className="flex justify-center pt-1">
            <button
              type="submit"
              disabled={isLoading}
              className="w-full h-12 rounded-xl bg-[#C2410C] hover:bg-[#9A3412] text-white font-medium flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors focus:outline-none focus:ring-2 focus:ring-[#C2410C]/30 focus:ring-offset-2"
            >
              {isLoading ? (
                <>
                  <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden>
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  {isOtpStep ? "Verifying..." : "Signing in..."}
                </>
              ) : (
                <>
                  {isOtpStep ? <KeyRound className="w-5 h-5" /> : <LogIn className="w-5 h-5" />}
                  {isOtpStep ? "Verify & Sign In" : "Sign in"}
                </>
              )}
            </button>
          </div>

          {false && !isOtpStep && ENABLE_GOOGLE_LOGIN && (
            <>
              <div className="relative my-2">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-neutral-200" />
                </div>
                <div className="relative flex justify-center">
                  <span className="px-2 bg-white text-neutral-500 text-sm">Or continue with</span>
                </div>
              </div>
              <div className="flex justify-center">
                <GoogleLogin
                  onSuccess={handleGoogleSuccess}
                  onError={handleGoogleError}
                  theme="filled_blue"
                  size="large"
                  shape="pill"
                  text="signin_with"
                />
              </div>
            </>
          )}

          {isOtpStep && (
            <div className="text-center">
              <button
                type="button"
                onClick={resetToLogin}
                disabled={isLoading}
                className="text-[#C2410C] hover:underline font-medium text-sm"
              >
                ← Back to login
              </button>
            </div>
          )}
        </form>
      </AuthSplitLayout>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .animate-fadeIn { animation: fadeIn 0.25s ease-out; }
      `}</style>
    </>
  );
};

export default Login;
