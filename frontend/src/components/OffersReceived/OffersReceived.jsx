import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { useToast } from "../toast/ToastProvider";
import API from "../../api/client.js";

const THEME = "#028090";

function getToken(state) {
  const t = state?.auth?.token;
  if (t) return t;
  return null;
}

export default function OffersReceived({ item, offersForProject, setOffersForProject }) {
  const toast = useToast();
  const navigate = useNavigate();
  const token = useSelector(getToken);

  return (
    <div className="mt-8 rounded-2xl border-2 border-teal-100 bg-gradient-to-br from-white to-teal-50/30 p-6 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-xl font-bold text-slate-800">
          Offers Received
          <span className="ml-2 inline-flex items-center justify-center w-8 h-8 text-sm font-bold text-white rounded-full" style={{ backgroundColor: THEME }}> 
            {offersForProject.length}
          </span>
        </h3>
      </div>
      
      {/* 24-Hour Rule Notice */}
      <div className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg">
        <div className="flex items-start">
          <span className="text-amber-500 mr-2">⚠️</span>
          <div className="text-sm">
            <span className="font-semibold text-amber-800">Important:</span>{" "}
            <span className="text-amber-700">
              Clients must accept or reject offers within 24 hours. After this period, offers will automatically expire.
            </span>
          </div>
        </div>
      </div>

      {offersForProject.length === 0 ? (
        <div className="text-center py-8">
          <div className="text-slate-400 text-5xl mb-3">📭</div>
          <p className="text-base font-medium text-slate-600">No offers submitted yet.</p>
          <p className="text-sm text-slate-500 mt-1">Freelancers will submit their proposals here</p>
        </div>
      ) : (
        <ul className="space-y-4">
          {offersForProject.map((o) => {
            // normalized offer object (from getOffersForProjectApi)
            const statusColors = {
              pending: "bg-amber-50 text-amber-700 border-amber-200",
              accepted: "bg-emerald-50 text-emerald-700 border-emerald-200",
              rejected: "bg-red-50 text-red-700 border-red-200",
              expired: "bg-gray-100 text-gray-700 border-gray-300"
            };
            const statusColor = statusColors[o.offer_status] || statusColors.pending;
            const isPending = String(o.offer_status || "").toLowerCase() === "pending";
            
            return (
              <li key={o.offer_id || `${o.freelancer_id}-${o.submitted_at}`} className="p-5 rounded-xl border-2 border-slate-200 bg-white hover:border-teal-300 hover:shadow-md transition-all duration-200">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-teal-400 to-teal-600 flex items-center justify-center text-white font-bold text-lg">
                        {(o.freelancer_name || "F").charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div className="text-base font-bold text-slate-800">{o.freelancer_name || o.username || "Freelancer"}</div>
                        <div className="text-xs text-slate-500">
                          Submitted: {new Date(o.submitted_at).toLocaleString()}
                          {isPending && (
                            <span className="ml-2 text-amber-600">
                              {/* Calculate expiration time (24 hours from submission) */}
                              {(() => {
                                const submitTime = new Date(o.submitted_at);
                                const expireTime = new Date(submitTime.getTime() + 24 * 60 * 60 * 1000);
                                const now = new Date();
                                const hoursLeft = Math.max(0, Math.floor((expireTime - now) / (1000 * 60 * 60)));
                                const minsLeft = Math.max(0, Math.floor((expireTime - now) / (1000 * 60)) % 60);
                                
                                if (hoursLeft > 0) {
                                  return `Expires in ${hoursLeft}h ${minsLeft}m`;
                                } else if (minsLeft > 0) {
                                  return `Expires in ${minsLeft}m`;
                                } else {
                                  return "Expired";
                                }
                              })()}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-teal-600" style={{ color: THEME }}>
                      {o.bid_amount ? `${o.bid_amount} JD` : "—"}
                    </div>
                    <span className={`inline-block mt-1 px-3 py-1 text-xs font-semibold rounded-full border ${statusColor}`}>
                      {(o.offer_status ?? "pending").charAt(0).toUpperCase() + (o.offer_status ?? "pending").slice(1)}
                    </span>
                  </div>
                </div>

                {o.proposal && (
                  <div className="mb-3 p-3 bg-slate-50 rounded-lg border border-slate-200">
                    <div className="text-xs font-semibold text-slate-600 mb-1">Proposal:</div>
                    <p className="text-sm text-slate-700 whitespace-pre-wrap">{o.proposal}</p>
                  </div>
                )}

                <div className="flex flex-wrap gap-4 text-xs text-slate-600 mb-3">
                  <div className="flex items-center gap-1">
                    <span className="text-amber-500">⭐</span>
                    <span>Rating: <span className="font-bold text-slate-800">{o.rating ?? "N/A"}</span></span>
                  </div>
                  <div className="flex items-center gap-1">
                    <span className="text-teal-500">✓</span>
                    <span>Completed: <span className="font-bold text-slate-800">{o.completed_jobs ?? 0}</span></span>
                  </div>
                  <div className="flex items-center gap-1">
                    <span className="text-blue-500">⏱</span>
                    <span>Avg delivery: <span className="font-bold text-slate-800">{o.avg_delivery_days ? `${Number(o.avg_delivery_days).toFixed(1)}d` : "N/A"}</span></span>
                  </div>
                </div>

                {isPending && (
                  <div className="flex items-center gap-2 pt-3 border-t border-slate-200">
                    <button
                      onClick={async () => {
                        if (!token) {
                          toast.error("Please login first.");
                          return;
                        }
                        try {
                          const res = await API.post(
                            "/offers/approve-reject",
                            { offerId: o.offer_id, action: "accept" },
                            { headers: { Authorization: `Bearer ${token}` } }
                          );
                          setOffersForProject((prev) =>
                            prev.map((x) => {
                              if (x.offer_id === o.offer_id) return { ...x, offer_status: "accepted" };
                              if (x.offer_status === "pending") return { ...x, offer_status: "rejected" };
                              return x;
                            })
                          );
                          if (res?.data?.pendingAdminApproval === true) {
                            toast.success("Offer accepted. Choose payment method (CliQ/Cash). Project is pending admin approval.");
                            const projectId = res?.data?.projectId ?? item?.id;
                            if (projectId) navigate(`/projects/success/${projectId}`);
                            return;
                          }
                          toast.success("Offer accepted successfully! Other offers rejected.");
                        } catch (err) {
                          if (err?.response?.data?.message?.includes("expired")) {
                            setOffersForProject((prev) =>
                              prev.map((x) =>
                                x.offer_id === o.offer_id ? { ...x, offer_status: "expired" } : x
                              )
                            );
                          }
                          toast.error(err?.response?.data?.message || "Server error");
                        }
                      }}
                      className="flex-1 h-10 rounded-xl bg-emerald-600 text-white text-sm font-semibold hover:bg-emerald-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Accept Offer
                    </button>
                    <button
                      onClick={async () => {
                        if (!token) {
                          toast.error("Please login first.");
                          return;
                        }
                        try {
                          await API.post(
                            "/offers/approve-reject",
                            { offerId: o.offer_id, action: "reject" },
                            { headers: { Authorization: `Bearer ${token}` } }
                          );
                          setOffersForProject((prev) =>
                            prev.map((x) =>
                              x.offer_id === o.offer_id
                                ? { ...x, offer_status: "rejected" }
                                : x
                            )
                          );
                          toast.success("Offer rejected.");
                        } catch (err) {
                          // Check if the error is due to offer expiration
                          if (err?.response?.data?.message?.includes("expired")) {
                            // Update the offer status to expired in the UI
                            setOffersForProject((prev) =>
                              prev.map((x) =>
                                x.offer_id === o.offer_id
                                  ? { ...x, offer_status: "expired" }
                                  : x
                              )
                            );
                          }
                          toast.error(err?.response?.data?.message || "Failed to reject offer");
                        }
                      }}
                      className="flex-1 h-10 rounded-xl bg-white border-2 border-slate-300 text-slate-700 text-sm font-semibold hover:bg-slate-50 transition disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Reject
                    </button>
                  </div>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}