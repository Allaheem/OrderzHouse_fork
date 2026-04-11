import { useParams, useLocation, useNavigate } from "react-router-dom";
import { useEffect, useMemo, useState } from "react";
import {
  ArrowLeft,
  X,
  Wallet,
  Clock,
  Tag,
  FolderOpen,
  Paperclip,
  MessageSquareText,
  SendHorizontal,
  ClipboardList,
  User,
  TrendingUp,
  Calendar,
  Bell,
  CheckCircle,
  FileText,
  Eye,
} from "lucide-react";

import API from "../../../api/axios.js";
import {
  getProjectByIdApi,
  getProjectFilesApi,
  applyToProjectApi,
  checkIfAssignedApi,
} from "../../../../components/Catigories/api/projects";
import { sendOfferApi, getOffersForProjectApi } from "../../../../components/Catigories/api/offers";

import { useSelector } from "react-redux";
import { useToast } from "../../../../components/toast/ToastProvider";
import AttachmentList from "../../../../components/Attachments/AttachmentList";
import {
  ClientReviewDrawer,
  ClientApplicationsDrawer,
  ClientOffersDrawer,
  DeliverModal,
} from "./AdminProjects";



const THEME = "#F97316";
const THEME_DARK = "#C2410C";

const cx = (...a) => a.filter(Boolean).join(" ");

function formatDateSafe(value) {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return String(value);
  return d.toLocaleDateString();
}

function valueOrDash(v) {
  if (v === null || v === undefined || v === "") return "—";
  return v;
}

function StatusChip({ status }) {
  const s = String(status || "").toLowerCase();
  const tone =
    s.includes("completed") || s.includes("done") || s.includes("finished")
      ? "bg-emerald-50 border-emerald-200/70 text-emerald-700"
      : s.includes("pending") || s.includes("await")
      ? "bg-amber-50 border-amber-200/70 text-amber-700"
      : s.includes("bidding")
      ? "bg-orange-50 border-orange-200/70 text-orange-700"
      : "bg-slate-50 border-slate-200/70 text-slate-700";

  return (
    <span
      className={cx(
        "inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold",
        tone
      )}
    >
      <span className={cx("h-1.5 w-1.5 rounded-full", s ? "" : "opacity-40")} style={{ backgroundColor: THEME }} />
      {status ? String(status) : "—"}
    </span>
  );
}

function StatPill({ icon: Icon, label, value, tone = "slate" }) {
  const toneCls =
    tone === "violet"
      ? "bg-orange-50 border-orange-200/70 text-orange-700"
      : tone === "emerald"
      ? "bg-emerald-50 border-emerald-200/70 text-emerald-700"
      : tone === "amber"
      ? "bg-amber-50 border-amber-200/70 text-amber-700"
      : tone === "orange"
      ? "bg-orange-50 border-orange-200/70 text-orange-700"
      : "bg-slate-50 border-slate-200/70 text-slate-700";

  return (
    <div className={cx("rounded-2xl border px-3 py-3 bg-white", toneCls)}>
      <div className="flex items-center gap-3 min-w-0">
        <div
          className={cx(
            "h-9 w-9 rounded-2xl grid place-items-center border bg-white/60 shrink-0",
            toneCls
          )}
        >
          <Icon className="h-4 w-4" />
        </div>
        <div className="min-w-0">
          <div className="text-[11px] font-semibold opacity-80 truncate">
            {label}
          </div>
          <div className="text-sm font-extrabold text-slate-900 truncate">
            {value}
          </div>
        </div>
      </div>
    </div>
  );
}

function SectionCard({ title, icon: Icon, children, right }) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white shadow-sm overflow-hidden">
      <div className="px-4 sm:px-5 py-4 border-b border-slate-200/70 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2 min-w-0">
          {Icon ? (
            <span className="h-9 w-9 rounded-2xl border border-slate-200 bg-slate-50 grid place-items-center shrink-0">
              <Icon className="h-4 w-4 text-slate-700" />
            </span>
          ) : null}
          <h3 className="font-extrabold text-slate-900 truncate">{title}</h3>
        </div>
        {right ? <div className="shrink-0">{right}</div> : null}
      </div>
      <div className="p-4 sm:p-5">{children}</div>
    </div>
  );
}

