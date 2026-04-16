import { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import API from "../../../../api/client.js";
import { useToast } from "../../../../components/toast/ToastProvider";
import {
  Check,
  X,
  Clock,
  Loader2,
  Eye,
  DollarSign,
  Calendar,
  User,
  FileText,
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

export default function AdminPendingBiddingApprovals() {
  const { token } = useSelector((s) => s.auth);
  const toast = useToast();
  const [approvals, setApprovals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [approvingId, setApprovingId] = useState(null);
  const [rejectingId, setRejectingId] = useState(null);
  const [showRejectReason, setShowRejectReason] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [selectedProjectId, setSelectedProjectId] = useState(null);

  useEffect(() => {
    fetchPendingApprovals();
  }, []);

  const fetchPendingApprovals = async () => {
    try {
      setLoading(true);
      const { data } = await API.get("/offers/admin/pending-bidding-approvals", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (data.success) {
        setApprovals(data.approvals || []);
      }
    } catch (err) {
      const res = err?.response?.data;
      const message = res?.error || res?.message || "Failed to load pending approvals";
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (projectId) => {
    if (!token) return;
    setApprovingId(projectId);
    try {
      const { data } = await API.post(
        `/offers/admin/projects/${projectId}/approve-bidding-offer`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (data.success) {
        toast.success(data.message || "Bidding project approved successfully");
        fetchPendingApprovals();
      }
    } catch (err) {
      toast.error(err?.response?.data?.message || "Failed to approve project");
    } finally {
      setApprovingId(null);
    }
  };

  const handleReject = async (projectId, reason = "") => {
    if (!token) return;
    setRejectingId(projectId);
    try {
      const { data } = await API.post(
        `/offers/admin/projects/${projectId}/reject-bidding-offer`,
        { reason },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (data.success) {
        toast.success(data.message || "Bidding project offer rejected");
        fetchPendingApprovals();
        setShowRejectReason(false);
        setRejectReason("");
        setSelectedProjectId(null);
      }
    } catch (err) {
      toast.error(err?.response?.data?.message || "Failed to reject project");
    } finally {
      setRejectingId(null);
    }
  };

  const formatJD = (value) => {
    if (value == null || value === undefined || value === "") return "—";
    const num = Number(value);
    if (isNaN(num)) return "—";
    const formatted = num.toFixed(2);
    const cleaned = formatted.replace(/\.?0+$/, "");
    return `${cleaned} JD`;
  };

  const formatDate = (dateString) => {
    if (!dateString) return "—";
    try {
      return new Date(dateString).toLocaleDateString();
    } catch {
      return dateString;
    }
  };

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="space-y-5">
          <ProjectsHero
            eyebrow="ADMIN"
            title="Pending Bidding Approvals"
            subtitle="Review and approve bidding projects with accepted offers"
          />
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-orange-600" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div className="space-y-5">
        <ProjectsHero
          eyebrow="ADMIN"
          title="Pending Bidding Approvals"
          subtitle="Review and approve bidding projects with accepted offers. Projects will start after approval."
        />

        {approvals.length === 0 ? (
          <div className="rounded-2xl border border-slate-200 bg-white p-12 text-center">
            <Clock className="w-12 h-12 mx-auto text-slate-400 mb-4" />
            <p className="text-slate-600 font-medium">No pending bidding approvals</p>
            <p className="text-sm text-slate-500 mt-2">
              All bidding projects with accepted offers have been processed.
            </p>
          </div>
        ) : (
          <div className="grid gap-4">
            {approvals.map((approval) => (
              <div
                key={approval.project_id}
                className="rounded-2xl border border-slate-200 bg-white p-5 sm:p-6 shadow-sm hover:shadow-md transition"
              >
                <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start gap-3 mb-3">
                      <div className="flex-1 min-w-0">
                        <h3 className="text-lg font-bold text-slate-900 mb-1 truncate">
                          {approval.project_title}
                        </h3>
                        <div className="flex flex-wrap items-center gap-3 text-sm text-slate-600">
                          <span className="inline-flex items-center gap-1">
                            <FileText className="w-4 h-4" />
                            Project ID: #{approval.project_id}
                          </span>
                          <span className="inline-flex items-center gap-1">
                            <Calendar className="w-4 h-4" />
                            {formatDate(approval.offer_created_at || approval.project_created_at)}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="grid sm:grid-cols-2 gap-4 mt-4">
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-sm">
                          <User className="w-4 h-4 text-slate-400" />
                          <span className="text-slate-600">Client:</span>
                          <span className="font-semibold text-slate-900">
                            {approval.client_name || `ID: ${approval.client_id}`}
                          </span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <User className="w-4 h-4 text-slate-400" />
                          <span className="text-slate-600">Freelancer:</span>
                          <span className="font-semibold text-slate-900">
                            {approval.freelancer_name || `ID: ${approval.freelancer_id}`}
                          </span>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-sm">
                          <DollarSign className="w-4 h-4 text-slate-400" />
                          <span className="text-slate-600">Accepted Offer:</span>
                          <span className="font-bold text-orange-600">
                            {formatJD(approval.bid_amount)}
                          </span>
                        </div>
                        <div className="flex items-center gap-2 text-sm">
                          <FileText className="w-4 h-4 text-slate-400" />
                          <span className="text-slate-600">Offer ID:</span>
                          <span className="font-semibold text-slate-900">#{approval.offer_id}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-col sm:flex-row gap-2 sm:items-start">
                    <ActionButton
                      variant="success"
                      onClick={() => handleApprove(approval.project_id)}
                      disabled={approvingId === approval.project_id || rejectingId === approval.project_id}
                    >
                      {approvingId === approval.project_id ? (
                        <>
                          <Loader2 className="w-4 h-4 animate-spin" />
                          Approving...
                        </>
                      ) : (
                        <>
                          <Check className="w-4 h-4" />
                          Approve
                        </>
                      )}
                    </ActionButton>
                    <ActionButton
                      variant="danger"
                      onClick={() => {
                        setSelectedProjectId(approval.project_id);
                        setShowRejectReason(true);
                      }}
                      disabled={approvingId === approval.project_id || rejectingId === approval.project_id}
                    >
                      <X className="w-4 h-4" />
                      Reject
                    </ActionButton>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Reject Reason Modal */}
      {showRejectReason && selectedProjectId && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl max-w-md w-full p-6">
            <h3 className="text-lg font-bold text-slate-900 mb-4">Reject Bidding Project Offer</h3>
            <p className="text-sm text-slate-600 mb-4">
              This will revert the project to bidding status and unassign the freelancer. The client can accept another offer.
            </p>
            <div className="mb-4">
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Reason (optional)
              </label>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-orange-200"
                rows={3}
                placeholder="Enter rejection reason..."
              />
            </div>
            <div className="flex gap-3 justify-end">
              <ActionButton
                variant="outline"
                onClick={() => {
                  setShowRejectReason(false);
                  setRejectReason("");
                  setSelectedProjectId(null);
                }}
              >
                Cancel
              </ActionButton>
              <ActionButton
                variant="danger"
                onClick={() => handleReject(selectedProjectId, rejectReason)}
                disabled={rejectingId === selectedProjectId}
              >
                {rejectingId === selectedProjectId ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Rejecting...
                  </>
                ) : (
                  <>
                    <X className="w-4 h-4" />
                    Reject
                  </>
                )}
              </ActionButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
