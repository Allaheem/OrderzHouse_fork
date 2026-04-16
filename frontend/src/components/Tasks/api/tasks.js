import API from "../../../api/client.js";

/* ============================== ADMIN ============================== */
export const getAllTasksForAdmin = () => API.get("/tasks/admin");
export const approveTaskByAdmin = (id, status) => API.put(`/tasks/admin/${id}/status`, { status });
export const confirmPaymentByAdmin = (id) => API.put(`/tasks/admin/payment/${id}/confirm`);

/* ============================== FREELANCER ============================== */
export const createTask = (data) =>
  API.post("/tasks/freelancer", data, { headers: { "Content-Type": "multipart/form-data" } });
export const updateTask = (id, data) => API.put(`/tasks/freelancer/${id}`, data);
export const deleteTask = (id) => API.delete(`/tasks/freelancer/${id}`);
export const updateTaskRequestStatus = (requestId, status) =>
  API.put(`/tasks/freelancer/requests/${requestId}/status`, { status });
export const submitWorkCompletion = (id, data) =>
  API.post(`/tasks/freelancer/requests/${id}/submit`, data, {
    headers: { "Content-Type": "multipart/form-data" },
  });
export const resubmitWorkCompletion = (id, data) =>
  API.post(`/tasks/freelancer/requests/${id}/resubmit`, data, {
    headers: { "Content-Type": "multipart/form-data" },
  });
export const updateTaskKanbanStatus = (id, status) =>
  API.put(`/tasks/freelancer/${id}/kanban`, { new_status: status });
export const getFreelancerCreatedTasks = () => API.get("/tasks/freelancer/my-tasks");
export const getTaskRequests = (taskId) => API.get(`/tasks/freelancer/requests/${taskId}`);
export const getAssignedTasks = () => API.get("/tasks/freelancer/assigned");

/* ============================== CLIENT ============================== */
export const requestTask = (id, data) =>
  API.post(`/tasks/client/request/${id}`, data, { headers: { "Content-Type": "multipart/form-data" } });
export const submitPaymentProof = (id, data) =>
  API.post(`/tasks/client/payment/${id}`, data, { headers: { "Content-Type": "multipart/form-data" } });
export const approveWorkCompletion = (id, data) =>
  API.post(`/tasks/client/approve/${id}`, data, { headers: { "Content-Type": "multipart/form-data" } });
export const createReview = (id, data) => API.post(`/tasks/client/review/${id}`, data);

/* ============================== PUBLIC & SHARED ============================== */
export const getTaskPool = (category) =>
  API.get(`/tasks/pool${category ? `?category=${category}` : ""}`);
export const getTaskById = (id) => API.get(`/tasks/${id}`);
export const addTaskFiles = (id, data) =>
  API.post(`/tasks/files/${id}`, data, { headers: { "Content-Type": "multipart/form-data" } });

/* ============================== CATEGORY HIERARCHY ============================== */
export const getCategories = () => API.get("/tasks/categories");

// ✅ Get sub-categories by main category ID
export const getSubCategoriesByCategoryId = (categoryId) =>
  API.get(`/tasks/categories/${categoryId}/sub-categories`);

// ✅ Get sub-sub-categories by main category ID
export const getSubSubCategoriesByCategoryId = (categoryId) =>
  API.get(`/tasks/categories/${categoryId}/sub-sub-categories`);

// ✅ Get sub-sub-categories by sub-category ID
export const getSubSubCategoriesBySubCategoryId = (subCategoryId) =>
  API.get(`/tasks/categories/sub-category/${subCategoryId}/sub-sub-categories`);