function MobileBottomBar({ hidden, acceptLabel, onAccept, onContact, acceptDisabled }) {
  if (hidden) return null;
  return (
    <div className="lg:hidden fixed inset-x-0 bottom-0 z-40 border-t border-slate-200 bg-white/85 backdrop-blur">
      <div className="px-4 pt-3 pb-[calc(env(safe-area-inset-bottom)+12px)]">
        <div className="flex gap-3">
          <button
            onClick={onAccept}
            disabled={acceptDisabled}
            className={
              "flex-1 h-12 rounded-2xl text-white font-semibold transition " +
              (acceptDisabled ? "opacity-40 grayscale cursor-not-allowed" : "active:scale-[0.99]")
            }
            style={{ backgroundColor: THEME }}
          >
            {acceptLabel}
          </button>

          {onContact && (
            <button
              onClick={onContact}
              className="flex-1 h-12 rounded-2xl border border-slate-300 bg-white text-slate-800 font-semibold transition active:scale-[0.99]"
            >
              Contact
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

/* ---------- Redesign: small UI blocks ---------- */
function MetaPill({ icon: Icon, children, className = "" }) {
  return (
    <span
      className={cx(
        "inline-flex items-center gap-1.5 rounded-full border border-slate-200/80 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 shadow-sm",
        className
      )}
    >
      {Icon ? <Icon className="h-3.5 w-3.5 text-slate-500 shrink-0" /> : null}
      {children}
    </span>
  );
}

function ProjectTabs({ tabs, active, onChange }) {
  return (
    <div className="flex flex-wrap gap-1 border-b border-slate-200/80">
      {tabs.map(({ id, label }) => {
        const isActive = active === id;
        return (
          <button
            key={id}
            type="button"
            onClick={() => onChange(id)}
            className={cx(
              "px-4 py-3 text-sm font-medium transition",
              isActive
                ? "text-orange-600 border-b-2 border-orange-500 -mb-px"
                : "text-slate-500 hover:text-slate-700"
            )}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}

function SectionBlock({ title, children }) {
  return (
    <div className="mb-6 last:mb-0">
      <h3 className="text-sm font-bold text-slate-900 mb-2">{title}</h3>
      <div className="text-sm text-slate-600 leading-relaxed">{children}</div>
    </div>
  );
}

function ActionPill({ primary, icon: Icon, children, onClick, disabled, className = "" }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={cx(
        "inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition shrink-0",
        "focus:outline-none focus-visible:ring-2 focus-visible:ring-orange-300",
        primary
          ? "text-white shadow-sm hover:opacity-95 active:scale-[0.98]"
          : "bg-white border border-slate-200/80 text-slate-700 hover:bg-slate-50",
        disabled && "opacity-50 cursor-not-allowed",
        className
      )}
      style={primary ? { backgroundColor: THEME } : undefined}
    >
      {Icon ? <Icon className="h-4 w-4 shrink-0" /> : null}
      {children}
    </button>
  );
}

/**
 * Dashboard-themed Project Details (same endpoints/logic as old ProjectDetails).
 * Works for:
 * - Marketplace view (freelancer -> Apply / Send offer)
 * - Read-only view from "My Projects" cards (client/freelancer)
 */
export default function ProjectDetailsDashboard({ mode: propMode }) {
  // NOTE: keep compatible with different route param names (id / projectId)
  const params = useParams();
  const id = params?.id ?? params?.projectId;
  const location = useLocation();
  const navigate = useNavigate();
  const toast = useToast();

  const [item, setItem] = useState(null);
  const [projectFiles, setProjectFiles] = useState([]);
  const [showApplyModal, setShowApplyModal] = useState(false);
  const [applyModalType, setApplyModalType] = useState("apply");
  const [offerAmount, setOfferAmount] = useState("");
  const [hasApplied, setHasApplied] = useState(false);
  const [busy, setBusy] = useState(false);
  const [offersForProject, setOffersForProject] = useState([]);
  const [descExpanded, setDescExpanded] = useState(false);

  // Actions (كابينة + فريلانسر) — نفس أزرار الكاردات
  const [deliverOpen, setDeliverOpen] = useState(false);
  const [deliverSubmitting, setDeliverSubmitting] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [notifItems, setNotifItems] = useState([]);
  const [notifLoading, setNotifLoading] = useState(false);
  const [approveSubmitting, setApproveSubmitting] = useState(false);
  // Client: لوحة واحدة للمراجعة/الاستلام/طلب التعديلات (نفس AdminProjects)
  const [reviewDrawerOpen, setReviewDrawerOpen] = useState(false);
  const [reviewDrawerMode, setReviewDrawerMode] = useState("review"); // "review" | "files" | "request"
  const [offersModalOpen, setOffersModalOpen] = useState(false);
  const [applicationsModalOpen, setApplicationsModalOpen] = useState(false);
  const [applicationsList, setApplicationsList] = useState([]);
  const [applicationsLoading, setApplicationsLoading] = useState(false);
  const [offersSubmitting, setOffersSubmitting] = useState(false);
  const [appsSubmitting, setAppsSubmitting] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");

  // ✅ inferred mode (projects/tasks) — keep compatible with old file
  const inferredMode = useMemo(() => {
    return location.pathname.startsWith("/tasks") ? "tasks" : "projects";
  }, [location.pathname]);
  const mode = propMode || inferredMode;

  const readOnly = !!location.state?.readOnly;
  const roleLabel = location.state?.role || "guest";

  const { userData } = useSelector((s) => s?.auth || {}) || {};
  const roleIdFromRedux =
    userData?.role_id ?? userData?.roleId ?? userData?.role ?? null;

  const roleId =
    (typeof roleIdFromRedux === "number" ? roleIdFromRedux : null) ??
    (typeof window !== "undefined" &&
    /^\d+$/.test(localStorage.getItem("role") || "")
      ? Number(localStorage.getItem("role"))
      : null);

  const isClient = roleId === 2;
  const isFreelancer = roleId === 3;

  const currentUserId =
    userData?.id ??
    userData?.user_id ??
    userData?.userId ??
    Number(localStorage.getItem("userId"));

  // =============================== Fetch Project
  useEffect(() => {
    if (!id) return;
    const stateObj = location.state?.project;
    if (stateObj && String(stateObj.id) === String(id)) {
      setItem(stateObj);
      return;
    }

    getProjectByIdApi(id)
      .then((res) => setItem(res?.task || res?.project || res))
      .catch(() => toast.error("Failed to load details."));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  // =============================== Files
  useEffect(() => {
    if (!id || mode !== "projects") return;
    getProjectFilesApi(id)
      .then((files) => setProjectFiles(files))
      .catch(() => toast.error("Failed to load project files."));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, mode]);

  // =============================== Applied/Assigned (freelancer)
  useEffect(() => {
    if (!isFreelancer || mode !== "projects" || !id) return;
    (async () => {
      try {
        const isAssigned = await checkIfAssignedApi(id);
        if (isAssigned) setHasApplied(true);
      } catch (e) {
        console.error(e);
      }
    })();
  }, [id, isFreelancer, mode]);

  // =============================== Offers (client owner only)
  useEffect(() => {
    if (!item || !isClient || !currentUserId) return;
    if (
      String(item.user_id ?? item.userId ?? item.client_id ?? "") !==
      String(currentUserId)
    )
      return;

    let cancelled = false;

    (async () => {
      const token = localStorage.getItem("token");
      if (!token) return;

      try {
        const offers = await getOffersForProjectApi(item.id, token);
        if (cancelled) return;

        const normalized = (offers || []).map((o) => ({
          offer_id: o.offer_id ?? o.id,
          freelancer_id: o.freelancer_id,
          freelancer_name:
            (o.first_name || "") + (o.last_name ? ` ${o.last_name}` : "") ||
            o.freelancer_name ||
            o.username ||
            "Freelancer",
          bid_amount: o.bid_amount ?? o.bid_amount,
          proposal: o.proposal || "",
          offer_status: o.offer_status ?? o.status,
          submitted_at: o.submitted_at || o.created_at,
          rating: o.rating ?? null,
          completed_jobs: o.completed_jobs ?? o.completed_count ?? 0,
          avg_delivery_days: o.avg_delivery_days ?? o.avg_delivery_time ?? null,
        }));

        setOffersForProject(normalized);
      } catch (err) {
        console.error("Failed to load offers for project", err);
        try {
          toast.error(
            (err && err.message) || "Failed to load offers for this project."
          );
        } catch {}
      }
    })();

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [item, isClient, currentUserId]);

  // =============================== Guard
  // إذا كان الرابط لا يحتوي على id صحيح
  if (!id) {
    return (
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="rounded-3xl border border-slate-200 bg-white p-5 sm:p-6">
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0">
              <div className="text-sm font-semibold text-slate-900">Invalid project link</div>
              <div className="text-sm text-slate-500 mt-1">The project id is missing from the URL.</div>
            </div>
            <button
              type="button"
              onClick={() => navigate(-1)}
              className="h-10 rounded-2xl border border-slate-200 bg-white px-4 text-sm font-semibold hover:bg-slate-50"
            >
              Go back
            </button>
          </div>
        </div>
      </section>
    );
  }

  const onApplyToProject = () => {
    if (readOnly) return;
    if (!isFreelancer)
      return toast.error("Only freelancers can apply to projects.");
    if (hasApplied)
      return toast.error("You already applied or are assigned to this project.");
    setApplyModalType(item?.project_type === "bidding" ? "offer" : "apply");
    setShowApplyModal(true);
  };

  const handleConfirmApply = async () => {
    const token = localStorage.getItem("token");
    if (!token) {
      toast.error("Please login first.");
      setShowApplyModal(false);
      return;
    }
    if (busy) return;

    setShowApplyModal(false);
    try {
      setBusy(true);

      let response;
      if (applyModalType === "offer") {
        if (!offerAmount) {
          toast.error("Please enter an offer amount.");
          return;
        }
        response = await sendOfferApi(
          id,
          {
            offer_amount: offerAmount,
            message: "",
            delivery_time: 0,
            cover_letter: "",
          },
          token
        );
      } else {
        response = await applyToProjectApi(id, { proposal: "" }, token);
      }

      toast.success(response?.message || "Application sent successfully!");
      setHasApplied(true);
      setOfferAmount("");
    } catch (err) {
      console.error(err);
      toast.error(err?.message || "Failed to apply to project.");
    } finally {
      setBusy(false);
    }
  };

  // =============================== Skeleton
  if (!item) {
    return (
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="h-12 rounded-3xl bg-slate-200 animate-pulse mb-4" />
        <div className="grid lg:grid-cols-[1fr,360px] gap-6">
          <div className="space-y-4">
            <div className="h-[220px] rounded-3xl bg-slate-200 animate-pulse" />
            <div className="grid sm:grid-cols-2 gap-3">
              <div className="h-14 rounded-2xl bg-slate-200 animate-pulse" />
              <div className="h-14 rounded-2xl bg-slate-200 animate-pulse" />
              <div className="h-14 rounded-2xl bg-slate-200 animate-pulse sm:col-span-2" />
            </div>
            <div className="h-40 rounded-3xl bg-slate-200 animate-pulse" />
          </div>
          <div className="h-[420px] rounded-3xl bg-slate-200 animate-pulse" />
        </div>
      </section>
    );
  }

  // =============================== Normalized fields
  const title = item.title || "Project";
  const cover = item.cover_pic || item.cover;

  const budget = item?.budget ?? item?.price ?? item?.amount ?? null;
  const projectType = item?.project_type ?? item?.type ?? "—";
  const duration = item?.duration ?? item?.delivery_time ?? item?.days ?? null;
  const category =
    item?.category ?? item?.category_name ?? item?.categoryTitle ?? null;
  const createdAt = item?.created_at ?? item?.createdAt ?? item?.created ?? null;
  const status = item?.completion_status ?? item?.status ?? "—";


  const due = item?.due ?? item?.due_date ?? item?.deadline ?? null;
  const progress = item?.progress ?? item?.progress_percent ?? item?.progress_percentage ?? null;
  const clientName =
    item?.client_name ??
    item?.client ??
    item?.owner ??
    item?.user_name ??
    item?.username ??
    null;
  const freelancerName =
    item?.freelancer_name ??
    item?.assignee ??
    item?.assigned_to ??
    item?.assignedFreelancer ??
    null;
  const offersCount =
    item?.offers_count ??
    item?.offers ??
    item?.offersTotal ??
    null;
  const description = item.description || "No description provided.";
  const shortDesc =
    description.length > 260 ? description.slice(0, 260) + "…" : description;

  // accept label / state (same logic)
  const acceptLabel = isFreelancer
    ? hasApplied
      ? "Already Applied"
      : String(projectType || "").toLowerCase() === "bidding"
      ? "Send Offer"
      : "Apply"
    : "Apply";

  const acceptDisabled =
    readOnly || busy || !isFreelancer || (isFreelancer && hasApplied);

  const isOwnerClient =
    isClient &&
    String(item.user_id ?? item.userId ?? item.client_id ?? "") ===
      String(currentUserId);

  const completionKey = String(status || "").toLowerCase();
  const isCompleted = /completed|done|finished/.test(completionKey);
  const isWaitingForClient = /pending_review|awaiting_client|waiting_client/.test(completionKey);

  const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
  const authHeaders = token ? { headers: { Authorization: `Bearer ${token}` } } : {};

  const openDeliverModal = () => setDeliverOpen(true);
  const openNotifPanel = async () => {
    setNotifOpen(true);
    setNotifLoading(true);
    try {
      const { data } = await API.get(`/projects/${id}/change-requests`, authHeaders);
      setNotifItems(data?.requests || data?.items || []);
      await API.put(`/projects/${id}/change-requests/mark-read`, {}, authHeaders).catch(() => {});
    } catch (e) {
      console.error(e);
      setNotifItems([]);
    } finally {
      setNotifLoading(false);
    }
  };
  const submitDeliverPayload = async (payload) => {
    if (!id || !(payload?.files?.length)) {
      toast.error("Please add at least one file.");
      return;
    }
    setDeliverSubmitting(true);
    try {
      const fd = new FormData();
      (payload.files || []).forEach((f) => fd.append("project_files", f));
      await API.post(`/projects/${id}/deliver`, fd, authHeaders);
      toast.success("Delivery submitted.");
      setDeliverOpen(false);
      getProjectByIdApi(id).then((res) => setItem(res?.task || res?.project || res));
    } catch (err) {
      toast.error(err?.response?.data?.message || "Delivery failed.");
    } finally {
      setDeliverSubmitting(false);
    }
  };
  const openReviewDrawer = (mode) => {
    setReviewDrawerMode(mode);
    setReviewDrawerOpen(true);
  };
  const approveWork = async () => {
    setApproveSubmitting(true);
    try {
      await API.put(`/projects/${id}/approve`, { action: "approve" }, authHeaders);
      toast.success("Work approved.");
      getProjectByIdApi(id).then((res) => setItem(res?.task || res?.project || res));
    } catch (err) {
      toast.error(err?.response?.data?.message || "Approve failed.");
    } finally {
      setApproveSubmitting(false);
    }
  };

  const isBidding = String(projectType || "").toLowerCase() === "bidding";
  const openApplicationsModal = async () => {
    setApplicationsModalOpen(true);
    setApplicationsLoading(true);
    try {
      const { data } = await API.get(`/projects/project/${id}/applications`, authHeaders);
      const list = Array.isArray(data?.applications) ? data.applications : Array.isArray(data?.data) ? data.data : Array.isArray(data) ? data : [];
      setApplicationsList(list);
    } catch (e) {
      console.error(e);
      setApplicationsList([]);
    } finally {
      setApplicationsLoading(false);
    }
  };
  const openOffersModal = () => setOffersModalOpen(true);

  const handleOfferAction = async (offerId, projectId, action) => {
    if (!token) return;
    setOffersSubmitting(true);
    try {
      const res = await API.post("/offers/approve-reject", { offerId, action }, { headers: { Authorization: `Bearer ${token}` }, timeout: 15000 });
      if (action === "accept" && res?.data?.requiresPayment === true) {
        const payRes = await API.post("/stripe/offer-accept-checkout", { offerId }, { headers: { Authorization: `Bearer ${token}` }, timeout: 15000 });
        if (payRes?.data?.url) {
          window.location.href = payRes.data.url;
          return;
        }
      }
      setOffersForProject((prev) => {
        if (action === "accept") {
          return prev.map((o) => {
            const oid = o.offer_id ?? o.id;
            if (String(oid) === String(offerId)) return { ...o, offer_status: "accepted" };
            if (String(o.offer_status || "").toLowerCase() === "pending") return { ...o, offer_status: "rejected" };
            return o;
          });
        }
        return prev.map((o) => {
          const oid = o.offer_id ?? o.id;
          if (String(oid) === String(offerId)) return { ...o, offer_status: "rejected" };
          return o;
        });
      });
      toast.success(action === "accept" ? "Offer accepted." : "Offer rejected.");
    } catch (err) {
      toast.error(err?.response?.data?.message || "Action failed.");
    } finally {
      setOffersSubmitting(false);
    }
  };

  const handleApplicationAction = async (assignmentId, projectId, action) => {
    if (!token) return;
    setAppsSubmitting(true);
    try {
      await API.post("/projects/applications/decision", { assignmentId, id: assignmentId, projectId, action }, { headers: { Authorization: `Bearer ${token}` }, timeout: 15000 });
      setApplicationsList((prev) => {
        if (action === "accept") {
          return prev.map((app) => {
            const key = app.assignment_id ?? app.id;
            if (key === assignmentId) return { ...app, status: "active" };
            if (String(app.status || "").toLowerCase() === "pending_client_approval") return { ...app, status: "not_chosen" };
            return app;
          });
        }
        return prev.map((app) => {
          const key = app.assignment_id ?? app.id;
          if (key === assignmentId) return { ...app, status: "rejected" };
          return app;
        });
      });
      toast.success(action === "accept" ? "Application accepted." : "Application rejected.");
    } catch (err) {
      toast.error(err?.response?.data?.message || "Action failed.");
    } finally {
      setAppsSubmitting(false);
    }
  };

  return (
    <section className="relative min-h-screen bg-slate-50/80">
      {/* Mobile top bar */}
      <div className="sticky top-0 z-30 border-b border-slate-200/60 bg-white/90 backdrop-blur lg:hidden">
        <div className="max-w-7xl mx-auto px-4 h-14 flex items-center justify-between gap-3">
          <button
            onClick={() => navigate(-1)}
            className="inline-flex items-center gap-2 text-slate-700"
            aria-label="Back"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>

          <p className="text-sm font-extrabold text-slate-900 truncate min-w-0">
            {title}
          </p>

          {readOnly ? (
            <span className="text-[11px] px-2 py-1 rounded-full bg-slate-100 text-slate-600 shrink-0">
              Read-only
            </span>
          ) : (
            <span className="w-8" />
          )}
        </div>
      </div>

      <div className="max-w-5xl mx-auto  min-h-screen bg-slate-50/80">
        {/* Header card: top row + title + meta pills */}
        <div className="rounded-2xl border border-slate-200/80 bg-white shadow-sm overflow-hidden mb-6">
          <div className="p-4 sm:p-6">
            <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
              <div className="flex flex-wrap items-center gap-2">
                <StatusChip status={status} />
                {readOnly && (
                  <span className="text-[10px] px-2 py-1 rounded-full bg-slate-100 text-slate-600">
                    Read-only ({roleLabel})
                  </span>
                )}
              </div>
              <span className="inline-flex items-center gap-1.5 text-[11px] text-slate-500">
                <Clock className="h-3.5 w-3.5" />
                Last sync {createdAt ? formatDateSafe(createdAt) : "Just now"}
              </span>
            </div>

            <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-slate-900 tracking-tight break-words">
              {title}
            </h1>

            <div className="mt-4 flex flex-wrap items-center gap-2">
              <MetaPill icon={User}>{valueOrDash(clientName) ? `@ ${valueOrDash(clientName)}` : "—"}</MetaPill>
              <MetaPill icon={Calendar}>
                {duration != null ? `${duration} days` : due ? formatDateSafe(due) : "—"}
              </MetaPill>
              <MetaPill icon={Tag}>{valueOrDash(projectType)}</MetaPill>
              {progress != null && progress !== undefined && (
                <MetaPill>
                  <span className="font-semibold text-slate-800">{progress}%</span> progress
                </MetaPill>
              )}
              {freelancerName && (
                <span className="inline-flex items-center rounded-full border border-slate-200/80 bg-slate-50 w-8 h-8 justify-center text-xs font-bold text-slate-600">
                  {(freelancerName || "?").charAt(0).toUpperCase()}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Actions bar */}
        {id && token && ((isFreelancer && hasApplied) || isOwnerClient) && (
          <div className="flex flex-wrap items-center gap-2 mb-6">
            {isFreelancer && hasApplied && (
              <>
                <ActionPill icon={Bell} onClick={openNotifPanel}>Change requests</ActionPill>
                {!isCompleted && !isWaitingForClient && (
                  <ActionPill primary icon={SendHorizontal} onClick={openDeliverModal}>Deliver</ActionPill>
                )}
                {isWaitingForClient && (
                  <span className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm text-slate-600">Awaiting client decision</span>
                )}
                {isCompleted && !isWaitingForClient && (
                  <span className="inline-flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-2.5 text-sm text-emerald-700 font-medium">Work approved</span>
                )}
              </>
            )}
            {isOwnerClient && (
              <>
                <ActionPill
                  primary
                  icon={isCompleted ? FolderOpen : SendHorizontal}
                  onClick={() => openReviewDrawer(isCompleted ? "files" : "review")}
                >
                  {isCompleted ? "Files" : "Receive"}
                </ActionPill>
                <ActionPill icon={FileText} onClick={() => openReviewDrawer("request")}>Request changes</ActionPill>
                {isWaitingForClient && (
                  <ActionPill primary onClick={approveWork} disabled={approveSubmitting} icon={CheckCircle}>
                    {approveSubmitting ? "Approving…" : "Approve"}
                  </ActionPill>
                )}
                {isBidding ? (
                  <ActionPill icon={Eye} onClick={() => setOffersModalOpen(true)}>
                    Offers{offersForProject.filter((o) => String(o.offer_status || "").toLowerCase() === "pending").length ? ` (${offersForProject.filter((o) => String(o.offer_status || "").toLowerCase() === "pending").length})` : ""}
                  </ActionPill>
                ) : (
                  <ActionPill icon={Eye} onClick={openApplicationsModal}>Applicants</ActionPill>
                )}
              </>
            )}
          </div>
        )}

        {readOnly && !(id && token && ((isFreelancer && hasApplied) || isOwnerClient)) && (
          <p className="text-sm text-slate-500 mb-6">Read-only mode. Actions are disabled.</p>
        )}

        {/* Tabs */}
        <ProjectTabs
          tabs={[
            { id: "overview", label: "Overview" },
            { id: "workstream", label: "Workstream" },
            { id: "tasks", label: "Tasks" },
            { id: "notes", label: "Notes" },
            { id: "files", label: "Files" },
            { id: "comments", label: "Comments" },
          ]}
          active={activeTab}
          onChange={setActiveTab}
        />

        {/* Content card */}
        <div className="mt-0 rounded-b-2xl border border-t-0 border-slate-200/80 bg-white shadow-sm overflow-hidden">
          {activeTab === "overview" && (
            <div className="p-5 sm:p-6">
              <SectionBlock title="Goals">
                <p className="break-words">{descExpanded ? description : shortDesc}</p>
                {description?.length > 260 && (
                  <button type="button" onClick={() => setDescExpanded((v) => !v)} className="mt-2 text-sm font-semibold hover:opacity-90" style={{ color: THEME_DARK }}>
                    {descExpanded ? "Show less" : "Read more"}
                  </button>
                )}
              </SectionBlock>
              <SectionBlock title="In scope">
                <ul className="list-disc list-inside space-y-1 text-slate-600">
                  {description ? <li>Project delivery as per agreement</li> : null}
                  <li>Quality work within deadline</li>
                  {!description && <li>—</li>}
                </ul>
              </SectionBlock>
              <SectionBlock title="Out of scope">
                <ul className="list-disc list-inside space-y-1 text-slate-600">
                  <li>Additional work beyond original scope</li>
                  <li>—</li>
                </ul>
              </SectionBlock>
              <SectionBlock title="Expected outcomes">
                <ul className="list-disc list-inside space-y-1 text-slate-600">
                  <li>Completed deliverables</li>
                  <li>Client approval and release</li>
                </ul>
              </SectionBlock>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-6 pt-6 border-t border-slate-100">
                <div className="rounded-xl border border-slate-100 bg-slate-50/50 p-3">
                  <div className="text-[11px] font-semibold text-slate-500">Budget</div>
                  <div className="text-sm font-bold text-slate-900">{budget != null ? `${budget} JD` : "—"}</div>
                </div>
                <div className="rounded-xl border border-slate-100 bg-slate-50/50 p-3">
                  <div className="text-[11px] font-semibold text-slate-500">Type</div>
                  <div className="text-sm font-bold text-slate-900 truncate">{valueOrDash(projectType)}</div>
                </div>
                <div className="rounded-xl border border-slate-100 bg-slate-50/50 p-3">
                  <div className="text-[11px] font-semibold text-slate-500">Duration</div>
                  <div className="text-sm font-bold text-slate-900">{duration != null ? `${duration} days` : "—"}</div>
                </div>
                <div className="rounded-xl border border-slate-100 bg-slate-50/50 p-3">
                  <div className="text-[11px] font-semibold text-slate-500">Category</div>
                  <div className="text-sm font-bold text-slate-900 truncate">{valueOrDash(category)}</div>
                </div>
              </div>
            </div>
          )}

          {activeTab === "files" && (
            <div className="p-5 sm:p-6">
              {cover && (
                <div className="rounded-xl border border-slate-200 overflow-hidden bg-slate-50 mb-6">
                  <img src={cover} alt={title} className="w-full max-h-[320px] object-contain" />
                </div>
              )}
              {item.attachments && (
                <SectionCard title="Attachments" icon={Paperclip}>
                  <AttachmentList
                    attachments={item.attachments}
                    title={null}
                    projectId={id}
                  />
                </SectionCard>
              )}
              {projectFiles.length > 0 ? (
                <SectionCard title="Project Files" icon={FolderOpen}>
                  <AttachmentList
                    attachments={projectFiles}
                    title={null}
                    projectId={id}
                  />
                </SectionCard>
              ) : !item.attachments?.length && (
                <p className="text-slate-500 text-sm">No files or attachments yet.</p>
              )}
            </div>
          )}

          {(activeTab === "workstream" || activeTab === "tasks" || activeTab === "notes" || activeTab === "comments") && (
            <div className="p-5 sm:p-6 text-slate-500 text-sm">
              {activeTab === "workstream" && "Workstream — coming soon."}
              {activeTab === "tasks" && "Tasks — coming soon."}
              {activeTab === "notes" && "Notes — coming soon."}
              {activeTab === "comments" && "Comments — coming soon."}
            </div>
          )}
        </div>

        {/* Trust & safety */}
        <div className="mt-6 rounded-2xl border border-slate-200/80 bg-white shadow-sm p-4 sm:p-5">
          <div className="text-sm font-bold text-slate-900">Trust & safety</div>
          <div className="mt-3 flex flex-wrap gap-2 text-xs text-slate-600">
            <span className="inline-flex items-center gap-2 rounded-full bg-orange-50 px-3 py-1.5"><span className="h-1.5 w-1.5 rounded-full bg-orange-500" /> Secure checkout</span>
            <span className="inline-flex items-center gap-2 rounded-full bg-orange-50 px-3 py-1.5"><span className="h-1.5 w-1.5 rounded-full bg-orange-500" /> Money back guarantee</span>
            <span className="inline-flex items-center gap-2 rounded-full bg-orange-50 px-3 py-1.5"><span className="h-1.5 w-1.5 rounded-full bg-orange-500" /> 24/7 support</span>
          </div>
        </div>
      </div>

      {/* Mobile action bar: show only for freelancers in interactive mode */}
      <MobileBottomBar
        hidden={readOnly || !isFreelancer}
        acceptLabel={acceptLabel}
        onAccept={onApplyToProject}
        acceptDisabled={acceptDisabled}
      />

      {/* Apply/Offer Modal */}
      {showApplyModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-3xl shadow-2xl max-w-md w-full p-6 sm:p-8 relative animate-[scale-in_0.2s_ease-out]">
            <button
              onClick={() => {
                setShowApplyModal(false);
                setOfferAmount("");
              }}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 transition"
              aria-label="Close"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="text-center">
              <h3 className="text-xl sm:text-2xl font-bold text-slate-800 mb-2">
                {applyModalType === "offer"
                  ? "Send Your Offer"
                  : "Apply to Project"}
              </h3>

              <p className="text-slate-600 mb-6 text-sm sm:text-base">
                {applyModalType === "offer"
                  ? "Enter your offer amount to get started"
                  : "Are you sure you want to apply to this project?"}
              </p>

              {applyModalType === "offer" && (
                <div className="mb-6">
                  <label className="block text-left text-sm font-medium text-slate-700 mb-2">
                    Offer Amount
                  </label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-semibold">
                      $
                    </span>
                    <input
                      type="number"
                      value={offerAmount}
                      onChange={(e) => setOfferAmount(e.target.value)}
                      placeholder="0.00"
                      className="w-full h-12 pl-8 pr-4 border-2 border-slate-200 rounded-xl focus:border-orange-400 focus:outline-none text-lg font-semibold"
                    />
                  </div>
                </div>
              )}

              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowApplyModal(false);
                    setOfferAmount("");
                  }}
                  className="flex-1 h-12 rounded-xl border-2 border-slate-200 text-slate-700 font-semibold hover:bg-slate-50 transition"
                  disabled={busy}
                >
                  Cancel
                </button>
                <button
                  onClick={handleConfirmApply}
                  className="flex-1 h-12 rounded-xl text-white font-semibold hover:shadow-lg transition"
                  style={{ backgroundColor: THEME }}
                  disabled={busy}
                >
                  {busy
                    ? "Sending..."
                    : applyModalType === "offer"
                    ? "Send Offer"
                    : "Yes, Apply!"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Deliver — نفس لوحة AdminProjects (DeliverModal) */}
      {deliverOpen && item && (
        <DeliverModal
          project={item}
          onClose={() => setDeliverOpen(false)}
          onSubmit={submitDeliverPayload}
          submitting={deliverSubmitting}
        />
      )}

      {/* Change requests panel */}
      {notifOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-3xl shadow-2xl max-w-md w-full max-h-[80vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h3 className="text-lg font-bold text-slate-800">Change requests</h3>
              <button onClick={() => setNotifOpen(false)} className="p-1.5 rounded-lg hover:bg-slate-100"><X className="w-5 h-5" /></button>
            </div>
            <div className="p-4 overflow-y-auto flex-1">
              {notifLoading ? (
                <p className="text-slate-500 text-sm">Loading…</p>
              ) : notifItems.length === 0 ? (
                <p className="text-slate-500 text-sm">No change requests.</p>
              ) : (
                <ul className="space-y-3">
                  {notifItems.map((n) => (
                    <li key={n.id || n.created_at} className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-sm text-slate-800">
                      {n.message}
                      {n.created_at ? <p className="text-xs text-slate-500 mt-1">{new Date(n.created_at).toLocaleString()}</p> : null}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      )}

      {/* لوحة المراجعة/الاستلام/طلب التعديلات — نفس AdminProjects (ClientReviewDrawer) */}
      {reviewDrawerOpen && item && (
        <ClientReviewDrawer
          project={item}
          mode={reviewDrawerMode}
          readOnly={reviewDrawerMode === "files"}
          onClose={() => {
            setReviewDrawerOpen(false);
            setReviewDrawerMode("review");
          }}
          onApprove={async (projectId) => {
            await API.put(`/projects/${projectId}/approve`, { action: "approve" }, authHeaders);
            getProjectByIdApi(id).then((res) => setItem(res?.task || res?.project || res));
            setReviewDrawerOpen(false);
          }}
          onRequestChanges={async (projectId, message) => {
            await API.post(`/projects/${projectId}/request-changes`, { message }, authHeaders);
            getProjectByIdApi(id).then((res) => setItem(res?.task || res?.project || res));
          }}
          token={token}
        />
      )}

      {/* العروض — نفس لوحة AdminProjects (ClientOffersDrawer) */}
      {offersModalOpen && (
        <ClientOffersDrawer
          project={{ id, title }}
          offers={offersForProject}
          onClose={() => setOffersModalOpen(false)}
          onAction={handleOfferAction}
          submitting={offersSubmitting}
        />
      )}

      {/* المتقدمون — نفس لوحة AdminProjects (ClientApplicationsDrawer) */}
      {applicationsModalOpen && (
        <ClientApplicationsDrawer
          project={{ id, title }}
          applications={applicationsList}
          onClose={() => {
            setApplicationsModalOpen(false);
            setApplicationsList([]);
          }}
          onAction={handleApplicationAction}
          submitting={appsSubmitting}
        />
      )}

      <style>{`
        @keyframes scale-in {
          from { opacity: 0; transform: scale(0.95); }
          to { opacity: 1; transform: scale(1); }
        }
      `}</style>
    </section>
  );
}
