import API from "../../../api/client.js";
import store from "../../../store/store";

const getAuthToken = () => {
  return store?.getState()?.auth?.token || null;
};

const getAuthHeaders = () => {
  const token = getAuthToken();
  return token ? { headers: { Authorization: `Bearer ${token}` } } : {};
};

/* ==============================
   🔒 Authenticated (Token Required)
============================== */
export const fetchAuthProjectsByCategory = async (categoryId, options = {}) => {
  const { page = 1, limit = 20, search, sortBy } = options;
  try {
    const { data } = await API.get(
      `/projects/category/${categoryId}`,
      {
        ...getAuthHeaders(),
        params: { page, limit, search, sortBy },
      }
    );
    if (data.success) {
      return {
        projects: Array.isArray(data.projects) ? data.projects : [],
        pagination: data.pagination || null,
      };
    }
    throw new Error(data.message || "Failed to fetch projects");
  } catch (_) {
    return { projects: [], pagination: null };
  }
};

export const fetchAuthProjectsBySubCategory = async (
  subCategoryId,
  options = {}
) => {
  const { page = 1, limit = 20, search, sortBy } = options;
  try {
    const { data } = await API.get(
      `/projects/sub-category/${subCategoryId}`,
      {
        ...getAuthHeaders(),
        params: { page, limit, search, sortBy },
      }
    );
    if (data.success) {
      return {
        projects: Array.isArray(data.projects) ? data.projects : [],
        pagination: data.pagination || null,
      };
    }
    throw new Error(data.message || "Failed to fetch projects");
  } catch (_) {
    return { projects: [], pagination: null };
  }
};

export const fetchAuthProjectsBySubSubCategory = async (
  subSubCategoryId,
  options = {}
) => {
  const { page = 1, limit = 20, search, sortBy } = options;
  try {
    const { data } = await API.get(
      `/projects/sub-sub-category/${subSubCategoryId}`,
      {
        ...getAuthHeaders(),
        params: { page, limit, search, sortBy },
      }
    );
    if (data.success) {
      return {
        projects: Array.isArray(data.projects) ? data.projects : [],
        pagination: data.pagination || null,
      };
    }
    throw new Error(data.message || "Failed to fetch projects");
  } catch (_) {
    return { projects: [], pagination: null };
  }
};

/* ==============================
   🌍 Public (No Auth)
============================== */
export const fetchProjectsByCategory = async (categoryId) => {
  const { data } = await API.get(`/projects/public/category/${categoryId}`);
  if (data.success) return data.projects;
  throw new Error(data.message || "Failed to fetch projects");
};

export const fetchProjectsBySubCategory = async (subCategoryId) => {
  const { data } = await API.get(
    `/projects/public/subcategory/${subCategoryId}`
  );
  if (data.success) return data.projects;
  throw new Error(data.message || "Failed to fetch projects");
};

export const fetchProjectsBySubSubCategory = async (subSubCategoryId) => {
  try {
    const { data } = await API.get(
      `/projects/public/subsubcategory/${subSubCategoryId}`
    );
    if (data.success) return data.projects;
    throw new Error(data.message || "Failed to fetch projects");
  } catch (_) {
    return [];
  }
};

export const fetchProjectsByCategoryAuto = async (categoryId) => {
  const token = getAuthToken();
  if (token) {
    const result = await fetchAuthProjectsByCategory(categoryId);
    return result.projects;
  }
  return fetchProjectsByCategory(categoryId);
};

export const fetchProjectsBySubCategoryAuto = async (subCategoryId) => {
  const token = getAuthToken();
  if (token) {
    const result = await fetchAuthProjectsBySubCategory(subCategoryId);
    return result.projects;
  }
  return fetchProjectsBySubCategory(subCategoryId);
};

export const fetchProjectsBySubSubCategoryAuto = async (subSubCategoryId) => {
  const token = getAuthToken();
  if (token) {
    const result = await fetchAuthProjectsBySubSubCategory(subSubCategoryId);
    return result.projects;
  }
  return fetchProjectsBySubSubCategory(subSubCategoryId);
};

/* ==============================
   📌 GET PROJECT BY ID
============================== */
export const getProjectByIdApi = async (projectId, token) => {
  if (!projectId) throw new Error("Missing projectId");
  
  const authToken = token || getAuthToken();

  try {
    const config = authToken 
      ? { headers: { Authorization: `Bearer ${authToken}` } }
      : {};

    const { data } = await API.get(`/projects/${projectId}`, config);

    if (!data.success) throw new Error(data.message || "Failed to fetch project");
    return data.project;
  } catch (err) {
    throw err.response?.data || err;
  }
};

/* ==============================
   📎 GET PROJECT FILES BY PROJECT ID
============================== */
export const getProjectFilesApi = async (projectId) => {
  if (!projectId) throw new Error("Missing projectId");

  try {
    const { data } = await API.get(
      `/projects/${projectId}/files`,
      getAuthHeaders()
    );
    if (data.success && Array.isArray(data.files)) {
      return data.files;
    }
    throw new Error(data.message || "Failed to fetch project files");
  } catch (_) {
    return [];
  }
};

/* ==============================
   👷‍♂️ GET ASSIGNMENT FOR FREELANCER
============================== */
export const getAssignmentForFreelancerApi = async (projectId) => {
  if (!projectId) throw new Error("Missing projectId");

  try {
    const { data } = await API.get(
      `/assignments/${projectId}/my-assignment`,
      getAuthHeaders()
    );

    if (data.success) return data.assignment;
    return null; 
  } catch (err) {
    if (err.response?.status === 404) return null;
    
    throw new Error(err.response?.data?.message || err.message || "Failed to fetch assignment");
  }
};

/* ==============================
   📝 APPLY TO PROJECT (Freelancer)
============================== */

export const applyToProjectApi = async (projectId, body = {}, token) => {
  try {
    const { data } = await API.post(
      `/projects/${projectId}/apply`,
      body,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    return data; 
  } catch (err) {
    throw new Error(err.response?.data?.message || "Failed to apply to project");
  }
};


/* ==============================
   🔍 CHECK IF FREELANCER IS ASSIGNED / APPLIED
============================== */
export const checkIfAssignedApi = async (projectId, token) => {
  if (!projectId) throw new Error("Missing projectId");
  const authToken = token || getAuthToken();
  if (!authToken) throw new Error("Missing authentication token");

  try {
    const { data } = await API.get(
      `/assignments/${projectId}/check`,
      { headers: { Authorization: `Bearer ${authToken}` } }
    );

    if (data.success) return data.is_assigned;
    return false;
  } catch (_) {
    return false;
  }
};

/* ==============================
   📋 GET ALL PROJECT IDs WHERE USER HAS APPLIED
============================== */
export const getMyAppliedProjectIds = async () => {
  const token = getAuthToken();
  if (!token) return new Set();

  try {
    const { data } = await API.get(
      "/projects/applications/my-projects",
      getAuthHeaders()
    );

    if (data.success && Array.isArray(data.applications)) {
      // Extract unique project IDs from applications
      const projectIds = new Set(
        data.applications
          .map((app) => app.project_id)
          .filter((id) => id != null)
      );
      return projectIds;
    }
    return new Set();
  } catch (_) {
    return new Set();
  }
};