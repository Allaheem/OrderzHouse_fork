import { useState, useEffect, useRef, useMemo } from "react";
import { createPortal } from "react-dom";
import { useSelector } from "react-redux";
import { useNavigate, useLocation } from "react-router-dom";
import axios from "axios";
import API from "../../../api/axios.js";
import { getClientProjects } from "../../../api/projects";
import PeopleTable from "../../Tables";
import { useToast } from "../../../../components/toast/ToastProvider";
import {
  Eye,
  MessageSquare,
  SendHorizontal,
  X,
  Bell,
  RefreshCw,
  Check,
  Undo2,
  Loader2,
  FileText,
  Code,
  Palette,
  Link2,
  Download,
  FolderOpen,
  Activity,
  LayoutList,
  Clock,
  CreditCard,
} from "lucide-react";

/* ---------- Theme ---------- */
const T = { primary: "#C2410C", dark: "#9A3412", ring: "rgba(15,23,42,.10)" };
const ringStyle = { border: `1px solid ${T.ring}` };

/* ---------- Small UI helpers (Projects page) ---------- */
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
  soft:
    "bg-orange-50 text-orange-700 border border-orange-200/70 hover:bg-orange-100",
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

function statFromProjects(list = []) {
  const norm = (p) =>
    String(p?.completion_status || p?.status || "").toLowerCase();

  let total = list.length;
  let completed = 0;
  let pendingReview = 0;
  let pendingPayment = 0;
  let active = 0;

  for (const p of list) {
    const s = norm(p);
    const isCompleted = ["completed", "done", "finished"].includes(s);
    const isPendingReview = [
      "pending_review",
      "awaiting_client",
      "waiting_client",
    ].includes(s);
    const isPendingPayment = ["pending_payment", "payment_pending"].includes(s);

    if (isCompleted) completed++;
    else if (isPendingReview) pendingReview++;
    else if (isPendingPayment) pendingPayment++;
    else active++;
  }

  return { total, active, pendingReview, pendingPayment, completed };
}

