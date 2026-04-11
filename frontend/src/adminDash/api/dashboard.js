// src/adminDash/api/dashboard.js
import API from "./axios.js";
import { Users, Briefcase, UserCheck, Wallet, ClipboardList, Lock, Clock, CheckCircle, DollarSign } from "lucide-react";

function pickArray(data, keys = []) {
  for (const k of keys) {
    const v = k ? data?.[k] : data;
    if (Array.isArray(v)) return v;
  }
  return [];
}

function toNum(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function formatMoney(n) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(n);
}

// Format amount as "number JD"
// Examples: 0 → "0 JD", 25 → "25 JD", 100.5 → "100.5 JD", 100.50 → "100.5 JD"
function formatAmountJD(n) {
  const num = Number.isFinite(+n) ? +n : 0;
  // Remove trailing zeros: 100.50 → "100.5", 25.00 → "25"
  const formatted = num % 1 === 0 
    ? num.toString() 
    : parseFloat(num.toFixed(3)).toString(); // Use 3 decimals for JOD, then parseFloat removes trailing zeros
  return `${formatted} JD`;
}

/* ===================== Client dashboard (عندك موجود) ===================== */
/* ===================== Client dashboard ===================== */
export async function fetchClientDashboard() {
  const [projectsRes, escrowRes, escrowSummaryRes, totalSpentRes, appsRes, offersRes] = await Promise.allSettled([
    API.get("/projects/myprojects"),
    // Fetch payment history
    API.get("/payments/client/history").catch(() => ({ data: { payments: [] } })),
    // Fetch escrow summary (held, released, refunded)
    API.get("/payments/client/escrow/summary").catch(() => ({ data: { summary: { held: 0, released: 0, refunded: 0 } } })),
    // Fetch total spent from payments table
    API.get("/payments/client/total-spent").catch(() => ({ data: { totalSpent: 0 } })),
    // Fetch applications and offers for pending decisions
    API.get("/projects/applications/my-projects").catch(() => ({ data: { applications: [] } })),
    API.get("/offers/my-projects/offers").catch(() => ({ data: { offers: [] } })),
  ]);

  const projects =
    projectsRes.status === "fulfilled"
      ? pickArray(projectsRes.value?.data, ["projects", "data", "rows", null])
      : [];

  // Get escrow data - we'll need to query it separately or get from payments
  // For now, we'll calculate from projects and payments data
  // Note: Escrow status might need a separate endpoint, but we can infer from project status and payments

  // ===== Projects in Escrow (escrow status = "held") =====
  // Projects with payment made but work not completed
  // Check if project has a payment record and is not completed
  const payments = escrowRes.status === "fulfilled" 
    ? pickArray(escrowRes.value?.data, ["payments", "data", "rows", null])
    : [];

  const applications =
    appsRes.status === "fulfilled"
      ? pickArray(appsRes.value?.data, ["applications", "data", "rows", null])
      : [];

  const offers =
    offersRes.status === "fulfilled"
      ? pickArray(offersRes.value?.data, ["offers", "data", "rows", null])
      : [];
  
  const projectsInEscrow = projects.filter((p) => {
    // Check if project has a payment record (payment made)
    const hasPayment = payments.some(
      (pay) => pay.reference_id === p.id && pay.purpose === "project" && pay.status === "paid"
    );
    
    // Project must have payment AND not be completed/delivered
    const status = String(p?.status || "").toLowerCase();
    const completionStatus = String(p?.completion_status || "").toLowerCase();
    const isNotCompleted = status !== "completed" && completionStatus !== "completed" && completionStatus !== "delivered";
    
    return hasPayment && isNotCompleted && (status === "in_progress" || status === "active");
  });

  // ===== Awaiting Delivery (project status = in_progress) =====
  const awaitingDelivery = projects.filter((p) => {
    const status = String(p?.status || "").toLowerCase();
    return status === "in_progress";
  });

  // ===== Awaiting Your Approval (project status = delivered) =====
  const awaitingApproval = projects.filter((p) => {
    const status = String(p?.status || "").toLowerCase();
    const completionStatus = String(p?.completion_status || "").toLowerCase();
    return status === "delivered" || completionStatus === "pending_review" || completionStatus === "delivered";
  });

  // ===== Completed Projects (escrow released OR project completed) =====
  const completedProjects = projects.filter((p) => {
    const status = String(p?.status || "").toLowerCase();
    const completionStatus = String(p?.completion_status || "").toLowerCase();
    return status === "completed" || completionStatus === "completed";
  });

  // ===== Total Spent (from payments table) =====
  // Get total spent from payments table (only paid status)
  const totalSpent = totalSpentRes.status === "fulfilled"
    ? toNum(totalSpentRes.value?.data?.totalSpent || 0)
    : 0;

  // ===== Escrow Summary (for Financial Overview card) =====
  // Get real escrow summary from backend
  const escrowSummary = escrowSummaryRes.status === "fulfilled"
    ? escrowSummaryRes.value?.data?.summary || { held: 0, released: 0, refunded: 0 }
    : { held: 0, released: 0, refunded: 0 };
  
  // Money in Escrow = SUM(escrow.amount WHERE status = 'held')
  const moneyInEscrow = toNum(escrowSummary.held || 0);
  
  // Total Released from Escrow = SUM(escrow.amount WHERE status = 'released')
  const totalReleasedFromEscrow = toNum(escrowSummary.released || 0);
  
  // Total Refunded = SUM(escrow.amount WHERE status = 'refunded')
  const totalRefunded = toNum(escrowSummary.refunded || 0);

  // ===== Stats cards =====
  const stats = [
    {
      id: "projects_in_escrow",
      title: "Projects in Escrow",
      value: projectsInEscrow.length,
      sub: "Payment made, work in progress",
      icon: Lock,
      accent: "bg-amber-50",
    },
    {
      id: "awaiting_delivery",
      title: "Awaiting Delivery",
      value: awaitingDelivery.length,
      sub: "Currently in progress",
      icon: Clock,
      accent: "bg-blue-50",
    },
    {
      id: "awaiting_approval",
      title: "Awaiting Your Approval",
      value: awaitingApproval.length,
      sub: "Delivered, needs review",
      icon: ClipboardList,
      accent: "bg-indigo-50",
    },
    {
      id: "completed_projects",
      title: "Completed Projects",
      value: completedProjects.length,
      sub: "Fully finished",
      icon: CheckCircle,
      accent: "bg-emerald-50",
    },
    {
      id: "total_spent",
      title: "Total Spent",
      value: formatAmountJD(totalSpent),
      sub: "All successful payments",
      icon: DollarSign,
      accent: "bg-slate-50",
    },
  ];

  // Financial overview data for the right panel
  const financialOverview = {
    moneyInEscrow,
    totalReleased: totalReleasedFromEscrow,
    totalRefunded,
  };

  // ===== Recent projects =====
  const recentProjects = [...projects]
    .sort((a, b) => {
      const da = new Date(a?.updated_at || a?.created_at || 0).getTime();
      const db = new Date(b?.updated_at || b?.created_at || 0).getTime();
      return db - da;
    })
    .slice(0, 6);

  // ===== Build Actionable Items (Priority Order) =====
  const actionableItems = [];

  // A) Approve Delivered Work (Priority 1)
  const deliveredProjects = projects.filter((p) => {
    const status = String(p?.status || "").toLowerCase();
    const completionStatus = String(p?.completion_status || "").toLowerCase();
    return status === "delivered" || completionStatus === "pending_review" || completionStatus === "delivered";
  });

  deliveredProjects.forEach((p) => {
    actionableItems.push({
      id: `approve_${p.id}`,
      type: "approve_delivery",
      priority: 1,
      title: "Review & approve delivery",
      projectTitle: p.title || "Untitled Project",
      projectId: p.id,
      reason: "Delivery submitted",
      amount: p.budget || p.amount_to_pay || null,
      actionLabel: "Approve",
      href: `/client/project/${p.id}`,
    });
  });

  // B) Release Escrow / Complete Payment Step (Priority 2)
  // Projects with escrow held AND ready for release (completed and approved)
  // Note: Escrow should only be released after project is completed (not just delivered)
  const projectsWithHeldEscrow = projects.filter((p) => {
    const hasPayment = payments.some(
      (pay) => pay.reference_id === p.id && pay.purpose === "project" && pay.status === "paid"
    );
    const status = String(p?.status || "").toLowerCase();
    const completionStatus = String(p?.completion_status || "").toLowerCase();
    // Project is completed (not just delivered) and has payment (escrow likely held)
    // Only show if project is fully completed, not just delivered (delivered needs approval first)
    return (
      hasPayment &&
      (status === "completed" || completionStatus === "completed") &&
      status !== "pending_payment" &&
      status !== "delivered" // Delivered projects need approval first, not escrow release
    );
  });

  projectsWithHeldEscrow.forEach((p) => {
    const projectPayment = payments.find(
      (pay) => pay.reference_id === p.id && pay.purpose === "project" && pay.status === "paid"
    );
    const amount = projectPayment?.amount || p.budget || p.amount_to_pay || 0;
    
    actionableItems.push({
      id: `release_${p.id}`,
      type: "release_escrow",
      priority: 2,
      title: `Release payment (${formatAmountJD(amount)})`,
      projectTitle: p.title || "Untitled Project",
      projectId: p.id,
      reason: "Escrow awaiting release",
      amount: amount,
      actionLabel: "Release",
      href: `/client/project/${p.id}`,
    });
  });

  // C) Respond to Freelancer Requests / Decisions (Priority 3)
  // Pending applications
  const pendingApplications = applications.filter(
    (a) => String(a?.status || "").toLowerCase() === "pending_client_approval"
  );

  pendingApplications.forEach((a) => {
    actionableItems.push({
      id: `decision_app_${a.id || a.assignment_id}`,
      type: "decision_required",
      priority: 3,
      title: "Decision required",
      projectTitle: a.project_title || a.projectTitle || "Project Application",
      projectId: a.project_id || a.projectId,
      reason: "Application waiting for your response",
      actionLabel: "View request",
      href: `/client/project/${a.project_id || a.projectId}`,
    });
  });

  // Pending offers
  const pendingOffers = offers.filter(
    (o) => String(o?.offer_status || o?.status || "").toLowerCase() === "pending"
  );

  pendingOffers.forEach((o, idx) => {
    actionableItems.push({
      id: `decision_offer_${o.id ?? o.offer_id ?? o.offerId ?? idx}`,
      type: "decision_required",
      priority: 3,
      title: "Decision required",
      projectTitle: o.project_title || o.projectTitle || "Project Offer",
      projectId: o.project_id || o.projectId,
      reason: "Offer waiting for your response",
      actionLabel: "View request",
      href: `/client/project/${o.project_id || o.projectId}`,
    });
  });

  // D) Fix Incomplete Payment / Checkout (Priority 4)
  // Projects created but not paid (status pending_payment or no payment record)
  const unpaidProjects = projects.filter((p) => {
    const status = String(p?.status || "").toLowerCase();
    const hasPayment = payments.some(
      (pay) => pay.reference_id === p.id && pay.purpose === "project" && pay.status === "paid"
    );
    // Project needs payment and doesn't have a paid payment record
    return (
      (status === "pending_payment" || (!hasPayment && p.project_type !== "bidding")) &&
      p.project_type !== "bidding" // Bidding projects don't require upfront payment
    );
  });

  unpaidProjects.forEach((p) => {
    actionableItems.push({
      id: `payment_${p.id}`,
      type: "complete_payment",
      priority: 4,
      title: "Complete payment to start work",
      projectTitle: p.title || "Untitled Project",
      projectId: p.id,
      reason: "Payment required to begin",
      amount: p.budget || p.amount_to_pay || 0,
      actionLabel: "Pay now",
      href: `/client/project/${p.id}`, // Or payment page if exists
    });
  });

  // Sort by priority and limit to 5 items
  const sortedActions = actionableItems
    .sort((a, b) => a.priority - b.priority)
    .slice(0, 5);

  // My projects: last 8, incomplete first (same idea as freelancer)
  const isCompleted = (p) => {
    const s = String(p?.status || "").toLowerCase();
    const c = String(p?.completion_status || "").toLowerCase();
    return s === "completed" || c === "completed" || c === "delivered";
  };
  const getProjectTime = (p) => {
    const raw = p?.updated_at ?? p?.updatedAt ?? p?.created_at ?? p?.createdAt ?? 0;
    return new Date(raw).getTime() || 0;
  };
  const myProjects = [...projects]
    .sort((a, b) => {
      const aDone = isCompleted(a);
      const bDone = isCompleted(b);
      if (aDone !== bDone) return aDone ? 1 : -1;
      return getProjectTime(b) - getProjectTime(a);
    })
    .slice(0, 8)
    .map((p) => {
      const budgetRaw = p?.budget ?? p?.amount_to_pay ?? p?.amountToPay;
      const dueRaw = p?.due ?? p?.deadline ?? p?.end_date ?? p?.updated_at;
      return {
        id: p?.id,
        title: p?.title,
        client: p?.assignee ?? p?.freelancer_name ?? p?.client_name ?? "",
        budget: budgetRaw != null ? String(budgetRaw) : "",
        status: p?.status,
        completion_status: p?.completion_status,
        due: dueRaw ? safeDate(dueRaw) : "",
        amount_to_pay: p?.amount_to_pay ?? p?.budget,
      };
    });

  return {
    stats,
    recentProjects,
    myProjects,
    actionableItems: sortedActions,
    financialOverview,
    attention: {
      pendingReviews: awaitingApproval.slice(0, 4),
    },
  };
}

