import API from "../../../api/client.js";

/**
 * Helper: Auth header
 */
const authHeaders = (token) => ({
  headers: {
    Authorization: `Bearer ${token}`,
  },
});


/* =====================================================
    SEND OFFER FOR A PROJECT
===================================================== */
export const sendOfferApi = async (projectId, payload, token) => {
  if (!projectId) throw new Error("Missing projectId");

  const body = {
    bid_amount: payload.offer_amount, 
    proposal: payload.message || "",  
  };

  try {
    const { data } = await API.post(
      `/offers/${projectId}/offers`,
      body,
      token ? authHeaders(token) : undefined
    );

    if (data?.success) return data;
    throw new Error(data?.message || "Failed to send offer");
  } catch (err) {
    throw new Error(err.response?.data?.message || err.message || "Failed to send offer");
  }
};
/* =====================================================
    GET MY OFFERS FOR A SPECIFIC PROJECT
===================================================== */
export const getMyOffersForProjectApi = async (projectId, token) => {
  const { data } = await API.get(
    `/offers/${projectId}/my-offers`,
    authHeaders(token)
  );
  if (data.success) return data.data || data.offers || [];
  throw new Error(data.message || "Failed to fetch my offers for this project");
};

/* =====================================================
   GET OFFERS FOR ALL PROJECTS OWNED BY THE LOGGED-IN CLIENT
   (Client view) - returns array of offers with freelancer and project info
===================================================== */
export const getOffersForMyProjectsApi = async (token) => {
  try {
    const { data } = await API.get("/offers/my-projects/offers", authHeaders(token));
    if (data?.success) return data.data || data.offers || [];
    throw new Error(data?.message || "Failed to fetch offers for my projects");
  } catch (_) {
    return [];
  }
};

/* =====================================================
   GET OFFERS FOR A SPECIFIC PROJECT (CLIENT OWNER)
   returns offers with freelancer stats if available
===================================================== */
export const getOffersForProjectApi = async (projectId, token) => {
  if (!projectId) throw new Error('Missing projectId');
  try {
    const { data } = await API.get(`/offers/project/${projectId}/offers`, authHeaders(token));
    if (data?.success) return data.data || data.offers || [];
    throw new Error(data?.message || 'Failed to fetch offers for project');
  } catch (_) {
    return [];
  }
};

export const checkMyPendingOfferApi = async (projectId, token) => {
  if (!projectId) throw new Error("Missing projectId");

  const { data } = await API.get(
    `/offers/my/${projectId}/pending`,
    authHeaders(token)
  );

  if (data?.success) return data;
  throw new Error(data?.message || "Failed to check pending offer");
};
