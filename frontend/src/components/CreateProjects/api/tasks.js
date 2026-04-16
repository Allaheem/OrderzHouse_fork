import API from "../../../api/client.js";

// 1) Create task
export const createTaskApi = async (formData, token) => {
  try {
    const res = await API.post("/tasks/freelancer", formData, {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "multipart/form-data",
      },
    });
    return res.data.task;
  } catch (err) {
    throw err.response?.data || err;
  }
};

// 2) Upload task files
export const uploadTaskFilesApi = async (requestId, files, token) => {
  try {
    const fd = new FormData();
    files.forEach((file) => fd.append("files", file));

    const res = await API.post(`/tasks/files/${requestId}`, fd, {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "multipart/form-data",
      },
    });

    return res.data;
  } catch (err) {
    throw err.response?.data || err;
  }
};

// 3) Fetch tasks by filter for /tasks catalog
export const fetchTasksByFilter = async ({ category, subcat, sub } = {}) => {
  try {
    const params = {};
    if (category) params.category = category;
    if (subcat) params.sub_category_id = subcat;
    if (sub) params.sub_sub_category_id = sub;

    const res = await API.get("/tasks/pool", { params });
    return res.data.tasks || [];
  } catch (err) {
    throw err.response?.data || err;
  }
};

// 4) Single task
export const getTaskByIdApi = async (id) => {
  try {
    const res = await API.get(`/tasks/${id}`);
    return res.data.task;
  } catch (err) {
    throw err.response?.data || err;
  }
};