/* ===================== Admin dashboard ===================== */
export async function fetchAdminDashboard() {
  const [projectsRes, freelancersRes, deactivatedRes, paymentsRes, tasksRes] =
    await Promise.allSettled([
      API.get("/projects/admin/projects"),
      API.get("/projects/admin/freelancers"),
      API.get("/users/deactivated-users"),
      API.get("/payments/admin/payments"),
      API.get("/tasks/admin"),
    ]);

  const projects =
    projectsRes.status === "fulfilled"
      ? pickArray(projectsRes.value?.data, ["projects", "data", "rows", null])
      : [];

  const freelancers =
    freelancersRes.status === "fulfilled"
      ? pickArray(freelancersRes.value?.data, ["freelancers", "users", "data", "rows", null])
      : [];

  const deactivatedUsers =
    deactivatedRes.status === "fulfilled"
      ? pickArray(deactivatedRes.value?.data, ["users", "deactivatedUsers", "data", "rows", null])
      : [];

  const payments =
    paymentsRes.status === "fulfilled"
      ? pickArray(paymentsRes.value?.data, ["payments", "data", "rows", null])
      : [];

  const tasks =
    tasksRes.status === "fulfilled"
      ? pickArray(tasksRes.value?.data, ["tasks", "data", "rows", null])
      : [];

  const totalRevenue = payments.reduce((sum, p) => {
    const amount =
      p?.amount ??
      p?.amount_paid ??
      p?.amountToPay ??
      p?.amount_to_pay ??
      p?.total ??
      p?.total_amount ??
      0;
    return sum + toNum(amount);
  }, 0);

  const topStats = [
    {
      id: "projects",
      title: "Projects",
      value: projects.length,
      sub: "All projects in the system",
      icon: Briefcase,
      accent: "bg-teal-50",
    },
    {
      id: "freelancers",
      title: "Freelancers",
      value: freelancers.length,
      sub: "Registered freelancers",
      icon: Users,
      accent: "bg-sky-50",
    },
    {
      id: "tasks",
      title: "Tasks",
      value: tasks.length,
      sub: "Tasks in the platform",
      icon: ClipboardList,
      accent: "bg-indigo-50",
    },
    {
      id: "revenue",
      title: "Total revenue",
      value: totalRevenue ? formatMoney(totalRevenue) : "—",
      sub: payments.length ? "From payments" : "No payments data",
      icon: Wallet,
      accent: "bg-emerald-50",
    },
  ];

  const pendingVerifications = deactivatedUsers.slice(0, 6).map((u) => {
    const name =
      u?.name ||
      u?.full_name ||
      u?.fullName ||
      [u?.first_name, u?.last_name].filter(Boolean).join(" ") ||
      "Unknown";
    const initials = name?.trim()?.charAt(0)?.toUpperCase() || "?";

    return {
      id: u?.id,
      name,
      email: u?.email,
      role: u?.role || u?.role_name || u?.roleName,
      initials,
    };
  });

  const revenuePoints = buildMonthlySeries(payments, 12);

  return { topStats, pendingVerifications, revenuePoints };
}

