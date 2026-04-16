import API from "../../../api/client.js";

// ================== CATEGORIES ==================
export const fetchCategories = async () => {
  const { data } = await API.get("/category/");
  if (data.success) return data.data;
  throw new Error(data.message || "Failed to fetch categories");
};

export const fetchCategoryById = async (id) => {
  const { data } = await API.get(`/category/${id}`);
  if (data.success) return data.data;
  throw new Error(data.message || "Failed to fetch category");
};

// ================== SUB‑CATEGORIES ==================
export const fetchSubCategoriesByCategoryId = async (categoryId) => {
  const { data } = await API.get(
    `/category/${categoryId}/sub-categories`,
    { meta: { silent: true } } // ما تظهر شاشة التحميل
  );
  if (data.success) return data.data;
  throw new Error(data.message || "Failed to fetch sub-categories");
};

// ================== SUB‑SUB BY SUB‑CATEGORY ==================
export const fetchSubSubCategoriesBySubId = async (subCategoryId) => {
  const { data } = await API.get(
    `/category/sub-category/${subCategoryId}/sub-sub-categories`,
    { meta: { silent: true } }
  );
  if (data.success) return data.data;
  throw new Error(
    data.message || "Failed to fetch sub-sub-categories by sub-category"
  );
};

// ================== ✅ SUB‑SUB BY CATEGORY ==================
/**
 * ترجع كل الـ sub‑sub‑categories التابعة لكاتيجوري معيّن
 * 1) نجيب 3 ساب كاتيجوري للكاتيجوري
 * 2) لكل واحد نجيب ساب‑ساب تبعه
 * 3) نعمل flatten للمصفوفات ونرجعها
 */
export const fetchSubSubCategoriesByCategoryId = async (categoryId) => {
  try {
    // 1) sub‑categories للكاتيجوري
    const subs = await fetchSubCategoriesByCategoryId(categoryId);
    const subsArray = Array.isArray(subs) ? subs : [];

    if (!subsArray.length) return [];

    // 2) نجيب sub‑sub لكل sub‑category (على التوازي)
    const results = await Promise.all(
      subsArray.map((sub) =>
        fetchSubSubCategoriesBySubId(sub.id).catch((_) => {
          return [];
        })
      )
    );

    // 3) ندمج كل النتائج في مصفوفة واحدة
    return results.reduce(
      (all, arr) => all.concat(Array.isArray(arr) ? arr : []),
      []
    );
  } catch (_) {
    return [];
  }
};
