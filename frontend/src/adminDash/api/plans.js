import API from "./axios";

/* ----------------------
   PUBLIC ROUTES
---------------------- */

export const getPlans = async (withCounts = false) => {
  const response = await API.get(`/plans${withCounts ? "?withCounts=true" : ""}`);
  return response.data;
};

/* ----------------------
   ADMIN ROUTES
---------------------- */

export const getPlanSubscriptionCounts = async () => {
  const response = await API.get("/plans/subscriptions/counts");
  return response.data;
};

export const getAllSubscriptions = async () => {
  const response = await API.get("/plans/subscriptions/all");
  return response.data;
};

export const getPlanSubscribers = async (planId) => {
  const response = await API.get(`/plans/${planId}/subscribers`);
  return response.data;
};

export const createPlan = async (planData) => {
  const response = await API.post("/plans/create", planData);
  return response.data;
};

export const editPlan = async (id, planData) => {
  const response = await API.put(`/plans/edit/${id}`, planData);
  return response.data;
};

export const deletePlan = async (id) => {
  const response = await API.delete(`/plans/delete/${id}`);
  return response.data;
};

export const adminUpdateSubscription = async (data) => {
  const response = await API.patch("/plans/admin/subscription", data);
  return response.data;
};

export const adminCancelSubscription = async (planId, subscriptionId) => {
  const response = await API.patch(`/plans/${planId}/subscribers/${subscriptionId}`);
  return response.data;
};


/* ----------------------
   FREELANCER ROUTES
---------------------- */

export const getFreelancerSubscription = async () => {
  const response = await API.get("/plans/subscription/me");
  return response.data;
};

export const subscribeToPlan = async (planId) => {
  const response = await API.post("/plans/subscribe", { plan_id: planId });
  return response.data;
};

export const cancelSubscription = async () => {
  const response = await API.patch("/plans/cancel");
  return response.data;
};

/* ----------------------
   EXPORT DEFAULT
---------------------- */
export default {
  getPlans,
  getPlanSubscriptionCounts,
  getAllSubscriptions,
  getPlanSubscribers,
  createPlan,
  editPlan,
  deletePlan,
  adminUpdateSubscription,
  adminCancelSubscription,
  getFreelancerSubscription,
  subscribeToPlan,
  cancelSubscription,
};
