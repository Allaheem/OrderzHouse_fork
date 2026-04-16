// components/Projects/ProjectsPage.jsx
import { useEffect, useMemo, useState } from "react";
import { useSearchParams, useLocation } from "react-router-dom";
import TopbarCategories from "./TopbarCategories.jsx";
import SubSidebar from "./SubSideBar.jsx";
import {
  fetchCategories,
  fetchSubCategoriesByCategoryId,
  fetchSubSubCategoriesBySubId,
} from "./api/category";

const THEME = "#F97316";
const THEME_DARK = "#C2410C";

export default function ProjectsPage({ mode: propMode }) {
  const [sp, setSp] = useSearchParams();
  const location = useLocation();

  const inferredMode = location.pathname.startsWith("/tasks")
    ? "tasks"
    : "projects";
  const mode = propMode || inferredMode;

  const q = (sp.get("q") || "").trim();
  const category = sp.get("cat") || "";
  const sub = sp.get("sub") || "";
  const subcat = sp.get("subcat") || "";
  const page = sp.get("page") || "";
  
  // Determine active category for tabs (UI only - URL is source of truth)
  const activeCategory = category ? String(category) : "all";

  const [catalog, setCatalog] = useState({});
  const [indexReady, setIndexReady] = useState(false);
  const [nameToCatId, setNameToCatId] = useState({});
  const [nameToSubCat, setNameToSubCat] = useState({});
  const [subSubInfo, setSubSubInfo] = useState(null);
  const [subCatInfo, setSubCatInfo] = useState(null);

  // Scroll to top when category/page params change
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  }, [category, sub, subcat, page, location.pathname]);

  // load categories
  useEffect(() => {
    const loadCategories = async () => {
      try {
        const cats = await fetchCategories();
        const catalogObj = Object.fromEntries(
          cats.map((c) => [
            String(c.id),
            {
              title: c.name,
              subtitle: c.description || c.subtitle || "", // <-- مهم
            },
          ])
        );

        setCatalog(catalogObj);
      } catch (_) {
      }
    };
    loadCategories();
  }, []);

  // build index for text search
  useEffect(() => {
    const buildIndex = async () => {
      try {
        const cats = Object.entries(catalog);
        if (!cats.length) return;

        const _nameToCatId = {};
        const _nameToSubCat = {};

        cats.forEach(([id, v]) => {
          const key = (v.title || "").toLowerCase();
          if (key) _nameToCatId[key] = id;
        });

        if (q) {
          await Promise.all(
            cats.map(async ([id]) => {
              try {
                const subs = await fetchSubCategoriesByCategoryId(Number(id));
                (subs || []).forEach((s) => {
                  const key = (s.name || "").toLowerCase();
                  if (!key) return;
                  _nameToSubCat[key] = { id: String(s.id), parentId: id };
                });
              } catch (e) {
                // Failed to load sub-categories
              }
            })
          );
        }

        setNameToCatId(_nameToCatId);
        setNameToSubCat(_nameToSubCat);
        setIndexReady(true);
      } catch (_) {
        setIndexReady(true);
      }
    };
    buildIndex();
  }, [catalog, q]);

  // STEP 4: Debug - Check if this auto-selection is interfering
  // REMOVED: Auto-select first category - "All" should be the default
  // This was preventing "All" tab from working correctly
  // useEffect(() => {
  //   if (!category && Object.keys(catalog).length > 0) {
  //     const firstId = Object.keys(catalog)[0];
  //     const next = new URLSearchParams(sp);
  //     next.set("cat", firstId);
  //     next.delete("sub");
  //     next.delete("subcat");
  //     next.delete("q");
  //     next.set("page", "1");
  //     setSp(next, { replace: true });
  //   }
  // }, [catalog, category, sp, setSp]);

  // search by text
  useEffect(() => {
    if (!q || !indexReady) return;
    if (category || subcat || sub) return;

    const term = q.toLowerCase().trim();

    const exactSub = nameToSubCat[term];
    if (exactSub) {
      const next = new URLSearchParams(sp);
      next.set("cat", exactSub.parentId);
      next.set("subcat", exactSub.id);
      next.delete("sub");
      next.delete("q");
      next.set("page", "1");
      setSp(next, { replace: true });
      return;
    }

    const exactCatId = nameToCatId[term];
    if (exactCatId) {
      const next = new URLSearchParams(sp);
      next.set("cat", exactCatId);
      next.delete("sub");
      next.delete("subcat");
      next.delete("q");
      next.set("page", "1");
      setSp(next, { replace: true });
      return;
    }

    const subHit = Object.entries(nameToSubCat).find(([k]) => k.includes(term));
    if (subHit) {
      const [, val] = subHit;
      const next = new URLSearchParams(sp);
      next.set("cat", val.parentId);
      next.set("subcat", val.id);
      next.delete("sub");
      next.delete("q");
      next.set("page", "1");
      setSp(next, { replace: true });
      return;
    }

    const catHit = Object.entries(nameToCatId).find(([k]) => k.includes(term));
    if (catHit) {
      const [, catId] = catHit;
      const next = new URLSearchParams(sp);
      next.set("cat", catId);
      next.delete("sub");
      next.delete("subcat");
      next.delete("q");
      next.set("page", "1");
      setSp(next, { replace: true });
      return;
    }

    const next = new URLSearchParams(sp);
    next.delete("q");
    setSp(next, { replace: true });
  }, [
    q,
    indexReady,
    nameToCatId,
    nameToSubCat,
    category,
    subcat,
    sub,
    sp,
    setSp,
  ]);

  // load sub-sub info (title/description)
  useEffect(() => {
    const loadSubSubInfo = async () => {
      if (!sub || !subcat) {
        setSubSubInfo(null);
        return;
      }

      try {
        const list = await fetchSubSubCategoriesBySubId(Number(subcat));
        const found =
          list && list.find((item) => String(item.id) === String(sub));
        setSubSubInfo(found || null);
      } catch (_) {
        setSubSubInfo(null);
      }
    };

    loadSubSubInfo();
  }, [sub, subcat]);
  useEffect(() => {
    const loadSubCatInfo = async () => {
      // لو مافي subcat أو فيه sub (sub-sub) نخليها null
      if (!subcat || sub) {
        setSubCatInfo(null);
        return;
      }

      try {
        const subs = await fetchSubCategoriesByCategoryId(Number(category));
        const found = subs?.find((s) => String(s.id) === String(subcat));
        setSubCatInfo(found || null);
      } catch (_) {
        setSubCatInfo(null);
      }
    };

    loadSubCatInfo();
  }, [category, subcat, sub]);

  const chooseCat = (id) => {
    const next = new URLSearchParams(sp);
    
    // If "all" is selected, remove category filter (URL is source of truth)
    if (id === "all" || id === "") {
      next.delete("cat");
    } else {
      next.set("cat", id.toString());
    }
    
    // Clear sub-category filters when changing category
    next.delete("sub");
    next.delete("subcat");
    next.delete("q");
    
    // Reset to page 1 when changing category
    next.set("page", "1");
    
    setSp(next, { replace: false });
  };

  const chooseSub = (subId) => {
    const next = new URLSearchParams(sp);
    if (subId) next.set("sub", subId.toString());
    else next.delete("sub");
    next.delete("subcat");
    next.delete("q");
    next.set("page", "1");
    setSp(next, { replace: false });
  };

  const handleSelectFromTopbar = (catId, subCatId, subSubId) => {
    const next = new URLSearchParams(sp);

    next.set("cat", catId.toString());

    if (subCatId) next.set("subcat", subCatId.toString());
    else next.delete("subcat");

    if (subSubId) next.set("sub", subSubId.toString());
    else next.delete("sub");

    next.delete("q");
    next.set("page", "1");
    setSp(next, { replace: false });
  };

  const meta = useMemo(
    () =>
      catalog[category] || {
        title: mode === "tasks" ? "Tasks" : "Projects",
        subtitle: "",
      },
    [catalog, category, mode]
  );

  return (
    <section className="relative min-h-[70vh] pb-8  via-white to-white">
      
      <div className="pointer-events-none absolute inset-0 -z-10 overflow-hidden">
        <div className="absolute -bottom-28 right-10 h-72 w-72 rounded-full bg-orange-100/60 blur-3xl" />
      </div>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 ">
        {/* sticky topbar */}
        <TopbarCategories
          active={activeCategory}
          onSelect={chooseCat}
          onSelectSubCategory={handleSelectFromTopbar}
          theme={THEME}
          themeDark={THEME_DARK}
        />

        {/* header */}
        <header className="mt-4 mb-6">
          <div className="flex items-center gap-2 text-sm">
            <a
              href="/"
              className="inline-flex items-center text-slate-600 hover:text-slate-800"
              aria-label="Home"
            >
              <svg
                className="w-4 h-4"
                viewBox="0 0 20 20"
                fill="none"
                stroke="currentColor"
              >
                <path
                  d="M3 9.5L10 3l7 6.5V17a1 1 0 01-1 1h-4.5v-4.5h-3V18H4a1 1 0 01-1-1V9.5z"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </a>
            <span className="text-slate-300">/</span>
            <h1
              className="text-xs sm:text-sm font-semibold tracking-tight text-slate-800"
              style={{ color: THEME_DARK }}
            >
              {meta.title}
            </h1>
          </div>

          {(() => {
            const headerTitle =
              subSubInfo?.name || subCatInfo?.name || meta.title;
            
            // When "All" tab is active (no category) and mode is projects, show "All projects"
            const isAllTabActive = !category && mode === "projects";
            const headerDesc =
              subSubInfo?.description ||
              subCatInfo?.description ||
              meta.subtitle ||
              (isAllTabActive ? "All projects" : ` "${headerTitle}".`);

            return (
              <div className="mt-2">
                <h2 className="text-xl sm:text-2xl font-semibold text-slate-900">
                  {headerTitle}
                </h2>

                <p className="text-xs sm:text-sm text-slate-600 mt-1 max-w-2xl leading-relaxed break-words [overflow-wrap:anywhere]">
                  {headerDesc}
                </p>
              </div>
            );
          })()}

          <hr className="mt-4 border-t border-slate-200" />
        </header>

        {/* content */}
        <SubSidebar
          mode={mode}
          categoryId={category}
          activeSubSub={sub}
          onSelectSubSub={chooseSub}
          theme={THEME}
          subCategoryId={subcat}
        />
      </div>
    </section>
  );
}