function useProjectsStats(endpoint, token) {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    pendingReview: 0,
    pendingPayment: 0,
    completed: 0,
  });

  useEffect(() => {
    if (!token || !endpoint) return;

    let cancelled = false;

    (async () => {
      setLoading(true);
      try {
        const { data } = await API.get(endpoint, {
          headers: { authorization: `Bearer ${token}` },
        });

        const list = Array.isArray(data?.data)
          ? data.data
          : Array.isArray(data?.projects)
          ? data.projects
          : Array.isArray(data)
          ? data
          : [];

        if (!cancelled) setStats(statFromProjects(list));
      } catch (_) {
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [endpoint, token]);

  return { stats, loading };
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
          <div className="text-sm font-extrabold text-slate-900">{value}</div>
        </div>
      </div>
    </div>
  );
}

function ProjectsHero({ title, subtitle, eyebrow = "PROJECTS" }) {
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

function ProjectsKPIs({ stats, loading }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <StatPill
        icon={LayoutList}
        label="Total projects"
        value={loading ? "…" : stats.total}
        tone="slate"
      />
      <StatPill
        icon={Activity}
        label="Active"
        value={loading ? "…" : stats.active}
        tone="orange"
      />
      <StatPill
        icon={Clock}
        label="Pending review"
        value={loading ? "…" : stats.pendingReview}
        tone="amber"
      />
      <StatPill
        icon={CreditCard}
        label="Pending payment"
        value={loading ? "…" : stats.pendingPayment}
        tone="orange"
      />
    </div>
  );
}

/* ---------- Role map ---------- */
function mapRole(roleId) {
  if (roleId === 1) return "admin";
  if (roleId === 2) return "client";
  if (roleId === 3) return "freelancer";
  return "user";
}

/* ===================== Entry ===================== */
export default function Projects() {
  const { userData } = useSelector((s) => s.auth);
  const role = mapRole(userData?.role_id);

  if (role === "admin") return <AdminProjects />;
  if (role === "freelancer") return <FreelancerProjects />;
  return <ClientProjects />;
}

/* ===================== Admin ===================== */
function AdminProjects() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const roleBase = useMemo(() => {
    const seg = (pathname.split("/")[1] || "").toLowerCase();
    return ["admin", "client", "freelancer", "partner"].includes(seg)
      ? `/${seg}`
      : "/admin";
  }, [pathname]);
  const { token } = useSelector((s) => s.auth);
  const { stats, loading } = useProjectsStats(
    "/projects/admin/projects",
    token
  );

  // columns
  const columns = [
    { label: "Title", key: "title" },
    { label: "Client", key: "client_name" },
    { label: "Freelancer", key: "freelancer_name" },
    { label: "Type", key: "project_type" },
    {
      label: "Status",
      key: "status",
      render: (row) => row?.completion_status || row?.status,
    },
    { label: "Completion", key: "completion_status" },
    { label: "Category", key: "project_category" },
    {
      label: "Created",
      key: "created_at",
      render: (row) =>
        row.created_at ? new Date(row.created_at).toLocaleDateString() : "—",
    },
  ];

  // form fields — values must match DB enums (PUT /projects/admin/projects/:id)
  const formFields = [
    { key: "title", label: "Title", required: true },
    {
      key: "completion_status",
      label: "Progress (completion_status)",
      type: "select",
      options: [
        { value: "not_started", label: "Not started" },
        { value: "in_progress", label: "In progress" },
        { value: "pending_review", label: "Pending review" },
        { value: "revision_requested", label: "Revision requested" },
        { value: "completed", label: "Completed" },
        { value: "invitation_sent", label: "Invitation sent" },
        { value: "overdue", label: "Overdue" },
      ],
    },
    {
      key: "status",
      label: "Workflow (status)",
      type: "select",
      options: [
        { value: "active", label: "Active (listed for fixed/hourly)" },
        { value: "bidding", label: "Bidding" },
        {
          value: "pending_admin_approval",
          label: "Pending admin approval (e.g. offline payment)",
        },
        { value: "in_progress", label: "In progress (work)" },
        { value: "pending_review", label: "Pending review" },
        { value: "completed", label: "Completed" },
        { value: "pending_acceptance", label: "Pending acceptance" },
        { value: "open", label: "Open" },
        { value: "terminated", label: "Terminated" },
      ],
    },
    {
      key: "admin_approval_status",
      label: "Payment / listing approval",
      type: "select",
      options: [
        { value: "none", label: "None" },
        { value: "pending", label: "Pending" },
        { value: "approved", label: "Approved" },
        { value: "rejected", label: "Rejected" },
      ],
    },
    { key: "budget", label: "Budget", type: "number", placeholder: "12000" },
    { key: "description", label: "Description", type: "textarea" },
  ];

  const chips = [
    { label: "All", value: "" },
    { label: "Not started", value: "not_started" },
    { label: "In progress", value: "in_progress" },
    { label: "Pending review", value: "pending_review" },
    { label: "Completed", value: "completed" },
  ];

  return (
    <div className="space-y-5">
      <ProjectsHero
        eyebrow="ADMIN"
        title="Projects"
        subtitle="Manage all projects, track status, and keep everything organized."
      />
      <ProjectsKPIs stats={stats} loading={loading} />
      <PeopleTable
        /* header */
        title="Projects"
        addLabel="Add Project"
        /* data */
        endpoint="/projects/admin/projects"
        token={token}
        columns={columns}
        formFields={formFields}
        chips={chips}
        chipField="completion_status"
        filters={[
          {
            key: "completion_status",
            label: "Progress",
            options: chips.slice(1).map((c) => c.value),
          },
        ]}
        /* UI */
        desktopAsCards
        hideCardAvatar
        /* Admin wants default CRUD inside cards */
        crudConfig={{ showDetails: false, showRowEdit: true, showDelete: true }}
        /* open details (admin route غالباً نسبي) */
        onCardClick={(row, h) =>
          navigate(`${roleBase}/project/${h.getId(row)}`)
        }
      />
    </div>
  );
}

/* ===================== Client ===================== */
function ClientProjects() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const toast = useToast();
  const roleBase = useMemo(() => {
    const seg = (pathname.split("/")[1] || "").toLowerCase();
    return ["admin", "client", "freelancer", "partner"].includes(seg)
      ? `/${seg}`
      : "/admin";
  }, [pathname]);
  const { token } = useSelector((s) => s.auth);
  const { stats, loading } = useProjectsStats("/projects/myprojects", token);

  // لوحات العميل (استلام التسليم)
  const [reviewOpen, setReviewOpen] = useState(false);
  const [reviewFor, setReviewFor] = useState(null);
  const [offersMap, setOffersMap] = useState({});
  const [offersListMap, setOffersListMap] = useState({});

  // عروض المشاريع (Offers) — Drawer
  const [offersProject, setOffersProject] = useState(null);
  const [offersOpen, setOffersOpen] = useState(false);
  const [offersSubmitting, setOffersSubmitting] = useState(false);

  // طلبات الفريلانسَر (applications)
  const [applicationsMap, setApplicationsMap] = useState({});
  const [appsProject, setAppsProject] = useState(null);
  const [appsOpen, setAppsOpen] = useState(false);
  const [appsSubmitting, setAppsSubmitting] = useState(false);
  const [reviewHelpers, setReviewHelpers] = useState(null);
  const [reviewMode, setReviewMode] = useState("review");

  // جلب عروض العميل لكل مشاريعه مرة واحدة
  useEffect(() => {
    if (!token) return;
    let cancelled = false;

    (async () => {
      try {
        const { data } = await API.get("/offers/my-projects/offers", {
          headers: token ? { authorization: `Bearer ${token}` } : undefined,
        });

        const list = Array.isArray(data?.data)
          ? data.data
          : Array.isArray(data?.offers)
          ? data.offers
          : [];

        const map = {};
        const listMap = {};
        for (const o of list) {
          const pid = o.project_id ?? o.projectId;
          if (!pid) continue;
          if (!map[pid]) {
            map[pid] = { total: 0, pending: 0, accepted: 0 };
          }
          map[pid].total += 1;
          const status = String(o.offer_status || "").toLowerCase();
          if (status === "pending") map[pid].pending += 1;
          if (status === "accepted") map[pid].accepted += 1;

          if (!listMap[pid]) listMap[pid] = [];
          listMap[pid].push(o);
        }

        if (!cancelled) {
          setOffersMap(map);
          setOffersListMap(listMap);
        }
      } catch (_) {
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [token]);

  const fetchOffersForProject = async (projectId) => {
    if (!token) return;
    try {
      const { data } = await API.get("/offers/my-projects/offers", {
        headers: { authorization: `Bearer ${token}` },
      });

      const list = Array.isArray(data?.data)
        ? data.data
        : Array.isArray(data?.offers)
        ? data.offers
        : [];

      const filtered = list.filter((o) => {
        const pid = o.project_id ?? o.projectId;
        return String(pid) === String(projectId);
      });

      const stats = { total: 0, pending: 0, accepted: 0 };
      for (const o of filtered) {
        stats.total += 1;
        const status = String(o.offer_status || "").toLowerCase();
        if (status === "pending") stats.pending += 1;
        if (status === "accepted") stats.accepted += 1;
      }

      setOffersListMap((prev) => ({ ...prev, [projectId]: filtered }));
      setOffersMap((prev) => ({ ...prev, [projectId]: stats }));
    } catch (_) {
    }
  };

  // تحديث حالة Offer (accept / reject)
  const handleOfferAction = async (offerId, projectId, action) => {
    if (!token) return;
    setOffersSubmitting(true);
    try {
      const res = await API.post(
        "/offers/approve-reject",
        { offerId, action },
        {
          headers: token ? { authorization: `Bearer ${token}` } : undefined,
          timeout: 15000,
        }
      );

      if (action === "accept" && res?.data?.requiresPayment === true) {
        const payRes = await API.post(
          "/stripe/offer-accept-checkout",
          { offerId },
          { headers: { authorization: `Bearer ${token}` }, timeout: 15000 }
        );
        if (payRes?.data?.url) {
          window.location.href = payRes.data.url;
          return;
        }
      }

      // Check if admin approval is required (bidding flow)
      if (action === "accept" && res?.data?.pendingAdminApproval === true) {
        const pid = res?.data?.projectId ?? projectId;
        setOffersListMap((prev) => {
          const next = { ...prev };
          const list = next[projectId] ? [...next[projectId]] : [];
          next[projectId] = list.map((o) => {
            const oid = o.offer_id ?? o.offerId ?? o.id;
            if (String(oid) === String(offerId)) return { ...o, offer_status: "accepted" };
            if (String(o.offer_status || "").toLowerCase() === "pending") return { ...o, offer_status: "rejected" };
            return o;
          });
          const updated = next[projectId] || [];
          const stats = { total: 0, pending: 0, accepted: 0 };
          for (const o of updated) {
            stats.total += 1;
            if (String(o.offer_status || "").toLowerCase() === "pending") stats.pending += 1;
            if (String(o.offer_status || "").toLowerCase() === "accepted") stats.accepted += 1;
          }
          setOffersMap((m) => ({ ...m, [projectId]: stats }));
          return next;
        });
        toast.success("Offer accepted. Choose payment method on the next page.");
        setOffersOpen(false);
        setOffersProject(null);
        if (pid) navigate(`/projects/success/${pid}`);
        return;
      }

      setOffersListMap((prev) => {
        const next = { ...prev };
        const list = next[projectId] ? [...next[projectId]] : [];

        if (action === "accept") {
          next[projectId] = list.map((o) => {
            const oid = o.offer_id ?? o.offerId ?? o.id;
            if (String(oid) === String(offerId)) {
              return { ...o, offer_status: "accepted" };
            }
            const st = String(o.offer_status || "").toLowerCase();
            if (st === "pending") return { ...o, offer_status: "rejected" };
            return o;
          });
        } else {
          next[projectId] = list.map((o) => {
            const oid = o.offer_id ?? o.offerId ?? o.id;
            if (String(oid) === String(offerId)) {
              return { ...o, offer_status: "rejected" };
            }
            return o;
          });
        }

        // sync stats
        const updated = next[projectId] || [];
        const stats = { total: 0, pending: 0, accepted: 0 };
        for (const o of updated) {
          stats.total += 1;
          const st = String(o.offer_status || "").toLowerCase();
          if (st === "pending") stats.pending += 1;
          if (st === "accepted") stats.accepted += 1;
        }
        setOffersMap((m) => ({ ...m, [projectId]: stats }));

        return next;
      });
    } catch (err) {
      // لو العرض منتهي (expired) خلي UI يحدث
      const msg = err?.response?.data?.message || "";
      if (String(msg).toLowerCase().includes("expired")) {
        setOffersListMap((prev) => {
          const next = { ...prev };
          const list = next[projectId] ? [...next[projectId]] : [];
          next[projectId] = list.map((o) => {
            const oid = o.offer_id ?? o.offerId ?? o.id;
            if (String(oid) === String(offerId)) {
              return { ...o, offer_status: "expired" };
            }
            return o;
          });
          return next;
        });
      }

      toast.error(msg || "Failed to update offer. Please try again.");
    } finally {
      setOffersSubmitting(false);
    }
  };

  // // جلب طلبات التقديم (applications) لكل مشاريع الكلينت
  // useEffect(() => {
  //   if (!token) return;
  //   let cancelled = false;

  //   (async () => {
  //     try {
  //       const { data } = await API.get("/projects/applications/my-projects", {
  //         headers: token ? { authorization: `Bearer ${token}` } : undefined,
  //       });

  //       const list = Array.isArray(data?.applications)
  //         ? data.applications
  //         : Array.isArray(data?.data)
  //         ? data.data
  //         : Array.isArray(data)
  //         ? data
  //         : [];

  //       const map = {};
  //       for (const app of list) {
  //         const pid = app.project_id ?? app.projectId;
  //         if (!pid) continue;
  //         if (!map[pid]) map[pid] = [];
  //         map[pid].push(app);
  //       }

  //       if (!cancelled) setApplicationsMap(map);
  //     } catch (e) {
  //       console.error("Failed to fetch applications for client projects", e);
  //     }
  //   })();

  //   return () => {
  //     cancelled = true;
  //   };
  // }, [token]);

  const fetchApplicationsForProject = async (projectId) => {
    if (!token) return;
    try {
      const { data } = await API.get(
        `/projects/project/${projectId}/applications`,
        {
          headers: { authorization: `Bearer ${token}` },
        }
      );

      const list = Array.isArray(data?.applications)
        ? data.applications
        : Array.isArray(data?.data)
        ? data.data
        : Array.isArray(data)
        ? data
        : [];

      setApplicationsMap((prev) => ({
        ...prev,
        [projectId]: list,
      }));
    } catch (_) {
    }
  };

  // تحديث حالة application (accept / reject)
  const handleApplicationAction = async (assignmentId, projectId, action) => {
    if (!token) return;
    setAppsSubmitting(true);
    try {
      await API.post(
        "/projects/applications/decision",
        { assignmentId, id: assignmentId, projectId, action },
        {
          headers: token ? { authorization: `Bearer ${token}` } : undefined,
          timeout: 15000, // 15s
        }
      );

      setApplicationsMap((prev) => {
        const next = { ...prev };
        const list = next[projectId] ? [...next[projectId]] : [];
        if (!list.length) {
          next[projectId] = list;
          return next;
        }

        if (action === "accept") {
          // واحد مقبول والباقي not_chosen حسب الباك إند
          next[projectId] = list.map((app) => {
            const key = app.assignment_id ?? app.id;
            if (key === assignmentId) {
              return { ...app, status: "active" };
            }
            const statusKey = String(app.status || "").toLowerCase();
            if (statusKey === "pending_client_approval") {
              return { ...app, status: "not_chosen" };
            }
            return app;
          });
        } else {
          // reject فقط لهذا الـ assignment
          next[projectId] = list.map((app) => {
            const key = app.assignment_id ?? app.id;
            if (key === assignmentId) {
              return { ...app, status: "rejected" };
            }
            return app;
          });
        }

        return next;
      });
    } catch (err) {
      toast.error(
        err?.response?.data?.message ||
          "Failed to update application. Please try again."
      );
    } finally {
      setAppsSubmitting(false);
    }
  };

  // أزرار العميل داخل الكارد
  const renderActions = (row, helpers) => {
    const id = helpers.getId(row);
    const pid = row.id ?? row._id ?? id;
    const appsForProject = applicationsMap[pid] || [];
    const projectType = String(row.project_type || "").toLowerCase();
    const isBidding = projectType === "bidding";

    const pendingCount = appsForProject.filter(
      (a) => String(a.status || "").toLowerCase() === "pending_client_approval"
    ).length;

    const statusKey = String(
      row.completion_status || row.status || ""
    ).toLowerCase();
    const isCompleted = statusKey === "completed" || statusKey === "done";
    const pendingOffers = offersMap[pid]?.pending || 0;

    return (
      <div className="flex flex-wrap gap-2 w-full">
        <ActionButton
          variant="primary"
          onClick={(e) => {
            e.stopPropagation();
            setReviewHelpers(helpers);
            setReviewFor(row);
            setReviewMode(isCompleted ? "files" : "review");
            setReviewOpen(true);
          }}
          title={
            isCompleted ? "View project files" : "Review & receive delivery"
          }
        >
          {isCompleted ? (
            <FolderOpen className="w-4 h-4 shrink-0" />
          ) : (
            <SendHorizontal className="w-4 h-4 shrink-0" />
          )}
          {isCompleted ? "Files" : "Receive"}
        </ActionButton>

        {isCompleted ? (
          <ActionButton
            variant="outline"
            onClick={(e) => {
              e.stopPropagation();
              setReviewHelpers(helpers);
              setReviewFor(row);
              setReviewMode("request");
              setReviewOpen(true);
            }}
            title="Request changes from freelancer"
          >
            <Undo2 className="w-4 h-4 shrink-0" />
            Request changes
          </ActionButton>
        ) : isBidding ? (
          <ActionButton
            variant="outline"
            onClick={async (e) => {
              e.stopPropagation();
              setOffersProject({ id: pid, title: row.title });
              await fetchOffersForProject(pid);
              setOffersOpen(true);
            }}
          >
            <Eye className="w-4 h-4 shrink-0" />
            Offers{pendingOffers ? ` (${pendingOffers})` : ""}
          </ActionButton>
        ) : (
          <ActionButton
            variant="outline"
            onClick={async (e) => {
              e.stopPropagation();
              setAppsProject({ id: pid, title: row.title });
              await fetchApplicationsForProject(pid);
              setAppsOpen(true);
            }}
          >
            <Eye className="w-4 h-4 shrink-0" />
            Applicants{pendingCount ? ` (${pendingCount})` : ""}
          </ActionButton>
        )}
      </div>
    );
  };

  const currentApplications =
    appsProject && applicationsMap[appsProject.id]
      ? applicationsMap[appsProject.id]
      : [];

  const currentOffers =
    offersProject && offersListMap[offersProject.id]
      ? offersListMap[offersProject.id]
      : [];

  return (
    <>
      <div className="space-y-5">
        <ProjectsHero
          eyebrow="CLIENT"
          title="My projects"
          subtitle="Review deliveries, manage applicants, and track progress."
        />
        <ProjectsKPIs stats={stats} loading={loading} />
        <PeopleTable
          /* header */
          title="My Projects"
          /* data */
          endpoint="/projects/myprojects"
          token={token}
          columns={[
            { label: "Title", key: "title" },
            { label: "Freelancer", key: "assignee" },
            { label: "Due", key: "due" },
            { label: "Budget", key: "budget" },
            { label: "Progress", key: "progress" },
            { label: "Status", key: "completion_status" },
            {
              label: "Offers",
              key: "offers",
              render: (row) => {
                const pid = row.id ?? row._id;
                const stats = offersMap[pid];
                if (!stats) return "0";
                const parts = [`${stats.total}`];
                if (stats.pending) parts.push(`pending: ${stats.pending}`);
                if (stats.accepted) parts.push(`accepted: ${stats.accepted}`);
                return parts.join(" | ");
              },
            },
          ]}
          formFields={[]}
          /* UI */
          desktopAsCards
          hideCardAvatar
          crudConfig={{
            showDetails: false,
            showRowEdit: false,
            showDelete: false,
          }}
          mobileAsCards
          renderActions={renderActions}
          renderSubtitle={(row) => {
            const pid = row.id ?? row._id;
            const stats = offersMap[pid];
            if (!stats) {
              return <span className="text-xs text-slate-400">Offers: 0</span>;
            }
            return (
              <span className="text-xs text-slate-600">
                Offers: <span className="font-semibold">{stats.total}</span>
                {stats.pending ? ` • Pending: ${stats.pending}` : ""}
                {stats.accepted ? ` • Accepted: ${stats.accepted}` : ""}
              </span>
            );
          }}
          onCardClick={(row, h) =>
            navigate(`${roleBase}/project/${h.getId(row)}`, {
              state: { project: row, readOnly: true, role: "client" },
            })
          }
        />
      </div>
      {reviewOpen && reviewFor && (
        <ClientReviewDrawer
          project={reviewFor}
          mode={reviewMode}
          readOnly={reviewMode === "files"}
          onClose={() => {
            setReviewOpen(false);
            setReviewFor(null);
            setReviewMode("review");
          }}
          onApprove={async (projectId) => {
            await API.put(
              `/projects/${projectId}/approve`,
              { action: "approve" },
              {
                headers: token
                  ? { authorization: `Bearer ${token}` }
                  : undefined,
              }
            );

            // ✅ تحديث فوري للـ chip بدون ريفرش صفحة
            reviewHelpers?.setRows?.((prev) =>
              prev.map((r) => {
                const rid = reviewHelpers?.getId?.(r) ?? r.id ?? r._id;
                if (String(rid) !== String(projectId)) return r;

                return {
                  ...r,
                  completion_status: "completed", // إذا أنت تعرض completion_status
                  status: "completed", // احتياط لو تعرض status
                };
              })
            );

            // ✅ اختياري: إعادة جلب من السيرفر للتأكيد
            reviewHelpers?.refresh?.();
          }}
          onRequestChanges={async (projectId, message) => {
            const headers = token
              ? { authorization: `Bearer ${token}` }
              : undefined;

            // ✅ endpoint الصحيح
            await API.post(
              `/projects/${projectId}/request-changes`,
              { message },
              { headers }
            );

            // ✅ تحديث فوري للواجهة: completed -> in_progress
            reviewHelpers?.setRows?.((prev) =>
              prev.map((r) => {
                const rid = reviewHelpers?.getId?.(r) ?? r.id ?? r._id;
                if (String(rid) !== String(projectId)) return r;
                return {
                  ...r,
                  status: "in_progress",
                  completion_status: "in_progress",
                };
              })
            );

            // ✅ ريـفريش للبيانات (اختياري)
            reviewHelpers?.refresh?.();

            // ✅ اغلاق اللوحة
            setReviewOpen(false);
          }}
          token={token}
        />
      )}

      {appsOpen && appsProject && (
        <ClientApplicationsDrawer
          project={appsProject}
          applications={currentApplications}
          onClose={() => {
            setAppsOpen(false);
            setAppsProject(null);
          }}
          onAction={handleApplicationAction}
          submitting={appsSubmitting}
        />
      )}

      {offersOpen && offersProject && (
        <ClientOffersDrawer
          project={offersProject}
          offers={currentOffers}
          onClose={() => {
            setOffersOpen(false);
            setOffersProject(null);
          }}
          onAction={handleOfferAction}
          submitting={offersSubmitting}
        />
      )}
    </>
  );
}

/* ===================== Freelancer ===================== */
function FreelancerProjects() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const roleBase = useMemo(() => {
    const seg = (pathname.split("/")[1] || "").toLowerCase();
    return ["admin", "client", "freelancer", "partner"].includes(seg)
      ? `/${seg}`
      : "/admin";
  }, [pathname]);
  const { token } = useSelector((s) => s.auth);
  const { stats, loading } = useProjectsStats("/projects/myprojects", token);
  const tableHelpersRef = useRef(null);
  const [pendingLocal, setPendingLocal] = useState({});

  // form deliver
  const [deliverOpen, setDeliverOpen] = useState(false);
  const [deliverFor, setDeliverFor] = useState(null);
  const [deliverSubmitting, setDeliverSubmitting] = useState(false);
  const toast = useToast();

  // notifications (change requests)
  const [notifOpen, setNotifOpen] = useState(false);
  const [notifFor, setNotifFor] = useState(null);
  const [notifLoading, setNotifLoading] = useState(false);
  const [notifItems, setNotifItems] = useState([]);

  const openNotifications = async (row, helpers) => {
    const projectId = helpers.getId(row);
    setNotifFor(row);
    setNotifOpen(true);
    setNotifLoading(true);

    try {
      const headers = token ? { authorization: `Bearer ${token}` } : undefined;

      const { data } = await API.get(`/projects/${projectId}/change-requests`, {
        headers,
      });

      const items = data?.requests || data?.items || [];
      setNotifItems(Array.isArray(items) ? items : []);

      // عند فتح اللوحة نعتبر الإشعارات مقروءة → نحدّث الباكند ونخفّي النقطة
      const hadUnread = !!String(row?.change_request_message || "").trim() || !!Number(row?.change_requests_unresolved_count || 0);
      if (hadUnread) {
        try {
          await API.put(`/projects/${projectId}/change-requests/mark-read`, {}, { headers });
          helpers.setRows?.((prev) =>
            prev.map((r) => {
              if (String(helpers.getId(r)) === String(projectId)) {
                return {
                  ...r,
                  change_request_message: null,
                  change_request_at: null,
                  change_requests_unresolved_count: 0,
                };
              }
              return r;
            })
          );
        } catch (_) {
        }
      }
    } catch (_) {
      const msg = row?.change_request_message;
      setNotifItems(
        msg
          ? [
              {
                id: "local",
                message: msg,
                created_at: row?.change_request_at || null,
              },
            ]
          : []
      );
    } finally {
      setNotifLoading(false);
    }
  };

  const renderActions = (row, helpers) => {
    if (!tableHelpersRef.current) tableHelpersRef.current = helpers;

    const id = helpers.getId(row);

    const completionKey = String(row?.completion_status || "").toLowerCase();
    const statusKey = String(row?.status || "").toLowerCase();
    const isPendingAdminApproval = 
      statusKey === "pending_admin_approval" || 
      completionKey === "pending_admin_approval";

    // ✅ completed state (اعتمد على completion_status)
    const isCompleted =
      completionKey === "completed" ||
      completionKey === "done" ||
      completionKey === "finished";

    // ✅ server says: waiting for client
    const isWaitingServer =
      completionKey === "pending_review" ||
      statusKey === "pending_review" ||
      completionKey === "awaiting_client" ||
      completionKey === "waiting_client" ||
      statusKey === "awaiting_client" ||
      statusKey === "waiting_client";
    // ✅ local fallback: hide Deliver immediately after submit
    const isWaitingLocal = !!pendingLocal[id] && !isCompleted;

    const isWaiting = isWaitingServer || isWaitingLocal;

    return (
      <div className="flex gap-2 w-full">
        {/* Notification bell */}
        <button
          type="button"
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            openNotifications(row, helpers);
          }}
          className="absolute right-3 top-3 inline-flex items-center justify-center h-9 w-9 rounded-full bg-white/90 border border-slate-200 text-slate-700 hover:bg-slate-50"
          title="Notifications"
        >
          <Bell className="w-4 h-4" />
          {!!String(row?.change_request_message || "").trim() ||
          !!Number(row?.change_requests_unresolved_count || 0) ? (
            <span className="absolute -top-1 -right-1 h-2.5 w-2.5 rounded-full bg-orange-500 ring-2 ring-white" />
          ) : null}
        </button>

        {/* ✅ Completed */}
        {isCompleted ? (
          <div className="inline-flex items-center justify-center h-10 px-3 rounded-xl border border-emerald-200 bg-emerald-50 text-emerald-700 text-xs font-semibold">
            ✅ Work has been successfully approved{" "}
          </div>
        ) : isWaiting ? (
          /* ✅ Waiting */
          <div
            className="inline-flex items-center justify-center h-10 px-3 rounded-xl border border-slate-200 bg-white text-xs font-medium"
            title="Waiting for client decision"
          >
            <span className="shiny-text">
              Awaiting the client's decision...
            </span>
          </div>
        ) : isPendingAdminApproval ? (
          /* ✅ Awaiting Admin Approval */
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-700 text-xs font-semibold">
            <Clock className="w-3 h-3" />
            Awaiting Admin Approval
          </div>
        ) : (
          /* ✅ Deliver */
          <button
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              setDeliverFor(row);
              setDeliverOpen(true);
            }}
            className="inline-flex items-center justify-center gap-2 h-10 rounded-xl text-white text-xs px-3 hover:shadow"
            style={{ backgroundColor: T.primary }}
            title="Deliver this project"
          >
            <SendHorizontal className="w-3 h-3" />
            Deliver
          </button>
        )}
      </div>
    );
  };

  const submitDelivery = async ({ project, payload, token }) => {
    setDeliverSubmitting(true);
    try {
      const fd = new FormData();
      (payload.files || []).forEach((f) => fd.append("project_files", f));

      await API.post(`/projects/${project.id}/deliver`, fd, {
        headers: { ...(token ? { authorization: `Bearer ${token}` } : {}) },
      });

      const hid = tableHelpersRef.current?.getId?.(project) ?? project.id;

      // ✅ 1) hide Deliver immediately (local)
      setPendingLocal((m) => ({ ...m, [hid]: true }));

      // ✅ 2) update row instantly (UI)
      tableHelpersRef.current?.setRows?.((prev) =>
        prev.map((r) => {
          const rid = tableHelpersRef.current?.getId?.(r) ?? r.id ?? r._id;
          if (String(rid) !== String(hid)) return r;
          return {
            ...r,
            completion_status: "pending_review",
            status: "pending_review",
          };
        })
      );

      // ✅ 3) refetch to persist after refresh
      tableHelpersRef.current?.refresh?.();

      toast?.success?.("Delivery submitted successfully ✅");
      setDeliverOpen(false);
      setDeliverFor(null);
    } catch (err) {
      toast?.error?.(
        err?.response?.data?.message ||
          "Something went wrong. Please try again."
      );
    } finally {
      setDeliverSubmitting(false);
    }
  };

  return (
    <>
      <div className="space-y-5">
        <ProjectsHero
          eyebrow="FREELANCER"
          title="My assigned projects"
          subtitle="Deliver work, respond to change requests, and track progress."
        />
        <ProjectsKPIs stats={stats} loading={loading} />
        <PeopleTable
          title="My Assigned Projects"
          endpoint="/projects/myprojects"
          token={token}
          renderActions={renderActions}
          columns={[
            { label: "Title", key: "title" },
            { label: "Client", key: "client" },
            { label: "Due", key: "due" },
            { label: "Budget", key: "budget" },
            { label: "Progress", key: "progress" },
            {
              label: "Status",
              key: "status",
              render: (row) => row?.completion_status || row?.status,
            },
          ]}
          formFields={[]}
          desktopAsCards
          mobileAsCards
          hideCardAvatar
          crudConfig={{
            showDetails: false,
            showRowEdit: false,
            showDelete: false,
          }}
          renderSubtitle={() => null}
          onCardClick={(row, h) =>
            navigate(`${roleBase}/project/${h.getId(row)}`, {
              state: { project: row, readOnly: true, role: "freelancer" },
            })
          }
        />
      </div>
      {deliverOpen && deliverFor && (
        <DeliverModal
          project={deliverFor}
          onClose={() => {
            setDeliverOpen(false);
            setDeliverFor(null);
          }}
          onSubmit={(payload) =>
            submitDelivery({ project: deliverFor, payload, token })
          }
          submitting={deliverSubmitting}
        />
      )}

      {notifOpen && (
        <div className="fixed inset-0 z-[9999]">
          <div
            className="absolute inset-0 bg-black/40"
            onClick={() => setNotifOpen(false)}
          />

          <div className="absolute left-1/2 top-[35%] -translate-x-1/2 w-[min(520px,90vw)] bg-white rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            {/* header ثابت */}
            <div className="p-4 border-b border-slate-200 flex items-center justify-between">
              <div className="min-w-0">
                <div className="text-sm font-semibold text-slate-900">
                  Notifications
                </div>
                <div className="text-xs text-slate-500 truncate">
                  {notifFor?.title || ""}
                </div>
              </div>

              <button
                className="h-9 w-9 rounded-full border border-slate-200 hover:bg-slate-50 grid place-items-center"
                onClick={() => setNotifOpen(false)}
                title="Close"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* body قابل للسكرول */}
            <div className="p-4 max-h-[60vh] overflow-y-auto min-h-0">
              {notifLoading ? (
                <div className="text-sm text-slate-500">Loading…</div>
              ) : notifItems.length === 0 ? (
                <div className="text-sm text-slate-500">No messages</div>
              ) : (
                <div className="space-y-3">
                  {notifItems.map((it) => (
                    <div
                      key={it.id}
                      className="rounded-xl border border-slate-200 p-3"
                    >
                      <div className="flex items-center justify-between gap-2 mb-1">
                        <div className="text-xs text-slate-500">
                          {it.created_at
                            ? new Date(it.created_at).toLocaleString()
                            : ""}
                        </div>
                        {it.is_resolved ? (
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-slate-100 border border-slate-200 text-slate-600">
                            Resolved
                          </span>
                        ) : (
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-50 border border-amber-200 text-amber-700">
                            New
                          </span>
                        )}
                      </div>

                      <div className="text-sm text-slate-800 whitespace-pre-wrap">
                        {it.message}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}

/* ===================== Client Drawer (استلام التسليم) ===================== */
function ClientReviewDrawer({
  project,
  onClose,
  onApprove,
  onRequestChanges,
  token,
  readOnly = false,
  mode = "review",
}) {
  const toast = useToast(); // ✅

  const { userData } = useSelector((s) => s.auth);
  const myId = userData?.id ?? userData?.userId ?? userData?.user_id;

  const freelancerId =
    project?.freelancer_id ??
    project?.freelancerId ??
    project?.assigned_freelancer_id ??
    project?.assignedFreelancerId;

  const [deliveries, setDeliveries] = useState([]);
  const [loading, setLoading] = useState(true);

  // ✅ states كانت ناقصة
  const [submitting, setSubmitting] = useState(false);
  const [requesting, setRequesting] = useState(false);
  const [requestText, setRequestText] = useState("");

  const canRequest = typeof onRequestChanges === "function";

  const viewMode = mode || (readOnly ? "files" : "review");
  const isFilesMode = viewMode === "files";
  const isRequestMode = viewMode === "request";
  const headerTitle = isFilesMode
    ? "Project Files"
    : isRequestMode
    ? "Request changes"
    : "Receive Project";

  /* ---------- Download attachments ---------- */
  const [downloadingMap, setDownloadingMap] = useState({});
  const [downloadingAllLatest, setDownloadingAllLatest] = useState(false);

  const downloadAllLatest = async () => {
    if (!shownAttachments?.length || downloadingAllLatest) return;

    setDownloadingAllLatest(true);
    try {
      const items = shownAttachments
        .map((f, idx) => {
          const name =
            typeof f === "string"
              ? f
              : f?.name ||
                f?.filename ||
                f?.originalname ||
                f?.url ||
                `Attachment ${idx + 1}`;

          const url = typeof f === "object" ? f?.url || f?.path : null;
          const id = typeof f === "object" ? f?.id : null;

          if (!url) return null; // ما نقدر ننزّل بدون رابط
          return { url, name, id };
        })
        .filter(Boolean);

      for (let i = 0; i < items.length; i++) {
        await startDownload(items[i], i);
        // فاصل صغير لتقليل احتمال الـ browser يعلق/يمنع
        await new Promise((r) => setTimeout(r, 150));
      }
    } finally {
      setDownloadingAllLatest(false);
    }
  };

  const isAbsoluteUrl = (u) => /^https?:\/\//i.test(String(u || ""));

  const resolveUrl = (u) => {
    if (!u) return null;
    const raw = String(u);
    if (isAbsoluteUrl(raw)) return raw;

    // If api.baseURL is empty, keep it relative (browser will use current origin).
    const base = String(API.defaults.baseURL || "").trim();
    if (!base) return raw;

    const cleanBase = base.replace(/\/$/, "");
    const cleanPath = raw.startsWith("/") ? raw : `/${raw}`;
    return `${cleanBase}${cleanPath}`;
  };

  const fileNameFromContentDisposition = (cd) => {
    if (!cd) return null;
    // filename*=UTF-8''... OR filename="..."
    const m = /filename\*=UTF-8''([^;]+)|filename="?([^";]+)"?/i.exec(cd);
    const v = m?.[1] || m?.[2];
    if (!v) return null;
    try {
      return decodeURIComponent(v);
    } catch {
      return v;
    }
  };

  const fileNameFromUrl = (u) => {
    try {
      const urlObj = new URL(u, window.location.href);
      const last = urlObj.pathname.split("/").filter(Boolean).pop();
      return last || null;
    } catch {
      const parts = String(u || "")
        .split("?")[0]
        .split("/");
      return parts.filter(Boolean).pop() || null;
    }
  };

  const startDownload = async ({ url, name, id }, idx) => {
    const numericId = id != null && /^\d+$/.test(String(id)) ? String(id) : null;
    const proxyPath =
      project?.id && numericId
        ? `/projects/${project.id}/files/${numericId}/download`
        : null;
    const resolvedExternal = resolveUrl(url);

    const key = String(id ?? `${name || "file"}-${idx}`);
    setDownloadingMap((m) => ({ ...m, [key]: true }));

    const fetchBlob = (target, client, headers) =>
      client.get(target, {
        responseType: "blob",
        headers,
      });

    try {
      let res;
      let nameSourceUrl = "";

      if (proxyPath) {
        try {
          res = await fetchBlob(
            proxyPath,
            API,
            token ? { authorization: `Bearer ${token}` } : undefined
          );
          nameSourceUrl = proxyPath;
        } catch {
          if (!resolvedExternal) throw new Error("no file url");
          const absolute = isAbsoluteUrl(resolvedExternal);
          res = await fetchBlob(
            resolvedExternal,
            absolute ? axios : API,
            !absolute && token ? { authorization: `Bearer ${token}` } : undefined
          );
          nameSourceUrl = resolvedExternal;
        }
      } else {
        if (!resolvedExternal) return;
        const absolute = isAbsoluteUrl(resolvedExternal);
        res = await fetchBlob(
          resolvedExternal,
          absolute ? axios : API,
          !absolute && token ? { authorization: `Bearer ${token}` } : undefined
        );
        nameSourceUrl = resolvedExternal;
      }

      const cd = res?.headers?.["content-disposition"];
      const fromHeader = fileNameFromContentDisposition(cd);
      const fromUrl = fileNameFromUrl(nameSourceUrl);
      const fileName = fromHeader || name || fromUrl || `attachment-${idx + 1}`;

      const blob = res?.data instanceof Blob ? res.data : new Blob([res.data]);
      const blobUrl = window.URL.createObjectURL(blob);

      const a = document.createElement("a");
      a.href = blobUrl;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(blobUrl);
    } catch (_) {
      toast?.error?.("Failed to download attachment.");
      try {
        if (resolvedExternal && isAbsoluteUrl(resolvedExternal)) {
          window.open(resolvedExternal, "_blank", "noopener,noreferrer");
        }
      } catch {}
    } finally {
      setDownloadingMap((m) => {
        const next = { ...m };
        delete next[key];
        return next;
      });
    }
  };

  // lock scroll
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  // Backend returns deliveries already grouped:
  // { id, sent_at, files: [ { file_name, file_url, file_size, id, ... } ] }
  const normalizeDelivery = (d, idx) => {
    const at = d?.sent_at ?? d?.sentAt ?? d?.at ?? null;

    const arr = Array.isArray(d?.files)
      ? d.files
      : Array.isArray(d?.attachments)
      ? d.attachments
      : [];

    const attachments = arr.map((f, i) => ({
      id: f?.id ?? `${idx}-${i}`,
      name:
        f?.file_name ??
        f?.name ??
        f?.filename ??
        f?.originalname ??
        `Attachment ${i + 1}`,
      url: f?.file_url ?? f?.url ?? f?.path ?? null,
      size: f?.file_size ?? f?.size ?? 0,
      senderId: f?.sender_id ?? f?.senderId ?? null,
    }));

    return {
      id: d?.id ?? (at ? new Date(at).toISOString() : `delivery-${idx}`),
      at,
      // optional fields (if you later add them in backend)
      notes: d?.notes ?? "",
      links: d?.links ?? {},
      attachments,
    };
  };

  const versions = (Array.isArray(deliveries) ? deliveries : [])
    .map(normalizeDelivery)
    .sort((a, b) => {
      const ta = a.at ? new Date(a.at).getTime() : 0;
      const tb = b.at ? new Date(b.at).getTime() : 0;
      return tb - ta;
    });

  const latest = (() => {
    if (!versions.length) return null;

    // If we know the freelancer id for this project, always prefer the latest delivery from that freelancer.
    if (freelancerId != null) {
      const fromFreelancer = versions.find((v) =>
        (v.attachments || []).some(
          (a) =>
            a?.senderId != null && String(a.senderId) === String(freelancerId)
        )
      );
      if (fromFreelancer) return fromFreelancer;
    }

    if (myId != null) {
      // Otherwise, prefer the most recent delivery that contains files NOT sent by me.
      const other = versions.find((v) =>
        (v.attachments || []).some(
          (a) => a?.senderId != null && String(a.senderId) !== String(myId)
        )
      );
      if (other) return other;
    }

    return versions[0] || null;
  })();

  const filterAttachmentsForDisplay = (atts) => {
    const arr = Array.isArray(atts) ? atts : [];
    if (freelancerId != null) {
      return arr.filter(
        (a) => !a?.senderId || String(a.senderId) === String(freelancerId)
      );
    }
    if (myId != null) {
      return arr.filter(
        (a) => !a?.senderId || String(a.senderId) !== String(myId)
      );
    }
    return arr;
  };

  const shownAttachments = latest
    ? filterAttachmentsForDisplay(latest.attachments)
    : [];

  const latestKey = latest ? String(latest.id ?? latest.at ?? "") : "";
  const historyVersions = latest
    ? versions.filter((v) => String(v.id ?? v.at ?? "") !== latestKey)
    : versions;

  // ✅ fetch حقيقي (زر Refresh كان بس يعمل spinner بدون fetch)
  useEffect(() => {
    if (!project?.id || !token) return;
    let alive = true;

    (async () => {
      try {
        setLoading(true);
        const { data } = await API.get(`/projects/${project.id}/deliveries`, {
          headers: { authorization: `Bearer ${token}` },
        });

        if (!alive) return;

        const list = Array.isArray(data?.deliveries)
          ? data.deliveries
          : Array.isArray(data?.data)
          ? data.data
          : Array.isArray(data)
          ? data
          : [];

        setDeliveries(list);
      } catch (_) {
      } finally {
        if (alive) setLoading(false);
      }
    })();

    return () => {
      alive = false;
    };
  }, [project?.id, token]);

  const refresh = async () => {
    if (!project?.id || !token) return;
    try {
      setLoading(true);
      const { data } = await API.get(`/projects/${project.id}/deliveries`, {
        headers: { authorization: `Bearer ${token}` },
      });

      const list = Array.isArray(data?.deliveries)
        ? data.deliveries
        : Array.isArray(data?.data)
        ? data.data
        : Array.isArray(data)
        ? data
        : [];

      setDeliveries(list);
    } catch (_) {
    } finally {
      setLoading(false);
    }
  };

  const approve = async () => {
    try {
      setSubmitting(true);
      await onApprove(project.id); // يستدعي PUT /projects/:id/approve :contentReference[oaicite:4]{index=4}
      toast?.success?.("Project approved ✅");
      onClose();
    } catch (err) {
      toast?.error?.(err?.response?.data?.message || "فشل اعتماد المشروع.");
    } finally {
      setSubmitting(false);
    }
  };

  const request = async () => {
    const msg = requestText.trim();
    if (!msg) return;
    if (!canRequest) {
      toast?.error?.("Request changes endpoint is not configured.");
      return;
    }

    try {
      setSubmitting(true);
      await onRequestChanges(project.id, msg);
      toast?.info?.("Change request sent ✉️");
      onClose();
    } catch (err) {
      toast?.error?.(
        err?.response?.data?.message || "فشل إرسال طلب التعديلات."
      );
    } finally {
      setSubmitting(false);
    }
  };

  return createPortal(
    <div className="fixed inset-0 z-[9999]">
      <div
        className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="absolute inset-0 flex items-center justify-center p-4">
        <div className="w-full max-w-2xl rounded-2xl bg-white shadow-xl overflow-hidden flex flex-col max-h-[85vh]">
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-slate-200">
            <div className="font-semibold text-slate-800">
              {headerTitle} — {project.title}
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-slate-100"
            >
              <X className="w-5 h-5 text-slate-500" />
            </button>
          </div>

          {/* Body */}
          <div className="p-5 space-y-5 flex-1 overflow-y-auto overscroll-contain">
            {mode !== "request" && (
              <section className="rounded-2xl bg-white p-4" style={ringStyle}>
                <div className="flex items-center justify-between">
                  <div className="font-medium text-slate-800">
                    Latest delivery
                  </div>
                  <button
                    className="inline-flex items-center gap-2 text-sm px-3 py-1.5 rounded-xl bg-white hover:bg-slate-50"
                    style={ringStyle}
                    onClick={refresh}
                    disabled={loading}
                    type="button"
                  >
                    <RefreshCw
                      className={`w-4 h-4 ${loading ? "animate-spin" : ""}`}
                    />
                    Refresh
                  </button>
                </div>

                {!latest ? (
                  <div className="text-sm text-slate-500 mt-3">
                    {loading ? "Loading..." : "No deliveries yet."}
                  </div>
                ) : (
                  <div className="mt-3 space-y-3">
                    <div className="text-xs text-slate-500">
                      Delivered on{" "}
                      {latest.at ? new Date(latest.at).toLocaleString() : "—"}
                    </div>

                    <div className="grid sm:grid-cols-2 gap-3">
                      <Field label="Primary">
                        {latest.links?.primary ? (
                          <a
                            className="text-sky-700 hover:underline break-all"
                            href={latest.links.primary}
                            target="_blank"
                            rel="noreferrer"
                          >
                            {latest.links.primary}
                          </a>
                        ) : (
                          <span className="text-slate-500 text-sm">—</span>
                        )}
                      </Field>

                      {latest.links?.secondary ? (
                        <Field label="Secondary">
                          <a
                            className="text-sky-700 hover:underline break-all"
                            href={latest.links.secondary}
                            target="_blank"
                            rel="noreferrer"
                          >
                            {latest.links.secondary}
                          </a>
                        </Field>
                      ) : null}
                    </div>

                    {latest.notes ? (
                      <Field label="Notes">
                        <div className="text-sm text-slate-700 whitespace-pre-wrap">
                          {latest.notes}
                        </div>
                      </Field>
                    ) : null}

                    <Field label="Attachments">
                      {shownAttachments?.length ? (
                        <>
                          <div className="mb-2 flex items-center justify-end">
                            <button
                              type="button"
                              onClick={downloadAllLatest}
                              disabled={downloadingAllLatest}
                              className="inline-flex items-center gap-2 h-9 px-3 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-xs"
                              style={ringStyle}
                              title="Download all"
                            >
                              {downloadingAllLatest ? (
                                <Loader2 className="w-4 h-4 animate-spin" />
                              ) : (
                                <Download className="w-4 h-4" />
                              )}
                              Download all
                            </button>
                          </div>

                          <ul className="space-y-2 text-sm text-slate-700 max-h-56 overflow-y-auto pr-1">
                            {shownAttachments.map((f, idx) => {
                              const name =
                                typeof f === "string"
                                  ? f
                                  : f?.name ||
                                    f?.filename ||
                                    f?.originalname ||
                                    f?.url ||
                                    `Attachment ${idx + 1}`;

                              const url =
                                typeof f === "object"
                                  ? f?.url || f?.path
                                  : null;
                              const openUrl = url ? resolveUrl(url) : null;
                              const id = typeof f === "object" ? f?.id : null;

                              const key = String(id ?? `${name}-${idx}`);
                              const isDownloading = !!downloadingMap[key];

                              return (
                                <li
                                  key={key}
                                  className="flex items-center justify-between gap-2"
                                >
                                  <div className="min-w-0">
                                    {openUrl ? (
                                      <a
                                        className="text-sky-700 hover:underline break-all"
                                        href={openUrl}
                                        target="_blank"
                                        rel="noreferrer"
                                        title="Open attachment"
                                      >
                                        {name}
                                      </a>
                                    ) : (
                                      <span className="break-all">{name}</span>
                                    )}
                                  </div>

                                  {openUrl ? (
                                    <button
                                      type="button"
                                      onClick={() =>
                                        startDownload(
                                          { url: openUrl, name, id },
                                          idx
                                        )
                                      }
                                      disabled={isDownloading}
                                      className="inline-flex items-center gap-2 h-9 px-3 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-xs shrink-0"
                                      style={ringStyle}
                                      title="Download"
                                    >
                                      {isDownloading ? (
                                        <Loader2 className="w-4 h-4 animate-spin" />
                                      ) : (
                                        <Download className="w-4 h-4" />
                                      )}
                                      Download
                                    </button>
                                  ) : null}
                                </li>
                              );
                            })}
                          </ul>
                        </>
                      ) : (
                        <span className="text-slate-500 text-sm">—</span>
                      )}
                    </Field>
                  </div>
                )}
              </section>
            )}

            {!isFilesMode && (
              <section className="rounded-2xl bg-white p-4" style={ringStyle}>
                {isRequestMode ? (
                  <>
                    <div className="text-sm text-slate-700 font-medium mb-2">
                      Request changes
                    </div>
                    <textarea
                      value={requestText}
                      onChange={(e) => setRequestText(e.target.value)}
                      placeholder="Briefly describe what needs to be changed..."
                      className="w-full px-3 py-2.5 rounded-xl bg-white text-sm outline-none min-h-[100px]"
                      style={ringStyle}
                    />
                    <div className="mt-2 flex items-center gap-2">
                      <button
                        disabled={!requestText.trim() || submitting}
                        onClick={request}
                        className="h-10 px-3 rounded-xl text-white text-sm inline-flex items-center gap-2"
                        style={{
                          backgroundColor: T.dark,
                          opacity: !requestText.trim() || submitting ? 0.75 : 1,
                        }}
                        type="button"
                      >
                        {submitting && (
                          <Loader2 className="w-4 h-4 animate-spin" />
                        )}
                        Send request
                      </button>
                      <button
                        type="button"
                        className="h-10 px-3 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-sm"
                        style={ringStyle}
                        onClick={onClose}
                        disabled={submitting}
                      >
                        Cancel
                      </button>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="flex items-center gap-2">
                      <button
                        disabled={!latest || submitting}
                        onClick={approve}
                        className="h-11 px-4 rounded-xl text-white text-sm inline-flex items-center gap-2"
                        style={{
                          backgroundColor: T.primary,
                          opacity: !latest || submitting ? 0.75 : 1,
                        }}
                        type="button"
                      >
                        <Check className="w-4 h-4" /> Approve
                      </button>

                      <button
                        type="button"
                        disabled={!latest || submitting || !canRequest}
                        onClick={() => setRequesting((v) => !v)}
                        className="h-11 px-4 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-sm inline-flex items-center gap-2"
                        style={ringStyle}
                      >
                        <Undo2 className="w-4 h-4" /> Request changes
                      </button>
                    </div>

                    {requesting ? (
                      <div className="mt-3">
                        <textarea
                          value={requestText}
                          onChange={(e) => setRequestText(e.target.value)}
                          placeholder="Briefly describe what needs to be changed..."
                          className="w-full px-3 py-2.5 rounded-xl bg-white text-sm outline-none min-h-[80px]"
                          style={ringStyle}
                        />
                        <div className="mt-2 flex items-center gap-2">
                          <button
                            disabled={!requestText.trim() || submitting}
                            onClick={request}
                            className="h-10 px-3 rounded-xl text-white text-sm"
                            style={{
                              backgroundColor: T.dark,
                              opacity:
                                !requestText.trim() || submitting ? 0.75 : 1,
                            }}
                            type="button"
                          >
                            Send request
                          </button>
                          <button
                            type="button"
                            className="h-10 px-3 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-sm"
                            style={ringStyle}
                            onClick={() => setRequesting(false)}
                            disabled={submitting}
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : null}
                  </>
                )}
              </section>
            )}
            {/* History */}
            {mode !== "request" && (
              <section className="rounded-2xl bg-white p-4" style={ringStyle}>
                <div className="font-medium text-slate-800">History</div>
                {historyVersions.length === 0 ? (
                  <div className="text-sm text-slate-500 mt-2">
                    {loading ? "Loading..." : "No history yet."}
                  </div>
                ) : (
                  <ol className="mt-3 space-y-3 max-h-[45vh] overflow-y-auto pr-1">
                    {historyVersions.map((v) => {
                      const list = filterAttachmentsForDisplay(v.attachments);
                      return (
                        <li
                          key={v.id || v.at}
                          className="rounded-xl bg-white p-3"
                          style={ringStyle}
                        >
                          <div className="text-xs text-slate-500">
                            {v.at ? new Date(v.at).toLocaleString() : "—"}
                          </div>

                          {v.notes ? (
                            <div className="mt-1 text-sm text-slate-700 whitespace-pre-wrap">
                              {v.notes}
                            </div>
                          ) : null}

                          <div className="mt-2 text-xs text-slate-500">
                            Attachments
                          </div>

                          {list?.length ? (
                            <ul className="mt-1 space-y-2 text-sm text-slate-700">
                              {list.map((f, idx) => {
                                const name =
                                  typeof f === "string"
                                    ? f
                                    : f?.name ||
                                      f?.filename ||
                                      f?.originalname ||
                                      f?.url ||
                                      `Attachment ${idx + 1}`;

                                const url =
                                  typeof f === "object"
                                    ? f?.url || f?.path
                                    : null;

                                const openUrl = url ? resolveUrl(url) : null;
                                const fid =
                                  typeof f === "object" ? f?.id : null;

                                const key = String(fid ?? `${name}-${idx}`);
                                const isDownloading = !!downloadingMap[key];

                                return (
                                  <li
                                    key={`${v.id || v.at}-${key}`}
                                    className="flex items-center justify-between gap-2"
                                  >
                                    <div className="min-w-0">
                                      {openUrl ? (
                                        <a
                                          className="text-sky-700 hover:underline break-all"
                                          href={openUrl}
                                          target="_blank"
                                          rel="noreferrer"
                                          title="Open attachment"
                                        >
                                          {name}
                                        </a>
                                      ) : (
                                        <span className="break-all">
                                          {name}
                                        </span>
                                      )}
                                    </div>

                                    {openUrl ? (
                                      <button
                                        type="button"
                                        onClick={() =>
                                          startDownload(
                                            { url: openUrl, name, id: fid },
                                            idx
                                          )
                                        }
                                        disabled={isDownloading}
                                        className="inline-flex items-center gap-2 h-9 px-3 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-xs shrink-0"
                                        style={ringStyle}
                                        title="Download"
                                      >
                                        {isDownloading ? (
                                          <Loader2 className="w-4 h-4 animate-spin" />
                                        ) : (
                                          <Download className="w-4 h-4" />
                                        )}
                                        Download
                                      </button>
                                    ) : null}
                                  </li>
                                );
                              })}
                            </ul>
                          ) : (
                            <div className="text-sm text-slate-500 mt-1">—</div>
                          )}
                        </li>
                      );
                    })}
                  </ol>
                )}
              </section>
            )}
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}

/* ===================== Client Applications Drawer ===================== */
function ClientApplicationsDrawer({
  project,
  applications,
  onClose,
  onAction,
  submitting,
}) {
  const formatStatus = (status) => {
    const key = String(status || "").toLowerCase();
    if (key === "pending_client_approval") return "Waiting for your decision";
    if (key === "active") return "Accepted";
    if (key === "rejected") return "Rejected";
    if (key === "not_chosen") return "Not chosen";
    return status || "Unknown";
  };

  const statusClasses = (status) => {
    const key = String(status || "").toLowerCase();
    if (key === "pending_client_approval")
      return "bg-amber-50 text-amber-700 border-amber-200";
    if (key === "active")
      return "bg-emerald-50 text-emerald-700 border-emerald-200";
    if (key === "rejected") return "bg-rose-50 text-rose-700 border-rose-200";
    if (key === "not_chosen")
      return "bg-slate-50 text-slate-600 border-slate-200";
    return "bg-slate-50 text-slate-600 border-slate-200";
  };

  return createPortal(
    <div className="fixed inset-0 z-[9999]">
      <div
        className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="absolute inset-0 flex items-center justify-center p-4">
        <div className="w-full max-w-2xl rounded-2xl bg-white shadow-xl overflow-hidden flex flex-col max-h-[85vh]">
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-slate-200">
            <div className="font-semibold text-slate-800">
              Freelancer applications — {project.title}
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-slate-100"
            >
              <X className="w-5 h-5 text-slate-500" />
            </button>
          </div>

          {/* Body */}
          <div className="p-5 space-y-4">
            {applications.length === 0 ? (
              <div className="text-sm text-slate-500">
                No freelancers have applied to this project yet.
              </div>
            ) : (
              <ul className="space-y-3">
                {applications.map((app) => {
                  const key = app.assignment_id ?? app.id;
                  const statusKey = String(app.status || "").toLowerCase();
                  const isPending = statusKey === "pending_client_approval";

                  return (
                    <li
                      key={key}
                      className="rounded-xl border border-slate-200 bg-white p-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
                    >
                      <div className="space-y-1">
                        <div className="font-medium text-slate-800">
                          {app.freelancer_name || "Freelancer"}
                          {app.freelancer_id && (
                            <span className="ml-2 text-xs text-slate-500">
                              # {app.freelancer_id}
                            </span>
                          )}
                        </div>
                        {app.freelancer_email && (
                          <div className="text-xs text-slate-500">
                            {app.freelancer_email}
                          </div>
                        )}
                        <div className="text-xs text-slate-500">
                          Applied:{" "}
                          {app.assigned_at
                            ? new Date(app.assigned_at).toLocaleString()
                            : "—"}
                        </div>
                        <div className="mt-1">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${statusClasses(
                              app.status
                            )}`}
                          >
                            {formatStatus(app.status)}
                          </span>
                        </div>
                      </div>

                      <div className="flex flex-row sm:flex-col gap-2 sm:items-end">
                        <button
                          type="button"
                          disabled={!isPending || submitting}
                          onClick={() => onAction(key, project.id, "accept")}
                          className={`inline-flex items-center justify-center gap-1.5 h-9 px-3 rounded-xl text-xs text-white ${
                            isPending && !submitting
                              ? "hover:shadow"
                              : "opacity-60 cursor-not-allowed"
                          }`}
                          style={{ backgroundColor: T.primary }}
                        >
                          {submitting && (
                            <Loader2 className="w-3 h-3 animate-spin" />
                          )}
                          <Check className="w-3 h-3" />
                          Accept
                        </button>
                        <button
                          type="button"
                          disabled={!isPending || submitting}
                          onClick={() => onAction(key, project.id, "reject")}
                          className={`inline-flex items-center justify-center gap-1.5 h-9 px-3 rounded-xl text-xs bg-white text-slate-700 ${
                            isPending && !submitting
                              ? "hover:bg-slate-50"
                              : "opacity-60 cursor-not-allowed"
                          }`}
                          style={ringStyle}
                        >
                          <X className="w-3 h-3" />
                          Reject
                        </button>
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}

/* ===================== Client Offers Drawer ===================== */
function ClientOffersDrawer({
  project,
  offers,
  onClose,
  onAction,
  submitting,
}) {
  const formatStatus = (status) => {
    const key = String(status || "").toLowerCase();
    if (key === "pending") return "Pending";
    if (key === "accepted") return "Accepted";
    if (key === "rejected") return "Rejected";
    if (key === "expired") return "Expired";
    return status || "Unknown";
  };

  const statusClasses = (status) => {
    const key = String(status || "").toLowerCase();
    if (key === "pending") return "bg-amber-50 text-amber-700 border-amber-200";
    if (key === "accepted")
      return "bg-emerald-50 text-emerald-700 border-emerald-200";
    if (key === "rejected") return "bg-rose-50 text-rose-700 border-rose-200";
    if (key === "expired")
      return "bg-slate-100 text-slate-700 border-slate-300";
    return "bg-slate-50 text-slate-600 border-slate-200";
  };

  return createPortal(
    <div className="fixed inset-0 z-[9999]">
      <div
        className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="absolute inset-0 flex items-center justify-center p-4">
        <div className="w-full max-w-2xl rounded-2xl bg-white shadow-xl overflow-hidden flex flex-col max-h-[85vh]">
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-slate-200">
            <div className="font-semibold text-slate-800">
              Offers — {project.title}
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-slate-100"
            >
              <X className="w-5 h-5 text-slate-500" />
            </button>
          </div>

          {/* Body */}
          <div className="p-5 space-y-4">
            {offers.length === 0 ? (
              <div className="text-sm text-slate-500">
                No offers submitted for this project yet.
              </div>
            ) : (
              <ul className="space-y-3">
                {offers.map((o) => {
                  const offerId = o.offer_id ?? o.offerId ?? o.id;
                  const freelancerId =
                    o.freelancer_id ?? o.freelancerId ?? o.user_id ?? o.userId;
                  const statusKey = String(o.offer_status || "").toLowerCase();
                  const isPending = statusKey === "pending";

                  return (
                    <li
                      key={offerId ?? `${freelancerId}-${o.submitted_at}`}
                      className="rounded-xl border border-slate-200 bg-white p-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
                    >
                      <div className="space-y-1">
                        {/* ✅ لا تعرض اسم الفريلانسَر — اعرض ID فقط */}
                        <div className="font-medium text-slate-800">
                          Freelancer ID:{" "}
                          <span className="font-semibold">
                            # {freelancerId ?? "—"}
                          </span>
                        </div>
                        <div className="text-xs text-slate-500">
                          Submitted:{" "}
                          {o.submitted_at
                            ? new Date(o.submitted_at).toLocaleString()
                            : "—"}
                        </div>
                        <div className="mt-1">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${statusClasses(
                              o.offer_status
                            )}`}
                          >
                            {formatStatus(o.offer_status)}
                          </span>
                        </div>
                      </div>

                      <div className="flex flex-col sm:items-end gap-2">
                        <div className="text-sm text-slate-700">
                          Offer:{" "}
                          <span className="font-semibold">
                            ${o.bid_amount ?? "—"}
                          </span>
                        </div>
                        <div className="flex gap-2 sm:justify-end">
                          <button
                            type="button"
                            disabled={!isPending || submitting}
                            onClick={() =>
                              onAction(offerId, project.id, "accept")
                            }
                            className={`inline-flex items-center justify-center gap-1.5 h-9 px-3 rounded-xl text-xs text-white ${
                              isPending && !submitting
                                ? "hover:shadow"
                                : "opacity-60 cursor-not-allowed"
                            }`}
                            style={{ backgroundColor: T.primary }}
                          >
                            {submitting && (
                              <Loader2 className="w-3 h-3 animate-spin" />
                            )}
                            <Check className="w-3 h-3" />
                            Accept
                          </button>
                          <button
                            type="button"
                            disabled={!isPending || submitting}
                            onClick={() =>
                              onAction(offerId, project.id, "reject")
                            }
                            className={`inline-flex items-center justify-center gap-1.5 h-9 px-3 rounded-xl text-xs bg-white text-slate-700 ${
                              isPending && !submitting
                                ? "hover:bg-slate-50"
                                : "opacity-60 cursor-not-allowed"
                            }`}
                            style={ringStyle}
                          >
                            <X className="w-3 h-3" />
                            Reject
                          </button>
                        </div>
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}

/* ===================== Freelancer Modal ===================== */
function DeliverModal({ project, onClose, onSubmit, submitting }) {
  const [category, setCategory] = useState(project.category || "programming");
  const [primaryLink, setPrimaryLink] = useState("");
  const [secondaryLink, setSecondaryLink] = useState("");
  const [notes, setNotes] = useState("");
  const [files, setFiles] = useState([]);
  const [confirmed, setConfirmed] = useState(false);

  const readOnlyCategory = !!project.category;
  const requiredOk = confirmed && files.length > 0;

  const MAX_FILES = 30;

  const totalMb = useMemo(() => {
    const bytes = files.reduce((s, f) => s + (f.size || 0), 0);
    return bytes / (1024 * 1024);
  }, [files]);

  const onPickFiles = (e) => {
    const picked = Array.from(e.target.files || []);

    setFiles((prev) => {
      const map = new Map(
        (prev || []).map((f) => [`${f.name}-${f.size}-${f.lastModified}`, f])
      );
      picked.forEach((f) =>
        map.set(`${f.name}-${f.size}-${f.lastModified}`, f)
      );
      return Array.from(map.values()).slice(0, MAX_FILES);
    });

    e.target.value = ""; // يسمح تختار نفس الملف مرة ثانية
  };

  const submit = (e) => {
    e.preventDefault();
    if (!requiredOk) return;
    onSubmit({
      category,
      notes,
      links: { primary: primaryLink, secondary: secondaryLink },
      checklist: { confirmed },
      files,
    });
  };

  const HeaderIcon = () => {
    if (category === "content")
      return <FileText className="w-5 h-5" style={{ color: T.dark }} />;
    if (category === "design")
      return <Palette className="w-5 h-5" style={{ color: T.dark }} />;
    return <Code className="w-5 h-5" style={{ color: T.dark }} />;
  };

  return createPortal(
    <div className="fixed inset-0 z-[9999]">
      <div
        className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="absolute inset-0 flex items-center justify-center p-4">
        <div className="w-full max-w-2xl rounded-2xl bg-white shadow-xl overflow-hidden flex flex-col max-h-[85vh]">
          {/* header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-slate-200">
            <div className="flex items-center gap-2">
              <HeaderIcon />
              <div className="font-semibold text-slate-800">
                Deliver Project — {project.title}
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-slate-100"
            >
              <X className="w-5 h-5 text-slate-500" />
            </button>
          </div>

          {/* body */}
          <form onSubmit={submit} className="p-5 space-y-5">
            {/* Attachments */}
            <div>
              <label className="text-sm text-slate-600">
                Attachments (optional)
              </label>

              <div className="mt-1.5 flex items-start gap-3">
                <label
                  className="inline-flex items-center gap-2 h-11 px-3 rounded-xl bg-white hover:bg-slate-50 cursor-pointer text-sm shrink-0"
                  style={ringStyle}
                >
                  Upload files
                  <input
                    type="file"
                    multiple
                    className="hidden"
                    onChange={onPickFiles}
                  />
                </label>

                {/* Summary + List */}
                <div className="flex-1 min-w-0">
                  {files.length > 0 ? (
                    <>
                      <div className="flex items-center justify-between gap-3 mb-2">
                        <div className="text-xs text-slate-600">
                          <span className="font-semibold text-slate-800">
                            {files.length}
                          </span>{" "}
                          files selected{" "}
                          <span className="text-slate-400">•</span>{" "}
                          <span className="font-semibold text-slate-800">
                            {totalMb.toFixed(2)} MB
                          </span>
                          {files.length >= MAX_FILES ? (
                            <span className="ml-2 text-[11px] text-amber-600">
                              (max {MAX_FILES})
                            </span>
                          ) : null}
                        </div>

                        <button
                          type="button"
                          onClick={() => setFiles([])}
                          className="text-xs text-rose-600 hover:underline"
                        >
                          Remove all
                        </button>
                      </div>

                      <div className="max-h-52 overflow-y-auto pr-1 space-y-1">
                        {files.map((f, i) => (
                          <div
                            key={`${f.name}-${f.size}-${f.lastModified}`}
                            className="flex items-center justify-between gap-2 rounded-lg border border-slate-200 px-2 py-1"
                          >
                            <div className="min-w-0 text-xs text-slate-700 truncate">
                              {f.name}
                            </div>
                            <button
                              type="button"
                              onClick={() =>
                                setFiles((prev) =>
                                  prev.filter((_, idx) => idx !== i)
                                )
                              }
                              className="text-xs text-rose-600 hover:underline shrink-0"
                            >
                              Remove
                            </button>
                          </div>
                        ))}
                      </div>
                    </>
                  ) : (
                    <div className="text-xs text-slate-500 pt-2">
                      You can upload multiple files.
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Confirm */}
            <label
              className="flex items-center gap-2 px-3 py-2 rounded-xl bg-white cursor-pointer"
              style={ringStyle}
            >
              <input
                type="checkbox"
                className="accent-emerald-600"
                checked={confirmed}
                onChange={(e) => setConfirmed(e.target.checked)}
              />
              <span className="text-sm text-slate-700">
                I confirm this delivery matches the project requirements.
              </span>
            </label>

            {/* Footer */}
            <div className="flex items-center justify-between pt-3 border-t border-slate-200">
              <div className="text-xs text-slate-500">
                Trusted links are preferred over large uploads.
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={onClose}
                  className="h-11 px-4 rounded-xl bg-white hover:bg-slate-50 text-slate-700 text-sm"
                  style={ringStyle}
                  disabled={submitting}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!requiredOk || submitting}
                  className="h-11 px-4 rounded-xl text-white text-sm inline-flex items-center gap-2"
                  style={{
                    backgroundColor: T.primary,
                    opacity: !requiredOk || submitting ? 0.75 : 1,
                  }}
                >
                  {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                  Submit Delivery
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>,
    document.body
  );
}

/* ---------- Small helpers ---------- */
function Field({ label, children }) {
  return (
    <div>
      <div className="text-xs text-slate-500">{label}</div>
      <div className="mt-1">{children}</div>
    </div>
  );
}
function capitalize(s) {
  return (s || "").charAt(0).toUpperCase() + (s || "").slice(1);
}

export {
  AdminProjects,
  ClientProjects,
  FreelancerProjects,
  ClientReviewDrawer,
  ClientApplicationsDrawer,
  ClientOffersDrawer,
  DeliverModal,
};
