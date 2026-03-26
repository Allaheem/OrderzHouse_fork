// components/Projects/SubSideBar.jsx
import React, { useEffect, useMemo, useState } from "react";
import { useSelector } from "react-redux";
import { useSearchParams } from "react-router-dom";
import { fetchSubSubCategoriesByCategoryId } from "./api/category";

// Projects API
import {
  fetchAuthProjectsByCategory,
  fetchAuthProjectsBySubCategory,
  fetchAuthProjectsBySubSubCategory,
  checkIfAssignedApi,
} from "./api/projects";

// Tasks API
import { fetchTasksByFilter } from "../CreateProjects/api/tasks";

import ProjectCard from "./ProjectCard";

export default function SubSidebar({
  mode = "projects",
  categoryId,
  activeSubSub,
  onSelectSubSub,
  theme = "#028090",
  subCategoryId,
}) {
  const userData = useSelector((state) => state?.auth?.userData) || null;
  const [subSubs, setSubSubs] = useState([]);
  const [items, setItems] = useState([]);
  const [loadingSubSubs, setLoadingSubSubs] = useState(false);
  const [loadingItems, setLoadingItems] = useState(false);
  const [appliedProjectIds, setAppliedProjectIds] = useState(new Set());

  const [projectTypeFilter, setProjectTypeFilter] = useState("all");
  const [sortFilter, setSortFilter] = useState("newest");
  const [budgetFilter, setBudgetFilter] = useState("any");
  const [durationFilter, setDurationFilter] = useState("any");
  const [withFilesOnly, setWithFilesOnly] = useState(false);
  const [withFreelancerOnly, setWithFreelancerOnly] = useState(false);
  const [serverPagination, setServerPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 1,
  });
  const [sp, setSp] = useSearchParams();
  const pageFromUrl = Math.max(1, Number(sp.get("page") || 1));
  const PAGE_SIZE = 20;

  // Mobile filters sheet (phone UI)
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);

  const isTasks = mode === "tasks";

  const activeFiltersCount = useMemo(() => {
    return [
      projectTypeFilter !== "all",
      withFilesOnly,
      withFreelancerOnly,
    ].filter(Boolean).length;
  }, [projectTypeFilter, withFilesOnly, withFreelancerOnly]);

  const filterPillHint = activeFiltersCount === 0 ? "All" : `${activeFiltersCount}`;

  const SORT_LABELS = {
    newest: "Newest",
    price_low_high: "Low to High",
    price_high_low: "High to Low",
  };

  const sortPillLabel = SORT_LABELS[sortFilter] || "Newest";

  const filterSummary = activeFiltersCount === 0 ? "All" : `${activeFiltersCount} selected`;

  // Close sheet on Escape + prevent body scroll when open
  useEffect(() => {
    if (!mobileFiltersOpen) return;

    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    const onKeyDown = (e) => {
      if (e.key === "Escape") setMobileFiltersOpen(false);
    };
    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [mobileFiltersOpen]);

  // load sub-sub categories
  useEffect(() => {
    if (!categoryId) {
      setSubSubs([]);
      return;
    }

    setLoadingSubSubs(true);
    fetchSubSubCategoriesByCategoryId(Number(categoryId))
      .then((data) => setSubSubs(Array.isArray(data) ? data : []))
      .catch(() => setSubSubs([]))
      .finally(() => setLoadingSubSubs(false));
  }, [categoryId]);

  // load items (projects / tasks)
  useEffect(() => {
    // URL is source of truth - categoryId is empty string when "All" is selected
    // Don't fetch if we have subCategoryId or activeSubSub but no categoryId (invalid state)
    if ((subCategoryId || activeSubSub) && !categoryId && !isTasks) {
      setItems([]);
      setLoadingItems(false);
      return;
    }

    // Tasks require a category
    if (isTasks && !categoryId) {
      setItems([]);
      setLoadingItems(false);
      return;
    }

    setLoadingItems(true);

    const run = async () => {
      try {
        if (isTasks) {
          if (!categoryId) {
            setItems([]);
            setLoadingItems(false);
            return;
          }
          const data = await fetchTasksByFilter({
            category: Number(categoryId),
            subcat: subCategoryId ? Number(subCategoryId) : undefined,
            sub: activeSubSub ? Number(activeSubSub) : undefined,
          });
          setItems(Array.isArray(data) ? data : []);
          setServerPagination({
            page: 1,
            limit: PAGE_SIZE,
            total: Array.isArray(data) ? data.length : 0,
            totalPages: 1,
          });
          setLoadingItems(false);
          return;
        }

        // projects
        let data;
        if (activeSubSub) {
          data = await fetchAuthProjectsBySubSubCategory(Number(activeSubSub), {
            page: pageFromUrl,
            limit: PAGE_SIZE,
            sortBy: sortFilter,
          });
        } else if (subCategoryId) {
          data = await fetchAuthProjectsBySubCategory(Number(subCategoryId), {
            page: pageFromUrl,
            limit: PAGE_SIZE,
            sortBy: sortFilter,
          });
        } else {
          // When categoryId is empty (All selected), pass "all" to backend
          // Backend treats "all" as missing category filter
          const catId = categoryId || "all";
          data = await fetchAuthProjectsByCategory(
            catId === "all" ? "all" : Number(catId),
            {
              page: pageFromUrl,
              limit: PAGE_SIZE,
              sortBy: sortFilter,
            }
          );
        }

        const projects = Array.isArray(data?.projects) ? data.projects : [];
        setItems(projects);
        setServerPagination(
          data?.pagination || {
            page: pageFromUrl,
            limit: PAGE_SIZE,
            total: projects.length,
            totalPages: 1,
          }
        );

        // Batch check which projects user has applied to (only for freelancers)
        if (projects.length > 0 && !isTasks) {
          const token = localStorage.getItem("token");
          const roleIdFromState = userData?.role_id || userData?.roleId;
          const roleIdFromStorage = localStorage.getItem("roleId");
          const roleId = roleIdFromState || roleIdFromStorage;
          const isFreelancer = String(roleId) === "3";

          if (token && isFreelancer) {
            // Check in parallel (limit to first 30 projects to avoid too many requests)
            const projectsToCheck = projects
              .filter((project) => project?.is_actionable !== false)
              .slice(0, 30);
            const checkPromises = projectsToCheck.map(async (project) => {
              try {
                const hasApplied = await checkIfAssignedApi(project.id, token);
                return hasApplied ? project.id : null;
              } catch (err) {
                return null;
              }
            });

            const results = await Promise.all(checkPromises);
            const appliedIds = new Set(results.filter((id) => id != null));
            setAppliedProjectIds(appliedIds);
          } else {
            setAppliedProjectIds(new Set());
          }
        } else {
          setAppliedProjectIds(new Set());
        }
      } catch (err) {
        console.error("SubSidebar fetch error:", err);
        setItems([]);
      } finally {
        setLoadingItems(false);
      }
    };

    run();
  }, [
    categoryId,
    activeSubSub,
    subCategoryId,
    isTasks,
    userData,
    sortFilter,
    pageFromUrl,
  ]);

  useEffect(() => {
    const next = new URLSearchParams(sp);
    if (next.get("page") !== "1") {
      next.set("page", "1");
      setSp(next, { replace: true });
    }
  }, [
    categoryId,
    activeSubSub,
    subCategoryId,
    projectTypeFilter,
    budgetFilter,
    durationFilter,
    withFilesOnly,
    withFreelancerOnly,
    sortFilter,
  ]);

  const hasSidebar = subSubs.length > 0;
  const priceField = isTasks ? "price" : "budget";

  // helpers (projects only)
  const getProjectType = (item) => item?.project_type || null;

  const getBudgetRange = (item) => {
    const type = item?.project_type;

    if (type === "fixed") {
      const value = Number(item?.budget || 0);
      return [value, value];
    }

    if (type === "hourly") {
      const rate = Number(item?.hourly_rate || 0);
      const total = rate * 3;
      return [total, total];
    }

    if (type === "bidding") {
      const min = Number(item?.budget_min || 0);
      const max = Number(item?.budget_max || min);
      return [min, max];
    }

    const value = Number(item?.price || 0);
    return [value, value];
  };

  const getDurationInDays = (item) => {
    const durationType = item?.duration_type;
    if (!durationType) return null;

    if (durationType === "days") {
      const d = Number(item?.duration_days || 0);
      return Number.isFinite(d) ? d : null;
    }

    if (durationType === "hours") {
      const h = Number(item?.duration_hours || 0);
      if (!Number.isFinite(h)) return null;
      return h / 24;
    }

    return null;
  };

  const hasFilesInfo = (item) =>
    item &&
    ("files_count" in item ||
      "filesCount" in item ||
      Array.isArray(item.files));

  const itemHasFiles = (item) => {
    if (!item) return false;
    if ("files_count" in item) return Number(item.files_count) > 0;
    if ("filesCount" in item) return Number(item.filesCount) > 0;
    if (Array.isArray(item.files)) return item.files.length > 0;
    return false;
  };

  const hasFreelancerInfo = (item) =>
    item &&
    ("freelancer_id" in item ||
      "assigned_freelancer_id" in item ||
      "freelancer" in item ||
      "assigned_freelancer" in item);

  const itemHasFreelancer = (item) => {
    if (!item) return false;
    if ("freelancer_id" in item && item.freelancer_id) return true;
    if ("assigned_freelancer_id" in item && item.assigned_freelancer_id)
      return true;
    if (item.freelancer) return true;
    if (item.assigned_freelancer) return true;
    return false;
  };

  const SkeletonGrid = () => (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="animate-pulse">
          <div className="aspect-[16/9] bg-slate-200 rounded-xl mb-3" />
          <div className="h-4 bg-slate-200 rounded w-3/4 mb-2" />
          <div className="h-4 bg-slate-200 rounded w-1/2" />
        </div>
      ))}
    </div>
  );

  const FilterDropdown = ({ label, value, onChange, options }) => (
    <div className="inline-flex items-center">
      <div className="inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5">
        <span className="text-sm text-slate-700 mr-2 whitespace-nowrap">
          {label}
        </span>
        <select
          className="bg-transparent text-sm text-slate-600 focus:outline-none focus:ring-0 pr-4"
          value={value}
          onChange={(e) => onChange(e.target.value)}
        >
          {options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>
    </div>
  );

  const Toggle = ({ checked, onChange, label }) => (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className="inline-flex items-center gap-2 text-sm text-slate-700"
    >
      <span
        className={
          "relative inline-flex h-5 w-9 items-center rounded-full border transition-colors " +
          (checked
            ? "bg-emerald-500 border-emerald-500"
            : "bg-slate-200 border-slate-300")
        }
      >
        <span
          className={
            "inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform " +
            (checked ? "translate-x-4" : "translate-x-1")
          }
        />
      </span>
      <span>{label}</span>
    </button>
  );

  // filters (projects only)
  let visibleItems = items;

  if (!isTasks && items.length) {
    visibleItems = items.filter((item) => {
      if (projectTypeFilter !== "all") {
        const type = getProjectType(item);
        if (type && type !== projectTypeFilter) return false;
      }

      if (budgetFilter !== "any") {
        const [minBudget, maxBudget] = getBudgetRange(item);

        if (budgetFilter === "0-100" && !(maxBudget <= 100)) return false;
        if (
          budgetFilter === "100-500" &&
          !(minBudget <= 500 && maxBudget >= 100)
        )
          return false;
        if (
          budgetFilter === "500-1000" &&
          !(minBudget <= 1000 && maxBudget >= 500)
        )
          return false;
        if (budgetFilter === "1000+" && !(minBudget >= 1000)) return false;
      }

      if (durationFilter !== "any") {
        const days = getDurationInDays(item);
        if (days != null) {
          if (durationFilter === "1" && !(days <= 1)) return false;
          if (durationFilter === "3" && !(days <= 3)) return false;
          if (durationFilter === "7" && !(days <= 7)) return false;
          if (durationFilter === "7+" && !(days > 7)) return false;
        }
      }

      if (withFilesOnly && hasFilesInfo(item) && !itemHasFiles(item)) {
        return false;
      }

      if (
        withFreelancerOnly &&
        hasFreelancerInfo(item) &&
        !itemHasFreelancer(item)
      ) {
        return false;
      }

      return true;
    });

    if (sortFilter === "price_low_high") {
      visibleItems = [...visibleItems].sort((a, b) => {
        const [, maxA] = getBudgetRange(a);
        const [, maxB] = getBudgetRange(b);
        return maxA - maxB;
      });
    } else if (sortFilter === "price_high_low") {
      visibleItems = [...visibleItems].sort((a, b) => {
        const [, maxA] = getBudgetRange(a);
        const [, maxB] = getBudgetRange(b);
        return maxB - maxA;
      });
    } else if (sortFilter === "newest") {
      visibleItems = [...visibleItems].sort((a, b) => {
        const dateA = new Date(a.created_at || a.createdAt || 0).getTime();
        const dateB = new Date(b.created_at || b.createdAt || 0).getTime();
        return dateB - dateA;
      });
    }
  }

  return (
    <div className="w-full">
      {/* filters bar – projects only */}
      {!isTasks && (
        <div className="mb-4">
          {/* Desktop (keep your original layout) */}
          <div className="hidden sm:flex flex-wrap items-center justify-between gap-3">
            <div className="flex flex-wrap items-center gap-3">
              <FilterDropdown
                label="Project type"
                value={projectTypeFilter}
                onChange={setProjectTypeFilter}
                options={[
                  { value: "all", label: "All types" },
                  { value: "fixed", label: "Fixed price" },
                  { value: "hourly", label: "Hourly" },
                  { value: "bidding", label: "Bidding" },
                ]}
              />
            </div>

       
          </div>

          {/* Mobile (phone UI like apps) */}
          <div className="sm:hidden flex items-center gap-3">
            <button
              type="button"
              onClick={() => setMobileFiltersOpen(true)}
              className={[
                "flex-1 flex items-center justify-between",
                "rounded-full border border-slate-200 bg-white/90 backdrop-blur",
                "px-4 py-3 shadow-sm",
                "active:scale-[0.99]",
              ].join(" ")}
            >
              <span className="text-sm font-semibold text-slate-900">Filters</span>
              <span className="text-xs font-semibold text-slate-400">{filterPillHint}</span>
            </button>

            <div className="relative shrink-0">
              <div
                className={[
                  "flex items-center gap-2",
                  "rounded-full border border-slate-200 bg-white/90 backdrop-blur",
                  "px-4 py-3 shadow-sm",
                ].join(" ")}
              >
                <span className="text-sm font-semibold text-slate-900">{sortPillLabel}</span>
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  className="text-slate-500"
                >
                  <path
                    d="M6 9l6 6l6-6"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </div>

              {/* invisible select above the pill */}
              <select
                value={sortFilter}
                onChange={(e) => setSortFilter(e.target.value)}
                className="absolute inset-0 h-full w-full cursor-pointer opacity-0"
                aria-label="Sort"
              >
                <option value="newest">Newest</option>
                <option value="price_low_high">Price: Low to High</option>
                <option value="price_high_low">Price: High to Low</option>
              </select>
            </div>
          </div>

          {/* Mobile filters sheet */}
          <div
            className={[
              "fixed inset-0 z-[9998] sm:hidden",
              mobileFiltersOpen ? "" : "pointer-events-none",
            ].join(" ")}
          >
            {/* backdrop */}
            <div
              className={[
                "absolute inset-0 bg-slate-900/40",
                "transition-opacity duration-200",
                mobileFiltersOpen ? "opacity-100" : "opacity-0",
              ].join(" ")}
              onClick={() => setMobileFiltersOpen(false)}
            />

            {/* sheet */}
            <div
              className={[
                "absolute inset-x-0 bottom-0 mx-auto w-full max-w-lg",
                "rounded-t-3xl bg-white",
                "p-4 shadow-2xl ring-1 ring-black/10",
                "transition-transform duration-300",
                mobileFiltersOpen ? "translate-y-0" : "translate-y-full",
              ].join(" ")}
              role="dialog"
              aria-modal="true"
              aria-label="Filters"
            >
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-base font-bold text-slate-900">Filters</div>
                  <div className="text-xs text-slate-500">
                    {filterSummary}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setMobileFiltersOpen(false)}
                  className="grid h-10 w-10 place-items-center rounded-full border border-slate-200 bg-white shadow-sm"
                  aria-label="Close"
                >
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" className="text-slate-700">
                    <path
                      d="M6 6l12 12M18 6L6 18"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                    />
                  </svg>
                </button>
              </div>

              <div className="mt-4 space-y-3">
                {/* Project type */}
                <div className="rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
                  <div className="text-sm font-semibold text-slate-800">Project type</div>
                  <div className="relative mt-2">
                    <select
                      value={projectTypeFilter}
                      onChange={(e) => setProjectTypeFilter(e.target.value)}
                      className="h-12 w-full appearance-none rounded-xl border border-slate-200 bg-slate-50 px-4 pr-10 text-sm font-semibold text-slate-900 outline-none focus:ring-2 focus:ring-orange-200"
                    >
                      <option value="all">All types</option>
                      <option value="fixed">Fixed price</option>
                      <option value="hourly">Hourly</option>
                      <option value="bidding">Bidding</option>
                    </select>
                    <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-slate-500">
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                        <path d="M6 9l6 6l6-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    </span>
                  </div>
                </div>

              </div>

              <button
                type="button"
                onClick={() => setMobileFiltersOpen(false)}
                className={[
                  "mt-4 w-full",
                  "rounded-full px-6 py-3",
                  "text-sm font-semibold text-white",
                  "bg-gradient-to-b from-orange-400 to-red-500",
                  "shadow-[0_12px_24px_rgba(249,115,22,0.25)]",
                  "ring-1 ring-black/10",
                ].join(" ")}
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}

      {/* results bar */}
      {!isTasks && (
        <div className="mb-4 flex items-center justify-between text-sm px-3">
          <span className="text-slate-600">
            {(serverPagination.total || visibleItems.length).toLocaleString()} results
          </span>
            <div className="hidden sm:flex items-center gap-2">
            <span className="text-slate-500">Sort by:</span>
            <select
              value={sortFilter}
              onChange={(e) => setSortFilter(e.target.value)}
              className="bg-transparent text-sm font-semibold text-slate-800 focus:outline-none cursor-pointer"
            >
              <option value="newest">Newest</option>
              <option value="price_low_high">Price: Low to High</option>
              <option value="price_high_low">Price: High to Low</option>
            </select>
          </div>
        </div>
      )}

      {isTasks && (
        <div className="mb-4 flex items-center justify-between text-sm px-3">
          <span className="text-slate-600">
            {items.length.toLocaleString()} tasks
          </span>
        </div>
      )}

      {/* grid */}
      <div className="flex w-full gap-6 lg:gap-8">
        <div className="flex-1 min-w-0">
          {loadingItems ? (
            <SkeletonGrid />
          ) : visibleItems.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center">
              <h3 className="text-lg font-semibold text-slate-700 mb-1">
                {isTasks ? "No tasks found" : "No projects found"}
              </h3>
              <p className="text-sm text-slate-500">
                Try changing the filters or selecting a different category
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {visibleItems.map((it) => (
                <ProjectCard
                  key={it.id}
                  project={it}
                  theme={theme}
                  linkBase={isTasks ? "tasks" : "projects"}
                  priceField={priceField}
                  hasApplied={appliedProjectIds.has(it.id)}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {!isTasks && (serverPagination.totalPages || 1) > 1 && (
        <div className="mt-6 flex items-center justify-center gap-2">
          <button
            type="button"
            disabled={pageFromUrl <= 1}
            onClick={() => {
              const next = new URLSearchParams(sp);
              next.set("page", String(Math.max(1, pageFromUrl - 1)));
              setSp(next, { replace: false });
            }}
            className="px-3 py-1.5 text-sm border border-slate-300 rounded-lg disabled:opacity-50"
          >
            Previous
          </button>
          <span className="text-sm text-slate-600">
            Page {serverPagination.page || pageFromUrl} of{" "}
            {serverPagination.totalPages || 1}
          </span>
          <button
            type="button"
            disabled={pageFromUrl >= (serverPagination.totalPages || 1)}
            onClick={() => {
              const next = new URLSearchParams(sp);
              next.set(
                "page",
                String(
                  Math.min(serverPagination.totalPages || 1, pageFromUrl + 1)
                )
              );
              setSp(next, { replace: false });
            }}
            className="px-3 py-1.5 text-sm border border-slate-300 rounded-lg disabled:opacity-50"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}
