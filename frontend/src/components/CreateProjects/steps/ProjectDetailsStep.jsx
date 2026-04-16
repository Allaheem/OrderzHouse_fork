// components/CreateProjects/steps/ProjectDetailsStep.jsx
import React, { useState, useEffect, useRef } from "react";
import {
  fetchCategories,
  fetchSubSubCategoriesByCategoryId,
} from "../api/category";
import API from "../../../api/client.js";

const THEME = {
  hero: "bg-gradient-to-b from-orange-400 to-red-500",
  primaryBtn:
    "bg-gradient-to-b from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white focus-visible:ring-2 focus-visible:ring-orange-200/70",
  soft: "bg-orange-50 text-orange-700 border border-orange-200/70",
  ring: "focus:ring-2 focus:ring-orange-200/70 focus:border-orange-400",
};

/** غيّر إلى true عند تفعيل نوع المشروع "Hourly Rate" */
const ENABLE_HOURLY_PROJECT_TYPE = false;

export default function ProjectDetailsStep({
  onNext,
  projectData,
  setProjectData,
  isTask = false,
}) {
  const [categories, setCategories] = useState([]);
  const [subSubCategories, setSubSubCategories] = useState([]);
  const [skillsInput, setSkillsInput] = useState("");
  const [skillSuggestions, setSkillSuggestions] = useState([]);
  const [skillSuggestionsLoading, setSkillSuggestionsLoading] = useState(false);
  const [showSkillDropdown, setShowSkillDropdown] = useState(false);
  const skillSuggestionsDebounceRef = useRef(null);
  const skillInputWrapperRef = useRef(null);

  // ====================== Form state ======================
  const [form, setForm] = useState(() => {
    const base = {
      title: "",
      description: "",
      category_id: "",
      sub_sub_category_id: "",
      duration_type: "days",
      duration_days: 1,
      duration_hours: 1,
      project_type: "fixed",
      budget: 1,
      budget_min: 1,
      budget_max: 1,
      hourly_rate: 1,
      preferred_skills: [],
    };

    const merged = { ...base, ...(projectData || {}) };
    if (isTask) merged.project_type = "fixed"; // التاسك دائماً Fixed
    return merged;
  });

  const [errors, setErrors] = useState({});
  const [isFormValid, setIsFormValid] = useState(false);

  // ====================== Load categories ======================
  useEffect(() => {
    fetchCategories()
      .then((data) => setCategories(Array.isArray(data) ? data : []))
      .catch(() => {
        setCategories([]);
      });
  }, []);

  // ====================== Load sub‑sub categories when category changes ======================
  useEffect(() => {
    if (!form.category_id) {
      setSubSubCategories([]);
      setForm((prev) => ({ ...prev, sub_sub_category_id: "" }));
      return;
    }

    const idAsNumber = Number(form.category_id);
    if (!idAsNumber) return;

    fetchSubSubCategoriesByCategoryId(idAsNumber)
      .then((data) => setSubSubCategories(Array.isArray(data) ? data : []))
      .catch(() => {
        setSubSubCategories([]);
      });

    // إعادة ضبط الساب ساب كاتيجوري عند تغيير الكاتيجوري
    setForm((prev) => ({ ...prev, sub_sub_category_id: "" }));
  }, [form.category_id]);

  // عند إخفاء Hourly: إذا كان النوع hourly نرجعه إلى fixed
  useEffect(() => {
    if (!ENABLE_HOURLY_PROJECT_TYPE && form.project_type === "hourly") {
      setForm((prev) => ({ ...prev, project_type: "fixed" }));
    }
  }, [ENABLE_HOURLY_PROJECT_TYPE, form.project_type]);

  // ====================== Helpers ======================
  const handleChange = (e) => {
    const { name, value } = e.target;

    // حقول لا يُسمح أن تكون 0
    const noZeroFields = [
      "budget",
      "hourly_rate",
      "duration_days",
      "duration_hours",
      "budget_min",
      "budget_max",
    ];

    let newValue = value;
    if (noZeroFields.includes(name)) {
      const num = Number(value);
      newValue = Number.isNaN(num) ? "" : Math.max(num, 1);
    }

    setForm((prev) => ({ ...prev, [name]: newValue }));

    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: "" }));
    }
  };

  const handleAddSkill = (skillToAdd) => {
    const newSkill = (skillToAdd ?? skillsInput).trim();
    if (!newSkill) return;
    const isDuplicate = form.preferred_skills.some(
      (s) => s.toLowerCase() === newSkill.toLowerCase()
    );
    if (isDuplicate) {
      setSkillsInput("");
      setShowSkillDropdown(false);
      return;
    }

    setForm((prev) => ({
      ...prev,
      preferred_skills: [...prev.preferred_skills, newSkill],
    }));
    setSkillsInput("");
    setShowSkillDropdown(false);
    setSkillSuggestions([]);
  };

  // جلب اقتراحات المهارات من إجابات المستخدمين السابقين (بدون تكرار)
  useEffect(() => {
    const query = skillsInput.trim();
    if (skillSuggestionsDebounceRef.current) clearTimeout(skillSuggestionsDebounceRef.current);
    if (!query) {
      setSkillSuggestions([]);
      setShowSkillDropdown(false);
      return;
    }
    skillSuggestionsDebounceRef.current = setTimeout(() => {
      setSkillSuggestionsLoading(true);
      API.get(`/projects/skills-suggestions?q=${encodeURIComponent(query)}`)
        .then((res) => {
          const list = res?.data?.suggestions ?? [];
          setSkillSuggestions(list);
          setShowSkillDropdown(list.length > 0);
        })
        .catch(() => {
          setSkillSuggestions([]);
          setShowSkillDropdown(false);
        })
        .finally(() => setSkillSuggestionsLoading(false));
    }, 280);
    return () => {
      if (skillSuggestionsDebounceRef.current) clearTimeout(skillSuggestionsDebounceRef.current);
    };
  }, [skillsInput]);

  const handleRemoveSkill = (skill) => {
    setForm((prev) => ({
      ...prev,
      preferred_skills: prev.preferred_skills.filter((s) => s !== skill),
    }));
  };

  const calculateAmountToPay = () => {
    if (form.project_type === "fixed") return form.budget;
    if (form.project_type === "hourly") return form.hourly_rate * 3; // مثال بسيط
    return null;
  };

  function validateForm(showErrors = true) {
    const newErrors = {};
    const titleLength = form.title.trim().length;
    const descLength = form.description.trim().length;

    if (!form.title.trim()) {
      newErrors.title = "Title is required";
    } else if (titleLength < 10) {
      newErrors.title = "Title must be at least 10 characters";
    } else if (titleLength > 100) {
      newErrors.title = "Title must not exceed 100 characters";
    }

    if (!form.description.trim()) {
      newErrors.description = "Description is required";
    } else if (descLength < 100) {
      newErrors.description = "Description must be at least 100 characters";
    } else if (descLength > 2000) {
      newErrors.description = "Description must not exceed 2000 characters";
    }

    if (!form.category_id) newErrors.category_id = "Category is required";
    if (!form.sub_sub_category_id)
      newErrors.sub_sub_category_id = "Sub-category is required";

    if (form.project_type === "fixed" && Number(form.budget) <= 0) {
      newErrors.budget = "Budget must be greater than 0";
    }

    if (ENABLE_HOURLY_PROJECT_TYPE && !isTask && form.project_type === "hourly") {
      if (Number(form.hourly_rate) <= 0) {
        newErrors.hourly_rate = "Hourly rate must be greater than 0";
      }
    }

    if (!isTask && form.project_type === "bidding") {
      if (Number(form.budget_min) <= 0) {
        newErrors.budget_min = "Min budget must be greater than 0";
      }
      if (Number(form.budget_max) <= 0) {
        newErrors.budget_max = "Max budget must be greater than 0";
      }
      if (
        Number(form.budget_max) > 0 &&
        Number(form.budget_min) > 0 &&
        Number(form.budget_max) < Number(form.budget_min)
      ) {
        newErrors.budget_max = "Max budget must be greater than min budget";
      }
    }

    if (showErrors) setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  // تحديث زر "Continue" بشكل حي
  useEffect(() => {
    setIsFormValid(validateForm(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    // لو تاسك نبعث فقط الحقول اللي الباك إند مستنيها
    const finalData = isTask
      ? {
          title: form.title,
          description: form.description,
          price: form.budget, // مهم: budget → price
          category_id: form.category_id,
          duration_days: form.duration_type === "days" ? form.duration_days : 0,
          duration_hours:
            form.duration_type === "hours" ? form.duration_hours : 0,
          sub_sub_category_id: form.sub_sub_category_id,
        }
      : form;

    setProjectData(finalData);
    onNext();
  };

  const inputBase =
    "w-full px-4 py-2.5 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-orange-200/70 focus:border-orange-400 transition";

  const titleLength = form.title.trim().length;
  const descLength = form.description.trim().length;
  const titleProgress = Math.min((titleLength / 10) * 100, 100);
  const descProgress = Math.min((descLength / 100) * 100, 100);

  // ====================== JSX ======================
  return (
    <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
      {/* Header */}
      <div className="p-6 bg-gradient-to-b from-orange-400 to-red-500 border-b border-slate-100">
        <h2 className="text-2xl font-black tracking-tight text-white">
          {isTask ? "Task Details" : "Project Details"}
        </h2>
        <p className="text-white/90">
          {isTask ? "Tell us about your task" : "Tell us about your project"}
        </p>
      </div>

      <form onSubmit={handleSubmit} className="p-6 space-y-6">
        {/* ========== Title ========== */}
        <div>
          <label className="block text-sm font-semibold text-slate-700 mb-2">
            {isTask ? "Task Title" : "Project Title"}{" "}
            <span className="text-red-500">*</span>
          </label>
          <input
            name="title"
            placeholder={
              isTask
                ? "e.g., Design a landing page section"
                : "e.g., Build a responsive website"
            }
            value={form.title}
            onChange={handleChange}
            maxLength={100}
            className={`${inputBase} ${
              errors.title ? "ring-red-400 border-red-300" : ""
            }`}
          />
          <div className="mt-2 flex items-center justify-between text-xs">
            <span
              className={`font-medium ${
                titleLength < 10
                  ? "text-amber-600"
                  : titleLength > 100
                  ? "text-red-600"
                  : "text-emerald-600"
              }`}
            >
              {titleLength < 10
                ? `${10 - titleLength} more characters needed`
                : `${titleLength}/100 characters`}
            </span>
            <div className="flex items-center gap-2">
              <div className="w-20 h-1.5 bg-slate-200 rounded-full overflow-hidden">
                <div
                  className={`h-full transition-all ${
                    titleLength >= 10 ? "bg-emerald-500" : "bg-amber-500"
                  }`}
                  style={{ width: `${titleProgress}%` }}
                />
              </div>
            </div>
          </div>
          {errors.title && (
            <p className="mt-1 text-sm text-red-500">{errors.title}</p>
          )}
        </div>

        {/* ========== Description ========== */}
        <div>
          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Description <span className="text-red-500">*</span>
          </label>
          <textarea
            name="description"
            rows={6}
            placeholder={
              isTask
                ? "Describe your task in detail..."
                : "Describe your project in detail..."
            }
            value={form.description}
            onChange={handleChange}
            maxLength={2000}
            className={`${inputBase} resize-y ${
              errors.description ? "ring-red-400 border-red-300" : ""
            }`}
          />
          <div className="mt-2 flex items-center justify-between text-xs">
            <span
              className={`font-medium ${
                descLength < 100
                  ? "text-amber-600"
                  : descLength > 2000
                  ? "text-red-600"
                  : "text-emerald-600"
              }`}
            >
              {descLength < 100
                ? `${100 - descLength} more characters needed`
                : `${descLength}/2000 characters`}
            </span>
            <div className="flex items-center gap-2">
              <div className="w-20 h-1.5 bg-slate-200 rounded-full overflow-hidden">
                <div
                  className={`h-full transition-all ${
                    descLength >= 100 ? "bg-emerald-500" : "bg-amber-500"
                  }`}
                  style={{ width: `${descProgress}%` }}
                />
              </div>
            </div>
          </div>
          {errors.description && (
            <p className="mt-1 text-sm text-red-500">
              {errors.description}
            </p>
          )}
        </div>

        {/* ========== Preferred Skills ========== */}
        <div>
          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Preferred Skills
          </label>
          <div className="flex gap-3 mb-3 relative" ref={skillInputWrapperRef}>
            <div className="flex-1 relative">
              <input
                type="text"
                value={skillsInput}
                onChange={(e) => setSkillsInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    if (showSkillDropdown && skillSuggestions.length > 0) {
                      handleAddSkill(skillSuggestions[0].skill);
                    } else {
                      handleAddSkill();
                    }
                  }
                }}
                onFocus={() => skillSuggestions.length > 0 && setShowSkillDropdown(true)}
                onBlur={() =>
                  setTimeout(() => setShowSkillDropdown(false), 180)
                }
                placeholder="Type a skill and press Enter or Add"
                className={inputBase}
              />
              {showSkillDropdown && (skillSuggestions.length > 0 || skillSuggestionsLoading) && (
                <div className="absolute left-0 right-0 top-full z-20 mt-1 rounded-xl border border-slate-200 bg-white shadow-lg overflow-hidden">
                  {skillSuggestionsLoading ? (
                    <div className="px-4 py-3 text-sm text-slate-500">
                      Loading…
                    </div>
                  ) : (
                    <ul className="max-h-52 overflow-y-auto py-1">
                      {skillSuggestions.map((item, i) => (
                        <li key={`${item.skill}-${i}`}>
                          <button
                            type="button"
                            onClick={() => handleAddSkill(item.skill)}
                            className="w-full text-left px-4 py-2.5 text-sm text-slate-800 hover:bg-orange-50 flex items-center justify-between gap-2"
                          >
                            <span>{item.skill}</span>
                            <span className="text-xs text-slate-500 shrink-0">
                              {item.percentage}%
                            </span>
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              )}
            </div>
            <button
              type="button"
              onClick={() => handleAddSkill()}
              className={`px-5 rounded-xl font-semibold transition ${THEME.primaryBtn}`}
            >
              Add
            </button>
          </div>
          {form.preferred_skills.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {form.preferred_skills.map((skill, i) => (
                <span
                  key={i}
                  className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm bg-slate-100 text-slate-700 border border-slate-200"
                >
                  {skill}
                  <button
                    type="button"
                    onClick={() => handleRemoveSkill(skill)}
                    className="text-slate-500 hover:text-slate-700 font-bold"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>

        {/* ========== Categories ========== */}
        <div className="grid md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-2">
              Category <span className="text-red-500">*</span>
            </label>
            <select
              name="category_id"
              value={form.category_id}
              onChange={handleChange}
              className={`${inputBase} ${
                errors.category_id ? "ring-red-400 border-red-300" : ""
              }`}
            >
              <option value="">Select Category</option>
              {Array.isArray(categories) &&
                categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
            </select>
            {errors.category_id && (
              <p className="mt-1 text-sm text-red-500">
                {errors.category_id}
              </p>
            )}
          </div>

          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-2">
              Sub-category <span className="text-red-500">*</span>
            </label>
            <select
              name="sub_sub_category_id"
              value={form.sub_sub_category_id}
              onChange={handleChange}
              disabled={!form.category_id}
              className={`${inputBase} disabled:bg-slate-100 disabled:cursor-not-allowed ${
                errors.sub_sub_category_id
                  ? "ring-red-400 border-red-300"
                  : ""
              }`}
            >
              <option value="">Select Sub-category</option>
              {Array.isArray(subSubCategories) &&
                subSubCategories.map((sub) => (
                  <option key={sub.id} value={sub.id}>
                    {sub.name}
                  </option>
                ))}
            </select>
            {errors.sub_sub_category_id && (
              <p className="mt-1 text-sm text-red-500">
                {errors.sub_sub_category_id}
              </p>
            )}
          </div>
        </div>

        {/* ========== Project Type (projects only) ========== */}
        {!isTask && (
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-3">
              Project Type <span className="text-red-500">*</span>
            </label>
            <div className={`grid gap-3 ${ENABLE_HOURLY_PROJECT_TYPE ? "grid-cols-3" : "grid-cols-2"}`}>
              {[
                { value: "fixed", label: "Fixed Price", icon: "💰" },
                ...(ENABLE_HOURLY_PROJECT_TYPE ? [{ value: "hourly", label: "Hourly Rate", icon: "⏰" }] : []),
                { value: "bidding", label: "Bidding", icon: "🎯" },
              ].map((type) => {
                const active = form.project_type === type.value;
                return (
                  <button
                    key={type.value}
                    type="button"
                    onClick={() =>
                      handleChange({
                        target: { name: "project_type", value: type.value },
                      })
                    }
                    className={`p-4 rounded-xl border-2 transition-all text-center ${
                      active
                        ? "border-orange-500 bg-orange-50 shadow-sm"
                        : "border-slate-200 hover:border-orange-400/50"
                    }`}
                  >
                    <div className="text-2xl mb-1">{type.icon}</div>
                    <div className="font-semibold text-slate-800">
                      {type.label}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* ========== Budget / Price ========== */}
        <div className="bg-slate-50 p-6 rounded-2xl border border-slate-200">
          {form.project_type === "fixed" && (
            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Budget <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <span className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-medium">
                  $
                </span>
                <input
                  name="budget"
                  type="number"
                  min={1}
                  placeholder="0.00"
                  value={form.budget}
                  onChange={handleChange}
                  className={`${inputBase} pl-8 ${
                    errors.budget ? "ring-red-400 border-red-300" : ""
                  }`}
                />
              </div>
              {errors.budget && (
                <p className="mt-1 text-sm text-red-500">{errors.budget}</p>
              )}
              <p className="mt-2 text-slate-700 font-medium">
                Estimated amount to pay: ${calculateAmountToPay() || 0}
              </p>
            </div>
          )}

          {ENABLE_HOURLY_PROJECT_TYPE && !isTask && form.project_type === "hourly" && (
            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Hourly rate <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <span className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-medium">
                  $
                </span>
                <input
                  name="hourly_rate"
                  type="number"
                  min={1}
                  placeholder="0.00"
                  value={form.hourly_rate}
                  onChange={handleChange}
                  className={`${inputBase} pl-8 ${
                    errors.hourly_rate ? "ring-red-400 border-red-300" : ""
                  }`}
                />
              </div>
              {errors.hourly_rate && (
                <p className="mt-1 text-sm text-red-500">
                  {errors.hourly_rate}
                </p>
              )}
              <p className="mt-2 text-slate-700 text-sm">
                We’ll show freelancers an estimated total based on this rate.
              </p>
            </div>
          )}

          {!isTask && form.project_type === "bidding" && (
            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Budget range <span className="text-red-500">*</span>
              </label>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <span className="block text-xs text-slate-500 mb-1">
                    Min
                  </span>
                  <input
                    name="budget_min"
                    type="number"
                    min={1}
                    value={form.budget_min}
                    onChange={handleChange}
                    className={`${inputBase} ${
                      errors.budget_min ? "ring-red-400 border-red-300" : ""
                    }`}
                  />
                  {errors.budget_min && (
                    <p className="mt-1 text-sm text-red-500">
                      {errors.budget_min}
                    </p>
                  )}
                </div>
                <div>
                  <span className="block text-xs text-slate-500 mb-1">
                    Max
                  </span>
                  <input
                    name="budget_max"
                    type="number"
                    min={1}
                    value={form.budget_max}
                    onChange={handleChange}
                    className={`${inputBase} ${
                      errors.budget_max ? "ring-red-400 border-red-300" : ""
                    }`}
                  />
                  {errors.budget_max && (
                    <p className="mt-1 text-sm text-red-500">
                      {errors.budget_max}
                    </p>
                  )}
                </div>
              </div>
              <p className="mt-2 text-slate-700 text-sm">
                Freelancers will send offers inside this range.
              </p>
            </div>
          )}
        </div>

        {/* ========== Duration ========== */}
        {form.project_type !== "hourly" && (
          <div>
            <label className="block text-sm font-semibold text-slate-700 mb-3">
              {isTask ? "Task Duration" : "Project Duration"}
            </label>
            <div className="grid sm:grid-cols-2 gap-4">
              <select
                name="duration_type"
                value={form.duration_type}
                onChange={handleChange}
                className={inputBase}
              >
                <option value="days">Days</option>
                <option value="hours">Hours</option>
              </select>
              <input
                name={
                  form.duration_type === "days"
                    ? "duration_days"
                    : "duration_hours"
                }
                type="number"
                min={1}
                placeholder={`Duration in ${form.duration_type}`}
                value={
                  form.duration_type === "days"
                    ? form.duration_days
                    : form.duration_hours
                }
                onChange={handleChange}
                className={inputBase}
              />
            </div>
          </div>
        )}

        {/* ========== Submit ========== */}
        <button
          type="submit"
          disabled={!isFormValid}
          className={`w-full h-12 rounded-xl font-semibold transition flex items-center justify-center gap-2 ${
            !isFormValid
              ? "opacity-50 cursor-not-allowed bg-slate-300"
              : THEME.primaryBtn + " hover:shadow-lg"
          }`}
        >
          Continue to Files
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 7l5 5m0 0l-5 5m5-5H6"
            />
          </svg>
        </button>
      </form>
    </div>
  );
}
