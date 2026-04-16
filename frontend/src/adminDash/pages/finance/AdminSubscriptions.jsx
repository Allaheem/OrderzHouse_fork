import { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import API from "../../../api/client.js";
import { useToast } from "../../../components/toast/ToastProvider";
import {
  CheckCircle,
  Clock,
  Loader2,
  User,
  Mail,
  Calendar,
  CreditCard,
  X,
  Plus,
  Play,
  XCircle,
  RefreshCw,
} from "lucide-react";

/* ---------- Theme ---------- */
const T = { primary: "#C2410C", dark: "#9A3412", ring: "rgba(15,23,42,.10)" };

const cx = (...a) => a.filter(Boolean).join(" ");

const actionBtnBase =
  "inline-flex items-center justify-center gap-2 h-9 sm:h-10 px-3 sm:px-4 rounded-full text-xs font-semibold whitespace-nowrap " +
  "transition shadow-sm active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-200/70 " +
  "disabled:opacity-60 disabled:pointer-events-none";

const actionBtnVar = {
  primary:
    "text-white bg-gradient-to-b from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 hover:shadow",
  outline:
    "bg-white text-slate-700 border border-slate-200 hover:bg-slate-50",
  success:
    "text-white bg-gradient-to-b from-green-500 to-green-600 hover:from-green-600 hover:to-green-700",
  danger:
    "text-white bg-gradient-to-b from-red-500 to-red-600 hover:from-red-600 hover:to-red-700",
};

function ActionButton({ variant = "outline", className = "", ...props }) {
  return (
    <button
      type="button"
      className={`${actionBtnBase} ${actionBtnVar[variant] ?? actionBtnVar.outline} ${className}`.trim()}
      {...props}
    />
  );
}

function ProjectsHero({ title, subtitle, eyebrow = "ADMIN" }) {
  return (
    <div
      className="relative overflow-hidden rounded-3xl p-4 sm:p-5 lg:p-6 text-white shadow-sm bg-gradient-to-b from-orange-400 to-red-500"
    >
      <div className="absolute -right-20 -top-16 h-56 w-56 rounded-full bg-white/10 blur-2xl" />
      <div className="absolute left-6 -bottom-24 h-56 w-56 rounded-full bg-black/10 blur-2xl" />

      <div className="relative">
        <div className="text-[10px] uppercase tracking-[0.22em] text-white/70 font-semibold">
          {eyebrow}
        </div>
        <h2 className="mt-2 text-[18px] sm:text-[22px] lg:text-[26px] font-extrabold leading-tight text-white">
          {title}
        </h2>
        {subtitle ? (
          <p className="mt-2 text-[12px] sm:text-sm text-white/80 max-w-2xl">
            {subtitle}
          </p>
        ) : null}
      </div>
    </div>
  );
}

export default function AdminSubscriptions() {
  const { token } = useSelector((s) => s.auth);
  const toast = useToast();
  const [freelancers, setFreelancers] = useState([]);
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(null);
  
  // Pagination
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 10;
  
  // Modal states
  const [modalType, setModalType] = useState(null); // 'add' | 'activate' | 'cancel'
  const [selectedFreelancer, setSelectedFreelancer] = useState(null);
  const [selectedPlanId, setSelectedPlanId] = useState("");
  const [startDate, setStartDate] = useState("");
  const [cancelReason, setCancelReason] = useState("");

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [freelancersRes, plansRes] = await Promise.all([
        API.get("/subscriptions/admin/subscriptions/freelancers", {
          headers: { Authorization: `Bearer ${token}` },
        }),
        API.get("/plans", {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      if (freelancersRes.data?.success || freelancersRes.data?.freelancers) {
        setFreelancers(freelancersRes.data.freelancers || []);
      }

      if (plansRes.data?.success || plansRes.data?.plans) {
        const plansData = plansRes.data.plans || plansRes.data || [];
        setPlans(plansData);
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to load data");
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return "—";
    try {
      return new Date(dateString).toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "numeric",
      });
    } catch {
      return "—";
    }
  };

  const formatSubscriptionStatus = (status) => {
    const statusMap = {
      pending_start: "Pending Start",
      active: "Active",
      expired: "Expired",
      cancelled: "Cancelled",
    };
    return statusMap[status] || status || "—";
  };

  const getStatusBadgeClass = (status) => {
    if (!status) return "bg-slate-100 text-slate-800";
    switch (status) {
      case "pending_start":
        return "bg-amber-100 text-amber-800";
      case "active":
        return "bg-green-100 text-green-800";
      case "expired":
        return "bg-red-100 text-red-800";
      case "cancelled":
        return "bg-gray-100 text-gray-800";
      default:
        return "bg-slate-100 text-slate-800";
    }
  };

  const getActionButton = (freelancer) => {
    const subscription = freelancer.subscription;

    if (!subscription) {
      // CASE 1: No subscription
      return (
        <ActionButton
          variant="primary"
          onClick={() => {
            setModalType("add");
            setSelectedFreelancer(freelancer);
            setSelectedPlanId("");
          }}
          disabled={actionLoading !== null}
        >
          <Plus className="w-4 h-4" />
          Add Subscription
        </ActionButton>
      );
    }

    if (subscription.status === "pending_start") {
      // CASE 2: Pending start
      return (
        <ActionButton
          variant="success"
          onClick={() => {
            setModalType("activate");
            setSelectedFreelancer(freelancer);
            setStartDate(new Date().toISOString().split("T")[0]);
          }}
          disabled={actionLoading !== null}
        >
          <Play className="w-4 h-4" />
          Activate Subscription
        </ActionButton>
      );
    }

    if (subscription.status === "active") {
      // CASE 3: Active
      return (
        <ActionButton
          variant="danger"
          onClick={() => {
            setModalType("cancel");
            setSelectedFreelancer(freelancer);
            setCancelReason("");
          }}
          disabled={actionLoading !== null}
        >
          <XCircle className="w-4 h-4" />
          Cancel Subscription
        </ActionButton>
      );
    }

    // CASE 4: Expired/Cancelled
    return (
      <ActionButton
        variant="primary"
        onClick={() => {
          setModalType("add");
          setSelectedFreelancer(freelancer);
          setSelectedPlanId("");
        }}
        disabled={actionLoading !== null}
      >
        <RefreshCw className="w-4 h-4" />
        Add Subscription
      </ActionButton>
    );
  };

  const handleAddSubscription = async () => {
    if (!selectedFreelancer || !selectedPlanId) {
      toast.error("Please select a plan");
      return;
    }

    try {
      setActionLoading("add");
      const { data } = await API.post(
        "/subscriptions/admin/subscriptions/assign",
        {
          freelancer_id: selectedFreelancer.id,
          plan_id: Number(selectedPlanId),
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (data.success) {
        toast.success("Subscription assigned successfully");
        closeModal();
        fetchData();
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to assign subscription");
    } finally {
      setActionLoading(null);
    }
  };

  const handleActivateSubscription = async () => {
    if (!selectedFreelancer || !startDate) {
      toast.error("Please select a start date");
      return;
    }

    try {
      setActionLoading("activate");
      const { data } = await API.post(
        `/subscriptions/admin/subscriptions/${selectedFreelancer.subscription.id}/activate`,
        { start_date: startDate },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (data.success) {
        toast.success("Subscription activated successfully");
        closeModal();
        fetchData();
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to activate subscription");
    } finally {
      setActionLoading(null);
    }
  };

  const handleCancelSubscription = async () => {
    if (!selectedFreelancer) {
      return;
    }

    try {
      setActionLoading("cancel");
      const { data } = await API.post(
        `/subscriptions/admin/subscriptions/${selectedFreelancer.subscription.id}/cancel`,
        { reason: cancelReason || null },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (data.success) {
        toast.success("Subscription cancelled successfully");
        closeModal();
        fetchData();
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to cancel subscription");
    } finally {
      setActionLoading(null);
    }
  };

  const closeModal = () => {
    setModalType(null);
    setSelectedFreelancer(null);
    setSelectedPlanId("");
    setStartDate("");
    setCancelReason("");
  };

  // Pagination calculations
  const totalPages = Math.ceil(freelancers.length / PAGE_SIZE);
  const startIndex = (page - 1) * PAGE_SIZE;
  const endIndex = startIndex + PAGE_SIZE;
  const pageItems = freelancers.slice(startIndex, endIndex);
  const showingStart = freelancers.length > 0 ? startIndex + 1 : 0;
  const showingEnd = Math.min(endIndex, freelancers.length);

  // Reset to page 1 when data changes
  useEffect(() => {
    if (freelancers.length > 0 && page > totalPages) {
      setPage(1);
    }
  }, [freelancers.length, totalPages, page]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <>
      <div className="space-y-5">
        <ProjectsHero
          eyebrow="ADMIN"
          title="Subscriptions"
          subtitle="Manage client and freelancer subscriptions: assign, activate, cancel. Apple IAP rows show payment source."
        />

        {/* Table */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    #
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    User
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Role
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Email
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Current Plan
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Payment
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Start Date
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    End Date
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {pageItems.length === 0 ? (
                  <tr>
                    <td colSpan="10" className="px-4 py-8 text-center text-slate-500">
                      No clients or freelancers found
                    </td>
                  </tr>
                ) : (
                  pageItems.map((freelancer, index) => {
                    const subscription = freelancer.subscription;
                    // Row number continues across pages
                    const rowNumber = startIndex + index + 1;
                    return (
                      <tr key={freelancer.id} className="hover:bg-slate-50">
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {rowNumber}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center shrink-0">
                              <User className="w-4 h-4 text-slate-400" />
                            </div>
                            <span className="text-sm font-medium text-slate-900">
                              {freelancer.first_name} {freelancer.last_name}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {Number(freelancer.role_id) === 2
                            ? "Client"
                            : Number(freelancer.role_id) === 3
                            ? "Freelancer"
                            : "—"}
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {freelancer.email}
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {subscription?.plan_name || "No subscription"}
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-600 capitalize">
                          {subscription?.payment_source
                            ? String(subscription.payment_source).replace(/_/g, " ")
                            : "—"}
                          {subscription?.apple_original_transaction_id ? (
                            <span className="block text-[10px] text-slate-400 font-mono truncate max-w-[140px]">
                              {subscription.apple_original_transaction_id}
                            </span>
                          ) : null}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${getStatusBadgeClass(
                              subscription?.status
                            )}`}
                          >
                            {formatSubscriptionStatus(subscription?.status)}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {formatDate(subscription?.start_date)}
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {formatDate(subscription?.end_date)}
                        </td>
                        <td className="px-4 py-3">
                          {getActionButton(freelancer)}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
          
          {/* Pagination */}
          {freelancers.length > 0 && (
            <div className="px-4 py-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
              <div className="text-sm text-slate-600">
                Showing <span className="font-medium">{showingStart}</span>–
                <span className="font-medium">{showingEnd}</span> of{" "}
                <span className="font-medium">{freelancers.length}</span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition"
                >
                  Previous
                </button>
                <div className="flex items-center gap-1">
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map((pageNum) => (
                    <button
                      key={pageNum}
                      onClick={() => setPage(pageNum)}
                      className={`px-3 py-1.5 text-sm font-medium rounded-lg transition ${
                        page === pageNum
                          ? "bg-orange-500 text-white"
                          : "text-slate-700 bg-white border border-slate-300 hover:bg-slate-50"
                      }`}
                    >
                      {pageNum}
                    </button>
                  ))}
                </div>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Modals */}
      {modalType && selectedFreelancer && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div
            className="bg-white rounded-xl shadow-xl max-w-md w-full p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold text-slate-900">
                  {modalType === "add" && "Add Subscription"}
                  {modalType === "activate" && "Activate Subscription"}
                  {modalType === "cancel" && "Cancel Subscription"}
                </h3>
                <p className="text-sm text-slate-600 mt-1">
                  {selectedFreelancer.first_name} {selectedFreelancer.last_name}
                </p>
                <p className="text-xs text-slate-500">{selectedFreelancer.email}</p>
              </div>
              <button
                onClick={closeModal}
                className="w-8 h-8 grid place-items-center rounded-full hover:bg-slate-100 text-slate-600 shrink-0"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              {/* Add Subscription Modal */}
              {modalType === "add" && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      Select Plan
                    </label>
                    <select
                      value={selectedPlanId}
                      onChange={(e) => setSelectedPlanId(e.target.value)}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200/70"
                    >
                      <option value="">Choose a plan...</option>
                      {plans.map((plan) => (
                        <option key={plan.id} value={plan.id}>
                          {plan.name}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="bg-amber-50 border border-amber-200 rounded-lg p-3">
                    <p className="text-xs text-amber-800">
                      <strong>Note:</strong> Subscription will be set to "Pending Start" status.
                      The start date will be automatically set when the freelancer starts their
                      first project.
                    </p>
                  </div>
                </>
              )}

              {/* Activate Subscription Modal */}
              {modalType === "activate" && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      Plan (Read-only)
                    </label>
                    <input
                      type="text"
                      value={selectedFreelancer.subscription?.plan_name || "—"}
                      disabled
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg bg-slate-50 text-slate-600"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      Start Date
                    </label>
                    <input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200/70"
                    />
                  </div>
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                    <p className="text-xs text-blue-800">
                      <strong>Note:</strong> End date will be calculated automatically based on
                      the plan duration.
                    </p>
                  </div>
                </>
              )}

              {/* Cancel Subscription Modal */}
              {modalType === "cancel" && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      Reason (Optional)
                    </label>
                    <textarea
                      value={cancelReason}
                      onChange={(e) => setCancelReason(e.target.value)}
                      rows={3}
                      placeholder="Enter cancellation reason..."
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200/70"
                    />
                  </div>
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                    <p className="text-xs text-red-800">
                      <strong>Warning:</strong> This will cancel the subscription. The freelancer
                      will no longer have access to premium features.
                    </p>
                  </div>
                </>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  onClick={closeModal}
                  className="flex-1 h-10 px-4 rounded-lg text-sm font-semibold bg-slate-100 text-slate-700 hover:bg-slate-200 transition"
                  disabled={actionLoading !== null}
                >
                  Cancel
                </button>
                <ActionButton
                  variant={
                    modalType === "add" || modalType === "activate"
                      ? "primary"
                      : "danger"
                  }
                  onClick={
                    modalType === "add"
                      ? handleAddSubscription
                      : modalType === "activate"
                      ? handleActivateSubscription
                      : handleCancelSubscription
                  }
                  disabled={
                    actionLoading !== null ||
                    (modalType === "add" && !selectedPlanId) ||
                    (modalType === "activate" && !startDate)
                  }
                  className="flex-1"
                >
                  {actionLoading !== null ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : modalType === "add" ? (
                    <>
                      <CheckCircle className="w-4 h-4" />
                      Assign
                    </>
                  ) : modalType === "activate" ? (
                    <>
                      <Play className="w-4 h-4" />
                      Activate
                    </>
                  ) : (
                    <>
                      <XCircle className="w-4 h-4" />
                      Cancel Subscription
                    </>
                  )}
                </ActionButton>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