/* ===================== Freelancer dashboard ===================== */
export async function fetchFreelancerDashboard() {
  const [projectsRes, assignedTasksRes, openRes, subscriptionRes] = await Promise.allSettled([
    API.get("/projects/myprojects"),
    API.get("/tasks/freelancer/assigned"),
    API.get("/offers/projects/open"),
    API.get("/subscriptions/status"),
  ]);

  const projects =
    projectsRes.status === "fulfilled"
      ? pickArray(projectsRes.value?.data, ["projects", "data", "rows", null])
      : [];

  const assignedTasks =
    assignedTasksRes.status === "fulfilled"
      ? pickArray(assignedTasksRes.value?.data, ["tasks", "data", "rows", null])
      : [];

  // /offers/projects/open ممكن يفشل بسبب subscription/verification -> fallback
  let openProjects =
    openRes.status === "fulfilled"
      ? pickArray(openRes.value?.data, ["projects", "data", "rows", null])
      : [];

  if (!openProjects.length) {
    try {
      const poolRes = await API.get("/tasks/pool");
      openProjects = pickArray(poolRes?.data, ["tasks", "data", "rows", null]);
    } catch {
      // ignore
    }
  }

  function mapProjectToCard(p) {
    const budgetRaw = p?.budget ?? p?.amount_to_pay ?? p?.amountToPay;
    const dueRaw = p?.due ?? p?.deadline ?? p?.end_date ?? p?.updated_at;
    return {
      id: p?.id,
      title: p?.title,
      client:
        p?.client_name ||
        p?.clientName ||
        p?.client ||
        p?.user_name ||
        p?.owner_name,
      budget: budgetRaw != null ? String(budgetRaw) : "",
      status: p?.status,
      completion_status: p?.completion_status,
      due: dueRaw ? safeDate(dueRaw) : "",
      amount_to_pay: p?.amount_to_pay ?? p?.budget,
    };
  }

  const activeProjects = projects
    .filter((p) => {
      const s = String(p?.status || "").toLowerCase();
      return ["in_progress", "active", "running", "started"].includes(s);
    })
    .slice(0, 6)
    .map((p) => mapProjectToCard(p));

  // My projects: last 8, priority for incomplete (non-completed) first, then by date
  const isCompleted = (p) => {
    const s = String(p?.status || "").toLowerCase();
    const c = String(p?.completion_status || "").toLowerCase();
    return s === "completed" || c === "completed" || c === "delivered";
  };
  const getProjectTime = (p) => {
    const raw = p?.updated_at ?? p?.updatedAt ?? p?.created_at ?? p?.createdAt ?? 0;
    return new Date(raw).getTime() || 0;
  };
  const myProjects = [...projects]
    .sort((a, b) => {
      const aDone = isCompleted(a);
      const bDone = isCompleted(b);
      if (aDone !== bDone) return aDone ? 1 : -1; // incomplete first
      return getProjectTime(b) - getProjectTime(a); // then newest first
    })
    .slice(0, 8)
    .map((p) => mapProjectToCard(p));

  const latestClientProjects = openProjects
    .slice(0, 6)
    .map((p) => {
      const budgetRaw = p?.budget ?? p?.budget_max ?? p?.price ?? p?.amount_to_pay;
      return {
        id: p?.id,
        title: p?.title,
        type: p?.project_type || p?.type || p?.category || "—",
        budget: budgetRaw != null ? String(budgetRaw) : "—",
      };
    });

  const balanceCards = [
    {
      id: "active_projects",
      title: "Active projects",
      value: activeProjects.length,
      sub: "Currently running",
      icon: Briefcase,
      accent: "bg-cyan-50",
    },
    {
      id: "assigned_tasks",
      title: "Assigned tasks",
      value: assignedTasks.length,
      sub: "Tasks assigned to you",
      icon: ClipboardList,
      accent: "bg-indigo-50",
    },
    {
      id: "open_opportunities",
      title: "Open opportunities",
      value: openProjects.length,
      sub: "Projects you can bid on",
      icon: UserCheck,
      accent: "bg-amber-50",
    },
  ];

  const subscriptionStatus = subscriptionRes.status === "fulfilled"
    ? subscriptionRes.value?.data
    : null;

  return { balanceCards, activeProjects, myProjects, latestClientProjects, subscriptionStatus };
}

/* ===================== Helpers ===================== */
function safeDate(d) {
  try {
    return new Date(d).toLocaleDateString();
  } catch {
    return "";
  }
}

function buildMonthlySeries(items, months = 12) {
  const now = new Date();
  const keys = [];
  for (let i = months - 1; i >= 0; i--) {
    const dt = new Date(now.getFullYear(), now.getMonth() - i, 1);
    keys.push(`${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}`);
  }

  const sums = new Map(keys.map((k) => [k, 0]));

  const getDate = (x) =>
    x?.created_at || x?.createdAt || x?.paid_at || x?.paidAt || x?.updated_at || x?.updatedAt;

  const getAmount = (x) =>
    x?.amount ??
    x?.amount_paid ??
    x?.amountToPay ??
    x?.amount_to_pay ??
    x?.total ??
    x?.total_amount ??
    x?.price ??
    0;

  for (const item of Array.isArray(items) ? items : []) {
    const d = getDate(item);
    if (!d) continue;
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) continue;

    const k = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}`;
    if (!sums.has(k)) continue;

    sums.set(k, (sums.get(k) || 0) + toNum(getAmount(item)));
  }

  return keys.map((k) => Math.round(sums.get(k) || 0));
}
