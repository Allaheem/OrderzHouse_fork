import API, { getWebSocketBaseURL } from "../../../api/client.js";
import store from "../../../store/store";

const getAuthToken = () =>
  store?.getState()?.auth?.token || null;

const getAuthHeaders = () => {
  const token = getAuthToken();
  return token ? { headers: { Authorization: `Bearer ${token}` } } : {};
};

/* ============================================================================
    FREELANCER APIs
============================================================================ */

export const createTaskApi = async (formData) => {
  const res = await API.post("/tasks/tasks", formData, {
    headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
  });
  return res.data;
};

export const updateTaskApi = async (id, data) => {
  const res = await API.put(`/tasks/tasks/${id}`, data, getAuthHeaders());
  return res.data;
};

export const deleteTaskApi = async (id) => {
  const res = await API.delete(`/tasks/tasks/${id}`, getAuthHeaders());
  return res.data;
};

export const updateTaskRequestStatusApi = async (requestId, status) => {
  const res = await API.put(
    `/tasks/tasks/requests/${requestId}/status`,
    { status },
    getAuthHeaders()
  );
  return res.data;
};

export const submitWorkCompletionApi = async (requestId, formData) => {
  const res = await API.post(
    `/tasks/tasks/requests/${requestId}/submit`,
    formData,
    {
      headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
    }
  );
  return res.data;
};

export const resubmitWorkCompletionApi = async (requestId, formData) => {
  const res = await API.post(
    `/tasks/tasks/requests/${requestId}/resubmit`,
    formData,
    {
      headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
    }
  );
  return res.data;
};

export const updateTaskKanbanStatusApi = async (id, status) => {
  const res = await API.put(`/tasks/tasks/${id}/kanban`, { status }, getAuthHeaders());
  return res.data;
};

/* ============================================================================
   👥 CLIENT APIs
============================================================================ */

export const requestTaskApi = async (taskId, formData) => {
  const res = await API.post(`/tasks/tasks/${taskId}/request`, formData, {
    headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
  });
  return res.data;
};

export const submitPaymentProofApi = async (taskId, formData) => {
  const res = await API.post(`/tasks/tasks/${taskId}/payment-proof`, formData, {
    headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
  });
  return res.data;
};

export const approveWorkCompletionApi = async (requestId, action, formData) => {
  const res = await API.put(`/tasks/tasks/requests/${requestId}/approve`, formData, {
    headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
    params: { action },
  });
  return res.data;
};

export const createReviewApi = async (taskId, data) => {
  const res = await API.post(`/tasks/tasks/${taskId}/review`, data, getAuthHeaders());
  return res.data;
};

/* ============================================================================
    ADMIN APIs
============================================================================ */

export const getAllTasksForAdminApi = async () => {
  const res = await API.get("/tasks/tasks/admin/all", getAuthHeaders());
  return res.data;
};

export const approveTaskByAdminApi = async (id, status) => {
  const res = await API.put(`/tasks/tasks/${id}/approve`, { status }, getAuthHeaders());
  return res.data;
};

export const confirmPaymentByAdminApi = async (requestId) => {
  const res = await API.put(
    `/tasks/tasks/requests/${requestId}/confirm-payment`,
    {},
    getAuthHeaders()
  );
  return res.data;
};

/* ============================================================================
    PUBLIC / SHARED APIs
============================================================================ */

export const getTaskPoolApi = async (categoryId) => {
  const res = await API.get("/tasks/tasks/pool", {
    params: categoryId ? { category: categoryId } : {},
  });
  return res.data;
};

export const getTaskByIdApi = async (taskId) => {
  const res = await API.get(`/tasks/tasks/${taskId}`, getAuthHeaders());
  return res.data;
};

export const addTaskFilesApi = async (requestId, formData) => {
  const res = await API.post(`/tasks/tasks/files/${requestId}`, formData, {
    headers: { ...getAuthHeaders().headers, "Content-Type": "multipart/form-data" },
  });
  return res.data;
};

export const getCategoriesApi = async () => {
  const res = await API.get("/tasks/tasks/categories");
  return res.data;
};

/* ============================================================================
    NOTIFICATIONS (using WebSocket)
============================================================================ */
let notificationSocket = null;

export const connectNotifications = (userId, onMessage) => {
  if (notificationSocket) return;
  const wsBase = getWebSocketBaseURL();
  notificationSocket = new WebSocket(`${wsBase}/ws/notifications?user=${userId}`);

  notificationSocket.onopen = () => {};
  notificationSocket.onmessage = (msg) => {
    const data = JSON.parse(msg.data);
    if (onMessage) onMessage(data);
  };
  notificationSocket.onclose = () => {
    setTimeout(() => connectNotifications(userId, onMessage), 5000);
  };
};

export const disconnectNotifications = () => {
  if (notificationSocket) {
    notificationSocket.close();
    notificationSocket = null;
  }
};

/* ============================================================================
    CHAT SOCKET (Realtime Messaging)
============================================================================ */
let chatSocket = null;

export const connectChat = (projectOrTaskId, userId, onMessage) => {
  if (chatSocket) return;
  const wsBase = getWebSocketBaseURL();
  chatSocket = new WebSocket(
    `${wsBase}/ws/chat?room=${projectOrTaskId}&user=${userId}`
  );

  chatSocket.onopen = () => {};
  chatSocket.onmessage = (msg) => {
    const data = JSON.parse(msg.data);
    if (onMessage) onMessage(data);
  };
  chatSocket.onclose = () => {
    setTimeout(() => connectChat(projectOrTaskId, userId, onMessage), 5000);
  };
};

export const sendChatMessage = (message) => {
  if (chatSocket && chatSocket.readyState === WebSocket.OPEN) {
    chatSocket.send(JSON.stringify(message));
  }
};

export const disconnectChat = () => {
  if (chatSocket) {
    chatSocket.close();
    chatSocket = null;
  }
};
