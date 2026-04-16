import React, { useMemo, useEffect, useState } from "react";
import {
  fetchCategories,
  fetchSubCategoriesByCategoryId,
  fetchSubSubCategoriesBySubId,
} from "./api/category";

/**
 * شريط الكاتيجوري + الميجا منيو (3 ساب كاتيجوري وكل واحد تحته ساب ساب)
 */
export function CategoriesRail({
  active,
  onSelect,
  onSelectSubCategory, // (categoryId, subCategoryId, subSubId)
  catalog = {},
  theme,
  themeDark,
}) {
  const list = useMemo(
    () => {
      // Add "All" as the first tab
      const allTab = { id: "all", name: "All" };
      const categoryTabs = Object.entries(catalog).map(([id, v]) => ({
        id,
        name: v.title,
      }));
      return [allTab, ...categoryTabs];
    },
    [catalog]
  );

  // الكاتيجوري اللي عليه الهوفر حاليًا
  const [hoveredId, setHoveredId] = useState(null);

  // كل كاتيجوري => مصفوفة ساب كاتيجوري + ساب ساب
  // { [catId]: [{ id, name, subSubs: [...] }, ...] }
  const [menuMap, setMenuMap] = useState({});
  const [loadingFor, setLoadingFor] = useState(null);

  const handleHover = (id) => {
    setHoveredId(id);
    if (!id) return;

    // لو منيو هذا الكاتيجوري محملة مسبقًا ما نعيد الطلب
    if (menuMap[id]) return;

    setLoadingFor(id);

    (async () => {
      try {
        // 1) نحضر 3 الساب كاتيجوري لهذا الكاتيجوري
        const subs = await fetchSubCategoriesByCategoryId(Number(id));
        const subsArray = Array.isArray(subs) ? subs : [];

        // 2) لكل ساب كاتيجوري نحضر ساب ساب تبعه
        const withChildren = await Promise.all(
          subsArray.map(async (sub) => {
            try {
              const subSubs = await fetchSubSubCategoriesBySubId(
                Number(sub.id)
              );
              return {
                ...sub,
                subSubs: Array.isArray(subSubs) ? subSubs : [],
              };
            } catch (_) {
              return { ...sub, subSubs: [] };
            }
          })
        );

        setMenuMap((prev) => ({
          ...prev,
          [id]: withChildren,
        }));
      } catch (_) {
        setMenuMap((prev) => ({
          ...prev,
          [id]: [],
        }));
      } finally {
        setLoadingFor((prev) => (prev === id ? null : prev));
      }
    })();
  };

  const handleLeave = () => setHoveredId(null);

  const hoveredMenu = hoveredId ? menuMap[hoveredId] || [] : [];
  const hoveredName = hoveredId ? catalog[hoveredId]?.title || "" : "";

  if (!list.length) return null;

  return (
    <div className="relative" onMouseLeave={handleLeave}>
      {/* الشريط الرئيسي مثل Fiverr: نصوص وخط تحت النشط */}
      <nav className="overflow-x-auto whitespace-nowrap">
        <div className="flex items-stretch gap-6 border-b border-slate-200 min-h-[44px]">
          {list.map((c) => {
            // "All" is active when active === "all"
            // Category tabs are active when their id matches active
            const isAll = c.id === "all";
            const isActive = isAll 
              ? String(active) === "all"
              : String(c.id) === String(active);

            return (
              <button
                key={c.id}
                type="button"
                onClick={() => {
                  // Ensure "all" is passed correctly
                  const selectedId = c.id === "all" ? "all" : c.id.toString();
                  onSelect?.(selectedId);
                }}
                onMouseEnter={() => {
                  // Don't show hover menu for "All" tab
                  if (c.id !== "all") {
                    handleHover(c.id.toString());
                  }
                }}
                onFocus={() => {
                  // Don't show hover menu for "All" tab
                  if (c.id !== "all") {
                    handleHover(c.id.toString());
                  }
                }}
                className={
                  "relative pb-2 pt-2 text-sm md:text-[15px] whitespace-nowrap border-b-2 border-transparent transition-colors " +
                  (isActive
                    ? "font-semibold"
                    : "text-slate-500 hover:text-slate-900")
                }
                style={
                  isActive
                    ? { color: themeDark || "#0f172a", borderColor: theme }
                    : {}
                }
              >
                {c.name}
              </button>
            );
          })}
        </div>
      </nav>

      {/* الميجا منيو (تظهر تحت الشريط عند الهوفر – ديسكتوب فقط) */}
      {hoveredId && (
        <div className="hidden md:block absolute left-0 right-0 top-full z-40">
          <div className="mt-1 rounded-b-2xl border border-t-0 border-slate-200 bg-white shadow-lg px-6 py-4">
            <div className="mb-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">
                {hoveredName || "Category"}
              </p>
            </div>

            {loadingFor === hoveredId ? (
              <p className="text-xs text-slate-400">
                Loading...
              </p>
            ) : hoveredMenu.length ? (
              <div className="grid gap-x-10 gap-y-4 sm:grid-cols-2 md:grid-cols-3">
                {hoveredMenu.map((sub) => (
                  <div key={sub.id} className="min-w-[160px]">
                    {/* اسم الساب كاتيجوري (العنوان الغامق) */}
                    <h3 className="text-[13px] font-semibold text-slate-900 mb-2">
                      {sub.name}
                    </h3>

                    {/* الساب ساب كاتيجوري تحت العنوان */}
                    <ul className="space-y-1.5">
                      {sub.subSubs && sub.subSubs.length ? (
                        sub.subSubs.map((ss) => (
                          <li key={ss.id}>
                            <button
                              type="button"
                              onClick={() => {
                                onSelectSubCategory?.(
                                  hoveredId.toString(), // categoryId
                                  sub.id.toString(), // subCategoryId
                                  ss.id.toString() // subSubId
                                );
                                setHoveredId(null);
                              }}
                              className="text-[13px] text-slate-600 hover:text-slate-900"
                            >
                              {ss.name}
                            </button>
                          </li>
                        ))
                      ) : (
                        <li className="text-[12px] text-slate-400">
                          لا توجد عناصر
                        </li>
                      )}
                    </ul>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400">
                لا توجد أقسام فرعية لهذا القسم.
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * التوب بار اللاصق بالأعلى (يستخدم CategoriesRail داخله)
 * يبقى معك لما تسكرول.
 */
export default function Topbar({
  active,
  onSelect,
  onSelectSubCategory,
  theme = "#F97316",
  themeDark = "#C2410C",
}) {
  const [catalog, setCatalog] = useState({});

  useEffect(() => {
    const loadCategories = async () => {
      try {
        const categories = await fetchCategories();
        const catalogObj = Object.fromEntries(
          categories.map((c) => [c.id.toString(), { title: c.name }])
        );
        setCatalog(catalogObj);
      } catch (_) {
      }
    };
    loadCategories();
  }, []);

  return (
    <div className="sticky top-0 z-40 bg-white">
      <div className="-mx-4 sm:-mx-6 lg:-mx-8 px-4 sm:px-6 lg:px-8">
        <CategoriesRail
          active={active}
          onSelect={onSelect}
          onSelectSubCategory={onSelectSubCategory}
          catalog={catalog}
          theme={theme}
          themeDark={themeDark}
        />
      </div>
    </div>
  );
}
