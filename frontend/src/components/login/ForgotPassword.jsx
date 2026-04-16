// src/components/login/ForgotPassword.jsx
import React, { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import API from "../../api/client.js";
import {
  Mail,
  Shield,
  AlertCircle,
  CheckCircle,
  ArrowLeft,
  KeyRound,
  Lock,
  Eye,
  EyeOff,
} from "lucide-react";
import GradientButton from "../buttons/GradientButton.jsx";
import { safeStringMatch } from "../../utils/safeStringMatch.js";
import { maskEmail } from "../../utils/maskEmail.js";

const ForgotPassword = () => {
  const navigate = useNavigate();

  // Load email and resetRequestId from sessionStorage on mount
  const [step, setStep] = useState(() => {
    const storedEmail = sessionStorage.getItem("fp_email");
    return storedEmail ? "reset" : "request";
  });
  const [email, setEmail] = useState(() => sessionStorage.getItem("fp_email") || "");
  const [resetRequestId, setResetRequestId] = useState(() => sessionStorage.getItem("fp_reset_request_id") || "");

  // If on reset step but email is missing (e.g., after refresh), redirect to request step
  useEffect(() => {
    if (step === "reset" && !email) {
      clearResetData();
      setStep("request");
    }
  }, [step, email]);
  const [otp, setOtp] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Clear stored reset data
  const clearResetData = () => {
    sessionStorage.removeItem("fp_email");
    sessionStorage.removeItem("fp_reset_request_id");
    setEmail("");
    setResetRequestId("");
    setStep("request");
    setOtp("");
    setNewPassword("");
    setConfirmPassword("");
    setMessage("");
  };

  const handleRequestReset = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage("");

    // Client-side validation: trim and validate email format
    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setStatus(false);
      setMessage("Please enter your email address.");
      setIsLoading(false);
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      setStatus(false);
      setMessage("Please enter a valid email address.");
      setIsLoading(false);
      return;
    }

    try {
      const response = await API.post("/users/forgot-password", {
        email: trimmedEmail.toLowerCase(),
      });

      if (response.data?.success) {
        // Store email and resetRequestId in sessionStorage
        const emailToStore = trimmedEmail.toLowerCase();
        const requestId = response.data.resetRequestId || "";
        sessionStorage.setItem("fp_email", emailToStore);
        if (requestId) {
          sessionStorage.setItem("fp_reset_request_id", requestId);
          setResetRequestId(requestId);
        }
        setEmail(emailToStore);
        
        setStatus(true);
        setMessage(
          response.data.message || "Password reset code has been sent to your email."
        );
        // Move to reset step after a short delay
        setTimeout(() => {
          setStep("reset");
          setMessage("");
        }, 2000);
      } else {
        setStatus(true);
        setMessage("If an account exists for this email, a reset code has been sent.");
        setTimeout(() => {
          setStep("reset");
          setMessage("");
        }, 2000);
      }
    } catch (error) {
      if (error.code === "ERR_NETWORK" || error.message?.includes("Failed to fetch")) {
        setStatus(false);
        setMessage("Unable to connect to server. Please check your internet connection and try again.");
      } else {
        // Avoid account enumeration by returning a uniform success response for this step.
        setStatus(true);
        setMessage("If an account exists for this email, a reset code has been sent.");
        setTimeout(() => {
          setStep("reset");
          setMessage("");
        }, 2000);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage("");

    // Validate inputs (email not required - only for display)
    if (!otp || !newPassword || !confirmPassword) {
      setStatus(false);
      setMessage("All fields are required.");
      setIsLoading(false);
      return;
    }

    // Validate OTP format (6 digits)
    const otpRegex = /^\d{6}$/;
    if (!safeStringMatch(otp, otpRegex)) {
      setStatus(false);
      setMessage("Please enter a valid 6-digit code.");
      setIsLoading(false);
      return;
    }

    // Validate password format
    const passwordRegex = /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$/;
    if (!passwordRegex.test(newPassword)) {
      setStatus(false);
      setMessage(
        "Password must be at least 8 characters and include uppercase, lowercase, and number."
      );
      setIsLoading(false);
      return;
    }

    // Check password match
    if (newPassword !== confirmPassword) {
      setStatus(false);
      setMessage("Passwords do not match.");
      setIsLoading(false);
      return;
    }

    try {
      // SECURITY: Only send resetRequestId, code, and newPassword - backend identifies user by resetRequestId
      // Get resetRequestId from sessionStorage (required)
      const storedRequestId = sessionStorage.getItem("fp_reset_request_id");
      if (!storedRequestId) {
        setStatus(false);
        setMessage("Reset session expired. Please request a new reset code.");
        setIsLoading(false);
        clearResetData();
        return;
      }

      const response = await API.post("/users/reset-password", {
        resetRequestId: storedRequestId,
        code: otp, // Renamed from 'otp' to 'code' to match backend
        newPassword,
      });

      if (response.data?.success) {
        setStatus(true);
        setMessage(
          response.data.message || "Password reset successfully! Redirecting to login..."
        );
        // Clear sessionStorage on success
        clearResetData();
        // Redirect to login after success
        setTimeout(() => {
          navigate("/login");
        }, 2000);
      } else {
        setStatus(false);
        setMessage(response.data?.message || "Failed to reset password. Please try again.");
      }
    } catch (error) {
      setStatus(false);
      if (error.response?.data?.message) {
        setMessage(error.response.data.message);
      } else if (error.code === "ERR_NETWORK" || error.message?.includes("Failed to fetch")) {
        setMessage("Unable to connect to server. Please check your internet connection and try again.");
      } else {
        setMessage("An error occurred. Please try again later.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white relative overflow-hidden">
      <div className="flex min-h-screen items-center justify-center pt-32 p-4 lg:px-8">
        <div className="w-full max-w-lg">
          <div className="text-center mb-6">
            <h1 className="text-2xl sm:text-4xl font-semibold text-slate-900 tracking-tight">
              {step === "request" ? "Forgot Password?" : "Reset Password"}
            </h1>
            <p className="text-slate-500 mt-2 text-sm">
              {step === "request"
                ? "Enter your email address and we'll send you a reset code."
                : "Enter the code sent to your email and your new password."}
            </p>
          </div>

          <div className="rounded-3xl border border-slate-200/70 bg-white/90 backdrop-blur p-6 sm:p-8 shadow-sm">
            <div className="mb-6 text-center">
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-slate-200 text-slate-600 bg-white">
                {step === "request" ? (
                  <Mail className="w-4 h-4" />
                ) : (
                  <KeyRound className="w-4 h-4" />
                )}
                <span className="text-sm">
                  {step === "request" ? "Request Reset" : "Enter Code"}
                </span>
              </div>
            </div>

            <form
              onSubmit={step === "request" ? handleRequestReset : handleResetPassword}
              className="space-y-5"
            >
              {/* Request Step */}
              {step === "request" && (
                <div>
                  <label htmlFor="email" className="block text-sm text-slate-700 mb-1.5">
                    Email Address
                  </label>
                  <div className="relative">
                    <Mail className="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      id="email"
                      placeholder="info@battechno.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      required
                      disabled={isLoading}
                      className="w-full pl-10 pr-3 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500/50"
                    />
                  </div>
                </div>
              )}

              {/* Reset Step */}
              {step === "reset" && (
                <>
                  {/* Masked email display (read-only, for user reference only) */}
                  {email && (
                    <div className="p-3 rounded-lg bg-slate-50 border border-slate-200">
                      <p className="text-sm text-slate-700">
                        <span className="font-medium">Enter the code sent to </span>
                        <span className="font-mono text-slate-900">{maskEmail(email) || email}</span>
                      </p>
                      <button
                        type="button"
                        onClick={clearResetData}
                        className="mt-2 text-xs text-orange-600 hover:text-orange-700 hover:underline font-medium"
                      >
                        Use a different email
                      </button>
                    </div>
                  )}

                  <div>
                    <label htmlFor="otp" className="block text-sm text-slate-700 mb-1.5">
                      Reset Code
                    </label>
                    <div className="relative">
                      <Shield className="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
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
                        className="w-full pl-10 pr-3 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500/50 text-center tracking-widest"
                      />
                    </div>
                  </div>

                  <div>
                    <label htmlFor="newPassword" className="block text-sm text-slate-700 mb-1.5">
                      New Password
                    </label>
                    <div className="relative">
                      <Lock className="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                      <input
                        type={showPassword ? "text" : "password"}
                        id="newPassword"
                        placeholder="••••••••"
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        required
                        disabled={isLoading}
                        className="w-full pl-10 pr-12 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500/50"
                      />
                      <button
                        type="button"
                        className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-orange-600"
                        onClick={() => setShowPassword(!showPassword)}
                        disabled={isLoading}
                      >
                        {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                      </button>
                    </div>
                    <p className="text-xs text-slate-500 mt-1">
                      Must be at least 8 characters with uppercase, lowercase, and number
                    </p>
                  </div>

                  <div>
                    <label
                      htmlFor="confirmPassword"
                      className="block text-sm text-slate-700 mb-1.5"
                    >
                      Confirm Password
                    </label>
                    <div className="relative">
                      <Lock className="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                      <input
                        type={showConfirmPassword ? "text" : "password"}
                        id="confirmPassword"
                        placeholder="••••••••"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        required
                        disabled={isLoading}
                        className="w-full pl-10 pr-12 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500/50"
                      />
                      <button
                        type="button"
                        className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-orange-600"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        disabled={isLoading}
                      >
                        {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                      </button>
                    </div>
                  </div>
                </>
              )}

              <div className="flex items-center justify-center">
                <GradientButton
                  type="submit"
                  disabled={isLoading}
                  className="from-orange-400 via-orange-500 to-red-500"
                >
                  <div className="relative z-10 flex items-center px-12">
                    {isLoading ? (
                      <>
                        <svg
                          className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                        >
                          <circle
                            className="opacity-25"
                            cx="12"
                            cy="12"
                            r="10"
                            stroke="currentColor"
                            strokeWidth="4"
                          ></circle>
                          <path
                            className="opacity-75"
                            fill="currentColor"
                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                          ></path>
                        </svg>
                        {step === "request" ? "Sending..." : "Resetting..."}
                      </>
                    ) : (
                      <>
                        {step === "request" ? (
                          <>
                            <Mail className="w-5 h-5 mr-2" />
                            Send Reset Code
                          </>
                        ) : (
                          <>
                            <KeyRound className="w-5 h-5 mr-2" />
                            Reset Password
                          </>
                        )}
                      </>
                    )}
                  </div>
                </GradientButton>
              </div>

              <div className="text-center">
                <Link
                  to="/login"
                  className="text-orange-600 hover:underline font-medium text-sm inline-flex items-center"
                >
                  <ArrowLeft className="w-4 h-4 mr-1" />
                  Back to login
                </Link>
              </div>
            </form>

            {message && (
              <div
                className={`mt-6 p-4 rounded-xl flex items-start border ${
                  status
                    ? "bg-green-50 text-green-800 border-green-200"
                    : "bg-rose-50 text-rose-800 border-rose-200"
                }`}
              >
                {status ? (
                  <CheckCircle className="w-5 h-5 mt-0.5 mr-3 text-green-600 flex-shrink-0" />
                ) : (
                  <AlertCircle className="w-5 h-5 mt-0.5 mr-3 text-rose-600 flex-shrink-0" />
                )}
                <p className="text-sm">{message}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
