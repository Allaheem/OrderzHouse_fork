import React, { useState, useEffect } from "react";
import { useDispatch } from "react-redux";
import API, { startProactiveRefresh } from "../../api/client.js";
import { useNavigate, useSearchParams } from "react-router-dom";
import { getStoredAttribution, getAttributionFromUrl, storeAttribution } from "../../utils/partnerReferral.js";
import arabCountries from "../../data/arabCountries.json";
import { Mail, Lock, Eye, EyeOff, Phone, MapPin, KeyRound } from "lucide-react";
import PageMeta from "../PageMeta.jsx";
import { useToast } from "../toast/ToastProvider";
import { useAuthTransition } from "../auth/useAuthTransition.js";
import AuthSplitLayout from "../auth/AuthSplitLayout.jsx";
import { applyLoginSuccess } from "../login/Login.jsx";
import { connectSocket } from "../../services/socketService";

const roles = [
  { id: 2, label: "Customer" },
  { id: 3, label: "Freelancer" },
  { id: 5, label: "Partner" },
];

const Register = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const toast = useToast();
  const [searchParams] = useSearchParams();
  const { containerClass, go } = useAuthTransition();

  const [step, setStep] = useState(1);
  const [stepErrors, setStepErrors] = useState({});
  const [confirmPassword, setConfirmPassword] = useState("");

  const [role_id, setRole_id] = useState("");
  const [first_name, setFirst_name] = useState("");
  const [last_name, setLast_name] = useState("");
  const [phone_number, setPhone_number] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [country, setCountry] = useState("");
  const [countries, setCountries] = useState([]);
  const [username, setUsername] = useState("");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);
  const [categories, setCategories] = useState([]);
  const [selectedCategories, setSelectedCategories] = useState([]);
  const [passwordStrength, setPasswordStrength] = useState({
    hasMinLength: false,
    hasUpperCase: false,
    hasLowerCase: false,
    hasNumber: false,
  });
  const [profile_pic_url, setProfile_pic_url] = useState("");
  const [uploading, setUploading] = useState(false);
  const [acceptTerms, setAcceptTerms] = useState(false);

  // ===== States for sub-categories =====
  const [expandedCategories, setExpandedCategories] = useState({});
  const [subCategories, setSubCategories] = useState({});
  const [selectedSubCategories, setSelectedSubCategories] = useState([]);

  // ===== OTP states =====
  const [showOtpField, setShowOtpField] = useState(false);
  const [otp, setOtp] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);

  const RESEND_COOLDOWN_SEC = 30;
  const RESEND_COOLDOWN_END_KEY = "otp_resend_cooldown_end";
  const startResendCooldown = () => {
    const end = Date.now() + RESEND_COOLDOWN_SEC * 1000;
    sessionStorage.setItem(RESEND_COOLDOWN_END_KEY, String(end));
    setResendCooldown(RESEND_COOLDOWN_SEC);
  };

  //========= countries api =========//

  useEffect(() => {
    setCountries(arabCountries.sort((a, b) => a.localeCompare(b)));
  }, []);

  // Note: Removed old email verification URL param handling (legacy flow)

  // Restore resend cooldown after refresh (persist 30s across page reload)
  useEffect(() => {
    if (!showOtpField) return;
    const endStr = sessionStorage.getItem(RESEND_COOLDOWN_END_KEY);
    if (!endStr) return;
    const end = Number(endStr);
    const remaining = Math.ceil((end - Date.now()) / 1000);
    if (remaining > 0) setResendCooldown(remaining);
    else sessionStorage.removeItem(RESEND_COOLDOWN_END_KEY);
  }, [showOtpField]);

  useEffect(() => {
  API
    .get("/category")
    .then((res) => {
      if (res.data.success) {
        setCategories(res.data.data);
      }
    })
    .catch((_) => {
    });
}, []);


  // ========= password strength checker =========//
  useEffect(() => {
    setPasswordStrength({
      hasMinLength: password.length >= 8,
      hasUpperCase: /[A-Z]/.test(password),
      hasLowerCase: /[a-z]/.test(password),
      hasNumber: /\d/.test(password),
    });
  }, [password]);

  // Partner referral: store attribution from URL (visit is logged only from App.jsx — do not call /referrals/visit here)
  useEffect(() => {
    const search = searchParams.toString() ? `?${searchParams.toString()}` : window.location?.search || "";
    const attribution = getAttributionFromUrl(search);
    if (attribution.source || attribution.ref) storeAttribution(attribution);
  }, [searchParams]);

  // ========= freelancer categories =========//
  useEffect(() => {
    // This useEffect can be simplified since we're using the new component
    // The new component handles its own category fetching
  }, []);

  const handleCategoryToggle = (categoryId) => {
    setSelectedCategories((prev) =>
      prev.includes(categoryId)
        ? prev.filter((id) => id !== categoryId)
        : [...prev, categoryId]
    );
  };

  const removeCategory = (categoryId) => {
    setSelectedCategories((prev) => prev.filter((id) => id !== categoryId));
  };

  // ========= Fetch sub-categories when category is expanded =========//
  const toggleCategoryExpand = async (categoryId) => {
    const isExpanded = expandedCategories[categoryId];
    setExpandedCategories((prev) => ({
      ...prev,
      [categoryId]: !isExpanded,
    }));

    // Fetch sub-categories if not already fetched
    if (!isExpanded && !subCategories[categoryId]) {
      try {
        const res = await API.get(
          `/category/${categoryId}/sub-categories`
        );
        setSubCategories((prev) => ({
          ...prev,
          [categoryId]: res.data.subCategories || [],
        }));
      } catch (_) {
      }
    }
  };

  // ========= Handle sub-category selection =========//
  const handleSubCategoryToggle = (subCategoryId) => {
    setSelectedSubCategories((prev) =>
      prev.includes(subCategoryId)
        ? prev.filter((id) => id !== subCategoryId)
        : [...prev, subCategoryId]
    );
  };

  const removeSubCategory = (subCategoryId) => {
    setSelectedSubCategories((prev) =>
      prev.filter((id) => id !== subCategoryId)
    );
  };

  // Helper function to get sub-category name by ID
  const getSubCategoryName = (subCategoryId) => {
    for (const catId in subCategories) {
      const subCat = subCategories[catId]?.find((sc) => sc.id === subCategoryId);
      if (subCat) return subCat.name;
    }
    return "";
  };

  /* ===================== Upload Profile Image to Cloudinary ===================== */
  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setUploading(true);
    try {
      const formDataCloud = new FormData();
      formDataCloud.append("file", file);
      formDataCloud.append("upload_preset", import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET);
      formDataCloud.append("cloud_name", import.meta.env.VITE_CLOUDINARY_CLOUD_NAME);
      formDataCloud.append("folder", "users/profile_pics");

      const res = await fetch(
        `https://api.cloudinary.com/v1_1/${import.meta.env.VITE_CLOUDINARY_CLOUD_NAME}/auto/upload`,
        { method: "POST", body: formDataCloud }
      );

      const data = await res.json();
      if (data.secure_url) {
        setProfile_pic_url(data.secure_url);
        setMessage("Profile picture uploaded!");
        setStatus(true);
      } else {
        setMessage("Cloudinary upload failed");
        setStatus(false);
      }
    } catch (_) {
      setMessage("Error uploading image");
      setStatus(false);
    } finally {
      setUploading(false);
    }
  };

  // =============== STEP VALIDATION =============== //
  const validateStep1 = () => {
    const err = {};
    const u = (username || "").trim();
    if (!u) err.username = "Username is required.";
    const em = (email || "").trim();
    if (!em) err.email = "Email is required.";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em)) err.email = "Please enter a valid email.";
    if (!password) err.password = "Password is required.";
    else if (password.length < 8) err.password = "Password must be at least 8 characters.";
    if (password !== confirmPassword) err.confirmPassword = "Passwords do not match.";
    setStepErrors(err);
    return Object.keys(err).length === 0;
  };

  const validateStep2 = () => {
    const err = {};
    if (!role_id) err.role_id = "Please select a role.";
    if (!(first_name || "").trim()) err.first_name = "First name is required.";
    if (!(last_name || "").trim()) err.last_name = "Last name is required.";
    if (!country) err.country = "Country is required.";
    if (!(phone_number || "").trim()) err.phone_number = "Phone number is required.";
    if (role_id === "3" && selectedCategories.length === 0) err.categories = "Please select at least one category.";
    if (!acceptTerms) err.acceptTerms = "You must accept the Terms and Privacy Policy.";
    setStepErrors(err);
    return Object.keys(err).length === 0;
  };

  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (step === 1) {
      if (validateStep1()) {
        setStepErrors({});
        setStep(2);
      }
      return;
    }
    if (step === 2 && validateStep2()) register(e);
  };

  // =============== REQUEST SIGNUP OTP (Step 1) =============== //
  const register = async (e) => {
    e?.preventDefault();
    if (!acceptTerms) {
      toast.error("Please accept the Terms and Privacy Policy.");
      return;
    }
    if (role_id === "3" && selectedCategories.length === 0) {
      toast.error("Please select at least one category.");
      return;
    }
    setIsLoading(true);

    try {
      // Step 1: Request OTP
      const result = await API.post("/users/request-signup-otp", { 
        email: email.toLowerCase().trim() 
      });
      
      toast.success(
        result.data.message || "Verification code sent. Check your email (and spam folder)."
      );
      setShowOtpField(true);
      startResendCooldown();
    } catch (error) {
      const errorMessage =
        error.response?.data?.message ||
        error.response?.data?.error ||
        "Failed to send verification code";
      toast.error(errorMessage);
      if (error.response?.status === 409) {
        setTimeout(() => go("/login"), 1500);
      }
    } finally {
      setIsLoading(false);
    }
  };

  // =============== VERIFY OTP AND REGISTER (Step 2) =============== //
  const handleVerifyOtp = async () => {
    const otpStr = String(otp ?? "").trim();
    if (!otpStr || otpStr.length !== 6) {
      toast.error("Please enter the 6-digit code sent to your email.");
      return;
    }

    // Validate form again (in case user navigated back)
    if (!acceptTerms) {
      toast.error("Please accept the Terms and Privacy Policy.");
      return;
    }
    if (role_id === "3" && selectedCategories.length === 0) {
      toast.error("Please select at least one category.");
      return;
    }

    // Backend requires all of these; validate before sending to avoid generic 400
    const required = [
      { value: first_name?.trim(), name: "First name" },
      { value: last_name?.trim(), name: "Last name" },
      { value: password, name: "Password" },
      { value: phone_number?.trim(), name: "Phone number" },
      { value: country?.trim(), name: "Country" },
      { value: username?.trim(), name: "Username" },
    ];
    const missing = required.find((r) => !r.value);
    if (missing) {
      toast.error(`${missing.name} is required.`);
      return;
    }

    setIsVerifying(true);

    try {
      const userData = {
        email: email.toLowerCase().trim(),
        otp: otpStr,
        role_id: parseInt(role_id, 10),
        first_name: first_name.trim(),
        last_name: last_name.trim(),
        password,
        phone_number: phone_number.trim(),
        country: country.trim(),
        username: username.trim(),
        profile_pic_url: profile_pic_url || undefined,
      };
      if (role_id === "3") userData.category_ids = selectedCategories;

      const attribution = getStoredAttribution();
      if (attribution) Object.assign(userData, attribution);

      const result = await API.post("/users/verify-and-register", userData);

      toast.success(result.data.message || "Account created successfully! Redirecting...");
      await applyLoginSuccess(dispatch, result.data, navigate, connectSocket);
    } catch (err) {
      const apiMessage = err.response?.data?.message;
      const errorMessage = apiMessage
        ? apiMessage
        : err.response
          ? "Invalid or expired OTP. Please try again or request a new code."
          : "Account was created but something went wrong. Try logging in.";
      toast.error(errorMessage);
      if (!err.response && apiMessage !== "Invalid OTP") {
        setTimeout(() => go("/login"), 2000);
      }
      setOtp("");
    } finally {
      setIsVerifying(false);
    }
  };

  // =============== RESEND OTP =============== //
  const handleResendOtp = async () => {
    if (resendCooldown > 0) return;
    if (!email || !email.trim()) {
      toast.error("Email is required.");
      return;
    }

    try {
      const res = await API.post("/users/request-signup-otp", {
        email: email.toLowerCase().trim(),
      });
      toast.success(res.data?.message || "Verification code sent. Check your email.");
      startResendCooldown();
    } catch (err) {
      const msg = err.response?.data?.message || "Failed to resend verification code. Please try again.";
      toast.error(msg);
      if (err.response?.status === 409) {
        setTimeout(() => go("/login"), 1500);
      }
    }
  };

  // =============== RESEND COOLDOWN TIMER =============== //
  useEffect(() => {
    if (resendCooldown > 0) {
      const timer = setTimeout(() => {
        setResendCooldown((prev) => {
          const next = Math.max(0, prev - 1);
          if (next === 0) sessionStorage.removeItem(RESEND_COOLDOWN_END_KEY);
          return next;
        });
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [resendCooldown]);

  const getPasswordStrengthText = () => {
    const validCount = Object.values(passwordStrength).filter(Boolean).length;
    if (validCount === 0) return { text: "", color: "" };
    if (validCount === 1) return { text: "Very Weak", color: "text-rose-600" };
    if (validCount === 2) return { text: "Weak", color: "text-rose-500" };
    if (validCount === 3) return { text: "Good", color: "text-amber-500" };
    if (validCount === 4) return { text: "Strong", color: "text-emerald-600" };
    return { text: "", color: "" };
  };

  const passwordStrengthInfo = getPasswordStrengthText();

  const inputPill = "h-12 rounded-xl bg-neutral-100 border border-transparent px-4 w-full focus:outline-none focus:ring-2 focus:ring-[#C2410C]/30 focus:border-[#C2410C]/40 placeholder:text-neutral-400 transition-colors";

  return (
    <>
      <PageMeta title="Sign up – OrderzHouse" description="Create your OrderzHouse account as a client, freelancer, or partner." />
      <AuthSplitLayout
        cardClassName={containerClass}
        footer={
          <p className="text-center text-sm text-neutral-600">
            Already have an account?{" "}
            <button
              type="button"
              onClick={() => go("/login")}
              className="font-medium text-[#C2410C] hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[#C2410C] focus-visible:ring-offset-2 rounded"
            >
              Log in
            </button>
          </p>
        }
      >
        {showOtpField ? (
              /* —— OTP View (same panel, same spacing) —— */
              <div className="space-y-6">
                <h2 className="text-2xl font-bold text-slate-900">Verify your email</h2>
                <p className="text-neutral-500 text-sm">
                  We sent a 6-digit code to <span className="font-medium text-[#C2410C]">{email}</span>. Enter it below to complete your registration.
                </p>
                <div className="relative">
                  <KeyRound className="w-5 h-5 text-neutral-400 absolute left-4 top-1/2 -translate-y-1/2" aria-hidden />
                  <input
                    type="text"
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    value={otp}
                    onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    maxLength={6}
                    placeholder="Enter OTP"
                    className={`${inputPill} pl-11 text-center tracking-widest text-lg`}
                    aria-label="Verification code"
                  />
                </div>
                <button
                  type="button"
                  onClick={handleVerifyOtp}
                  disabled={isVerifying}
                  className="w-full h-12 rounded-xl bg-[#C2410C] hover:bg-[#9A3412] text-white font-medium flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors focus:outline-none focus:ring-2 focus:ring-[#C2410C]/30 focus:ring-offset-2"
                >
                  {isVerifying ? "Verifying..." : "Verify OTP"}
                </button>
                <div className="text-center">
                  <button
                    type="button"
                    onClick={handleResendOtp}
                    disabled={resendCooldown > 0 || isVerifying}
                    className={`text-sm ${resendCooldown > 0 ? "text-neutral-400 cursor-not-allowed" : "text-[#C2410C] hover:underline"}`}
                  >
                    {resendCooldown > 0 ? `Resend code in ${resendCooldown}s` : "Resend code"}
                  </button>
                </div>
                <p className="text-center text-sm text-neutral-500">
                  Wrong email? <button type="button" onClick={() => setShowOtpField(false)} className="text-[#C2410C] hover:underline">Change email</button>
                </p>
              </div>
            ) : (
              /* —— Registration Form (2-Step Wizard) —— */
              <form onSubmit={handleFormSubmit} className="space-y-5">
                <h2 className="text-2xl font-bold text-slate-900">Create an account</h2>

                {/* —— Step 1: Account —— */}
                {step === 1 && (
                  <div className="space-y-5 transition-opacity duration-200">
                    <div>
                      <label htmlFor="username" className="block text-sm font-medium text-slate-700 mb-1">Username</label>
                      <input id="username" type="text" value={username} onChange={(e) => setUsername(e.target.value)} placeholder="Username" className={`${inputPill} ${stepErrors.username ? "border-red-400 focus:ring-red-300" : ""}`} aria-invalid={!!stepErrors.username} aria-describedby={stepErrors.username ? "err-username" : undefined} />
                      {stepErrors.username && <p id="err-username" className="text-xs text-red-600 mt-1">{stepErrors.username}</p>}
                    </div>

                    <div>
                      <label htmlFor="email" className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                      <input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" className={`${inputPill} ${stepErrors.email ? "border-red-400 focus:ring-red-300" : ""}`} aria-invalid={!!stepErrors.email} aria-describedby={stepErrors.email ? "err-email" : undefined} />
                      {stepErrors.email && <p id="err-email" className="text-xs text-red-600 mt-1">{stepErrors.email}</p>}
                    </div>

                    <div>
                      <label htmlFor="password" className="block text-sm font-medium text-slate-700 mb-1">Password</label>
                      <div className="relative">
                        <input
                          id="password"
                          type={showPassword ? "text" : "password"}
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          placeholder="••••••••"
                          className={`${inputPill} pr-12 ${stepErrors.password ? "border-red-400 focus:ring-red-300" : ""}`}
                          aria-invalid={!!stepErrors.password}
                          aria-describedby={stepErrors.password ? "err-password" : "pwd-strength"}
                        />
                        <button type="button" onClick={() => setShowPassword((p) => !p)} className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-[#C2410C] focus:outline-none" aria-label={showPassword ? "Hide password" : "Show password"}>
                          {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                        </button>
                      </div>
                      <div id="pwd-strength" className="mt-1.5 flex items-center justify-between">
                        <span className="text-xs text-neutral-500">Strength</span>
                        <span className={`text-xs font-medium ${passwordStrengthInfo.color}`}>{passwordStrengthInfo.text}</span>
                      </div>
                      {stepErrors.password && <p id="err-password" className="text-xs text-red-600 mt-1">{stepErrors.password}</p>}
                    </div>

                    <div>
                      <label htmlFor="confirmPassword" className="block text-sm font-medium text-slate-700 mb-1">Confirm Password</label>
                      <div className="relative">
                        <input
                          id="confirmPassword"
                          type={showConfirmPassword ? "text" : "password"}
                          value={confirmPassword}
                          onChange={(e) => setConfirmPassword(e.target.value)}
                          placeholder="••••••••"
                          className={`${inputPill} pr-12 ${stepErrors.confirmPassword ? "border-red-400 focus:ring-red-300" : ""}`}
                          aria-invalid={!!stepErrors.confirmPassword}
                          aria-describedby={stepErrors.confirmPassword ? "err-confirmPassword" : undefined}
                        />
                        <button type="button" onClick={() => setShowConfirmPassword((p) => !p)} className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-[#C2410C] focus:outline-none" aria-label={showConfirmPassword ? "Hide password" : "Show password"}>
                          {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                        </button>
                      </div>
                      {stepErrors.confirmPassword && <p id="err-confirmPassword" className="text-xs text-red-600 mt-1">{stepErrors.confirmPassword}</p>}
                    </div>

                    <button
                      type="submit"
                      disabled={!username?.trim() || !email?.trim() || !password || password.length < 8 || password !== confirmPassword}
                      className="w-full h-12 rounded-xl bg-[#C2410C] hover:bg-[#9A3412] text-white font-medium flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors focus:outline-none focus:ring-2 focus:ring-[#C2410C]/30 focus:ring-offset-2"
                    >
                      Next
                    </button>
                  </div>
                )}

                {/* —— Step 2: Details —— */}
                {step === 2 && (
                  <div className="space-y-5 transition-opacity duration-200">
                    {/* Segmented control: role */}
                    <div>
                      <span className="block text-sm font-medium text-slate-700 mb-2">Account type</span>
                      <div role="tablist" aria-label="Account type" className="flex p-1 rounded-xl bg-neutral-100">
                        {roles.map((role) => (
                          <button
                            key={role.id}
                            type="button"
                            role="tab"
                            aria-pressed={role_id === String(role.id)}
                            onClick={() => setRole_id(String(role.id))}
                            className={`flex-1 py-2.5 px-3 rounded-lg text-sm font-medium transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#C2410C] focus-visible:ring-offset-2 ${
                              role_id === String(role.id)
                                ? "bg-neutral-900 text-white"
                                : "text-neutral-600 hover:text-neutral-900"
                            }`}
                          >
                            {role.label}
                          </button>
                        ))}
                      </div>
                      {stepErrors.role_id && <p className="text-xs text-red-600 mt-1">{stepErrors.role_id}</p>}
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="first_name" className="block text-sm font-medium text-slate-700 mb-1">First name</label>
                        <input id="first_name" type="text" value={first_name} onChange={(e) => setFirst_name(e.target.value)} placeholder="First name" className={`${inputPill} ${stepErrors.first_name ? "border-red-400 focus:ring-red-300" : ""}`} aria-invalid={!!stepErrors.first_name} />
                        {stepErrors.first_name && <p className="text-xs text-red-600 mt-1">{stepErrors.first_name}</p>}
                      </div>
                      <div>
                        <label htmlFor="last_name" className="block text-sm font-medium text-slate-700 mb-1">Last name</label>
                        <input id="last_name" type="text" value={last_name} onChange={(e) => setLast_name(e.target.value)} placeholder="Last name" className={`${inputPill} ${stepErrors.last_name ? "border-red-400 focus:ring-red-300" : ""}`} aria-invalid={!!stepErrors.last_name} />
                        {stepErrors.last_name && <p className="text-xs text-red-600 mt-1">{stepErrors.last_name}</p>}
                      </div>
                    </div>

                    <div>
                      <label htmlFor="country" className="block text-sm font-medium text-slate-700 mb-1">Country</label>
                      <select id="country" value={country} onChange={(e) => setCountry(e.target.value)} className={`${inputPill} ${stepErrors.country ? "border-red-400 focus:ring-red-300" : ""}`} aria-invalid={!!stepErrors.country}>
                        <option value="">Select country</option>
                        {countries.map((c) => <option key={c} value={c}>{c}</option>)}
                      </select>
                      {stepErrors.country && <p className="text-xs text-red-600 mt-1">{stepErrors.country}</p>}
                    </div>

                    <div>
                      <label htmlFor="phone" className="block text-sm font-medium text-slate-700 mb-1">Phone number</label>
                      <input id="phone" type="tel" value={phone_number} onChange={(e) => setPhone_number(e.target.value)} placeholder="+1234567890" className={`${inputPill} ${stepErrors.phone_number ? "border-red-400 focus:ring-red-300" : ""}`} aria-invalid={!!stepErrors.phone_number} />
                      {stepErrors.phone_number && <p className="text-xs text-red-600 mt-1">{stepErrors.phone_number}</p>}
                    </div>

                    {/* Freelancer categories (chips) */}
                    {role_id === "3" && (
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">Categories (at least one)</label>
                        <div className="flex flex-wrap gap-2">
                          {categories.map((cat) => (
                            <button
                              key={cat.id}
                              type="button"
                              onClick={() => handleCategoryToggle(cat.id)}
                              className={`rounded-full border px-3 py-1.5 text-sm transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#C2410C] ${
                                selectedCategories.includes(cat.id)
                                  ? "bg-[#C2410C] text-white border-[#C2410C]"
                                  : "bg-neutral-100 text-slate-700 border-neutral-200 hover:border-[#C2410C]/50"
                              }`}
                            >
                              {cat.name}
                            </button>
                          ))}
                        </div>
                        <p className="text-xs text-neutral-500 mt-1">{selectedCategories.length} selected</p>
                        {stepErrors.categories && <p className="text-xs text-red-600 mt-1">{stepErrors.categories}</p>}
                      </div>
                    )}

                    <div className="flex items-start gap-3">
                      <input
                        id="acceptTerms"
                        type="checkbox"
                        checked={acceptTerms}
                        onChange={(e) => setAcceptTerms(e.target.checked)}
                        className={`h-4 w-4 rounded border-neutral-300 text-[#C2410C] focus:ring-[#C2410C] mt-0.5 ${stepErrors.acceptTerms ? "border-red-400" : ""}`}
                        aria-invalid={!!stepErrors.acceptTerms}
                        aria-describedby="terms-desc"
                      />
                      <label id="terms-desc" htmlFor="acceptTerms" className="text-sm text-slate-700">
                        I agree to the <a href="/terms" target="_blank" rel="noopener noreferrer" className="text-[#C2410C] hover:underline">Terms and Conditions</a> and <a href="/privacy" target="_blank" rel="noopener noreferrer" className="text-[#C2410C] hover:underline">Privacy Policy</a>.
                      </label>
                    </div>
                    {stepErrors.acceptTerms && <p className="text-xs text-red-600 -mt-2">{stepErrors.acceptTerms}</p>}

                    <div className="flex gap-3">
                      <button
                        type="button"
                        onClick={() => { setStep(1); setStepErrors({}); }}
                        className="flex-1 h-12 rounded-xl border-2 border-neutral-300 text-slate-700 font-medium hover:bg-neutral-100 focus:outline-none focus:ring-2 focus:ring-[#C2410C]/30 focus:ring-offset-2 transition-colors"
                      >
                        Back
                      </button>
                      <button
                        type="submit"
                        disabled={isLoading}
                        className="flex-1 h-12 rounded-xl bg-[#C2410C] hover:bg-[#9A3412] text-white font-medium flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors focus:outline-none focus:ring-2 focus:ring-[#C2410C]/30 focus:ring-offset-2"
                      >
                        {isLoading ? (
                          <>
                            <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden>
                              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                            </svg>
                            Creating account...
                          </>
                        ) : (
                          "Create account"
                        )}
                      </button>
                    </div>
                  </div>
                )}
              </form>
        )}
      </AuthSplitLayout>
    </>
  );
};

export default Register;
