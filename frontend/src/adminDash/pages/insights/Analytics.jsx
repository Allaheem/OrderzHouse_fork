import React, { useEffect, useState, useCallback, useMemo } from "react";
import API from "../../api/axios.js";
import { useSelector } from "react-redux";
import {
  Users,
  User,
  FolderKanban,
  AlertCircle,
  CreditCard,
  TrendingUp,
  MapPin,
  RefreshCw,
  Zap,
  FileCheck,
  DollarSign,
  ChevronRight,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart as RechartsPie,
  Pie,
  Cell,
} from "recharts";

// ——— Theme: Modern soft dashboard ———
const PAGE_BG = "#F6F8FB";
const PRIMARY = "#f97316";
const PRIMARY_SOFT = "#fed7aa";
const BLUE_SERIES = "#3b82f6";
const CARD_CLASS =
  "bg-white rounded-2xl border border-slate-200/60 shadow-sm overflow-hidden";

// ——— UI: Skeleton ———
function Skeleton({ className = "" }) {
  return (
    <div
      className={`animate-pulse rounded-xl bg-slate-100 ${className}`}
      style={{ minHeight: "60px" }}
    />
  );
}

// ——— UI: KPI Card (صغير، مثل الصورة المرجعية) ———
function KPICard({ icon: Icon, subtitle, value, trend, highlight }) {
  return (
    <div
      className={`${CARD_CLASS} p-4 flex flex-col gap-1 min-h-[88px] justify-center`}
    >
      {Icon && (
        <div className="w-8 h-8 rounded-xl bg-slate-100 grid place-items-center text-slate-500 shrink-0">
          <Icon className="w-4 h-4" />
        </div>
      )}
      <p className="text-xs font-medium text-slate-500">{subtitle}</p>
      <p
        className="text-lg font-bold text-slate-900 tabular-nums"
        style={highlight ? { color: PRIMARY } : {}}
      >
        {value ?? "—"}
      </p>
      {trend != null && trend !== "" && (
        <span
          className={`inline-flex items-center gap-0.5 text-xs font-medium ${
            Number(trend) >= 0 ? "text-emerald-600" : "text-red-500"
          }`}
        >
          {Number(trend) >= 0 ? "↑" : "↓"} {Math.abs(Number(trend))}%
        </span>
      )}
    </div>
  );
}

// ——— UI: Section Card ———
function SectionCard({ title, actionLabel, children, className = "" }) {
  return (
    <div className={`${CARD_CLASS} flex flex-col ${className}`}>
      <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between gap-2">
        <h2 className="text-sm font-bold text-slate-800">{title}</h2>
        {actionLabel && (
          <span className="text-xs font-semibold text-slate-500">
            {actionLabel}
          </span>
        )}
      </div>
      <div className="p-4 flex-1 min-h-0">{children}</div>
    </div>
  );
}

// ——— UI: Chart Tooltip ———
function ChartTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white rounded-xl border border-slate-200 shadow-lg px-3 py-2 text-xs">
      <p className="font-semibold text-slate-700 mb-1">
        {label
          ? new Date(label).toLocaleDateString("en", {
              month: "short",
              day: "numeric",
              year: "numeric",
            })
          : ""}
      </p>
      {payload.map((p) => (
        <p key={p.name} className="text-slate-600">
          {p.name === "projects" ? "Projects" : "Payments"}:{" "}
          {p.name === "payments" ? `${p.value} JD` : p.value}
        </p>
      ))}
    </div>
  );
}

export default function Analytics() {
  const { userData, token } = useSelector((s) => s.auth);
  const isAdmin = Number(userData?.role_id) === 1;

  const [range, setRange] = useState("30d");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [data, setData] = useState(null);

  const [kpisData, setKpisData] = useState(null);
  const [kpisLoading, setKpisLoading] = useState(true);
  const [kpisError, setKpisError] = useState(null);

  const fetchAnalytics = useCallback(async () => {
    setLoading(true);
    setError(null);
    if (!token) {
      setLoading(false);
      setError("Please log in to view analytics.");
      return;
    }
    try {
      const { data: res } = await API.get("/analytics/admin", {
        params: { range },
      });
      setData(res);
    } catch (err) {
      console.error("Analytics fetch:", err);
      const msg =
        err.response?.data?.message ||
        (err.response?.status === 403
          ? "Access denied. Admin only."
          : err.response?.status === 404
            ? "Analytics API not found (404). Ensure the backend is running and includes the /analytics routes."
            : "Failed to load analytics.");
      setError(msg);
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [token, range]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  const fetchKpis = useCallback(() => {
    if (!token) {
      setKpisLoading(false);
      return;
    }
    setKpisLoading(true);
    setKpisError(null);
    API.get("/analytics/kpis")
      .then(({ data: res }) => {
        setKpisData(res);
      })
      .catch((err) => {
        const msg =
          err.response?.data?.message ||
          (err.response?.status === 403
            ? "Access denied. Admin only."
            : err.response?.status === 401
              ? "Please log in again."
              : err.response?.status === 404
                ? "Analytics API not found (404). Ensure the backend is running and includes the /analytics routes."
                : err.message || "Failed to load KPIs");
        setKpisError(msg);
        setKpisData(null);
      })
      .finally(() => {
        setKpisLoading(false);
      });
  }, [token]);

  useEffect(() => {
    fetchKpis();
  }, [fetchKpis]);

  const handleRefresh = useCallback(() => {
    fetchAnalytics();
    fetchKpis();
  }, [fetchAnalytics, fetchKpis]);

  if (!isAdmin) {
    return (
      <div
        className="min-h-screen flex items-center justify-center"
        style={{ backgroundColor: PAGE_BG }}
      >
        <div className={`${CARD_CLASS} p-6 max-w-md`}>
          <p className="text-slate-600">
            Only administrators can access Analytics.
          </p>
        </div>
      </div>
    );
  }

  const rangeOptions = [
    { value: "7d", label: "7d" },
    { value: "30d", label: "30d" },
    { value: "90d", label: "90d" },
  ];

  const kpis = data?.kpis;
  const timeseries = data?.timeseries;
  const byStatus = data?.byStatus || [];
  const byType = data?.byType || [];
  const byCountry = data?.byCountry || [];
  const topProjects = data?.topProjects || [];
  const topCategories = data?.topCategories || [];

  const projectsByDay = timeseries?.projectsByDay || [];
  const paymentsByDay = timeseries?.paymentsByDay || [];

  const combinedSeries = useMemo(() => {
    const byDate = {};
    projectsByDay.forEach(({ date, count }) => {
      byDate[date] = { ...(byDate[date] || {}), date, projects: count };
    });
    paymentsByDay.forEach(({ date, total }) => {
      byDate[date] = {
        ...(byDate[date] || {}),
        date,
        payments: Math.round(total),
      };
    });
    return Object.values(byDate).sort(
      (a, b) => new Date(a.date) - new Date(b.date)
    );
  }, [projectsByDay, paymentsByDay]);

  const completionRate =
    kpis?.projectsTotal > 0 && data?.byStatus?.length
      ? Math.round(
          ((byStatus.find((s) =>
            String(s.status).toLowerCase() === "completed"
          )?.count || 0) /
            kpis.projectsTotal) *
            100
        )
      : 0;

  const CHART_COLORS = [PRIMARY, "#ea580c", "#c2410c", "#9a3412", "#7c2d12"];

  // ——— Goals (مشتقة من KPIs للعرض البصري) ———
  const goals = useMemo(() => {
    const projects = Number(kpisData?.projects ?? 0) || 0;
    const payments = Number(kpisData?.totalPaid ?? 0) || 0;
    const freelancers = Number(kpisData?.freelancers ?? 0) || 0;
    return [
      {
        label: "Projects this period",
        current: projects,
        target: Math.max(projects + 20, 50),
      },
      {
        label: "Active freelancers",
        current: freelancers,
        target: Math.max(freelancers + 10, 30),
      },
      {
        label: "Payments (JD)",
        current: Math.round(payments),
        target: Math.max(Math.round(payments) + 100, 200),
      },
    ];
  }, [kpisData?.projects, kpisData?.totalPaid, kpisData?.freelancers]);

  return (
    <div
      className="min-h-screen pb-8"
      style={{ backgroundColor: PAGE_BG }}
    >
      <div className="max-w-[1600px] mx-auto px-4 sm:px-6 space-y-6 pt-6">
        {/* ——— 1) Header (مثل الصورة المرجعية) ——— */}
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-slate-900">
              Analytics Dashboard
            </h1>
            <p className="text-sm text-slate-500 mt-0.5">
              Platform overview and key metrics
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex rounded-xl bg-white border border-slate-200/80 p-0.5 shadow-sm">
              {rangeOptions.map((opt) => (
                <button
                  key={opt.value}
                  onClick={() => setRange(opt.value)}
                  className={`px-3 py-2 rounded-lg text-sm font-medium transition ${
                    range === opt.value
                      ? "text-white shadow-sm"
                      : "text-slate-600 hover:bg-slate-50"
                  }`}
                  style={
                    range === opt.value ? { backgroundColor: PRIMARY } : {}
                  }
                >
                  {opt.label}
                </button>
              ))}
            </div>
            <button
              type="button"
              onClick={handleRefresh}
              className="p-2 rounded-xl bg-white border border-slate-200/80 shadow-sm text-slate-600 hover:bg-slate-50 hover:text-slate-900 transition"
              title="Refresh"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
            {userData?.avatar_url ? (
              <img
                src={userData.avatar_url}
                alt=""
                className="w-9 h-9 rounded-full object-cover border border-slate-200"
              />
            ) : (
              <div className="w-9 h-9 rounded-full bg-slate-200 flex items-center justify-center">
                <User className="w-4 h-4 text-slate-500" />
              </div>
            )}
          </div>
        </header>

        {/* ——— 2) صف KPI: 5 كروت ——— */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
          {kpisLoading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className={CARD_CLASS} style={{ minHeight: "88px" }}>
                <Skeleton className="h-full rounded-2xl" />
              </div>
            ))
          ) : kpisError ? (
            <div className="col-span-2 sm:col-span-3 lg:col-span-5 rounded-2xl bg-white border border-slate-200 p-5 flex flex-col items-center justify-center gap-3 text-center">
              <p className="text-slate-600 text-sm">{kpisError}</p>
              <button
                type="button"
                onClick={() => fetchKpis()}
                className="px-4 py-2 rounded-xl text-sm font-semibold text-white hover:opacity-90 transition"
                style={{ backgroundColor: PRIMARY }}
              >
                Retry
              </button>
            </div>
          ) : (
            <>
              <KPICard
                icon={Users}
                subtitle="Total Freelancers"
                value={
                  kpisData?.freelancers != null
                    ? Number(kpisData.freelancers).toLocaleString()
                    : null
                }
              />
              <KPICard
                icon={User}
                subtitle="Total Clients"
                value={
                  kpisData?.clients != null
                    ? Number(kpisData.clients).toLocaleString()
                    : null
                }
              />
              <KPICard
                icon={FolderKanban}
                subtitle="Total Projects"
                value={
                  kpisData?.projects != null
                    ? Number(kpisData.projects).toLocaleString()
                    : null
                }
              />
              <KPICard
                icon={CreditCard}
                subtitle="Total Paid"
                value={
                  kpisData?.totalPaid != null
                    ? `${Number(kpisData.totalPaid).toLocaleString("en-US", {
                        minimumFractionDigits: 0,
                        maximumFractionDigits: 2,
                      })} ${kpisData.currency || "JD"}`
                    : null
                }
                highlight
              />
              <KPICard
                icon={TrendingUp}
                subtitle="Completion rate"
                value={completionRate != null ? `${completionRate}%` : "—"}
              />
            </>
          )}
        </div>

        {/* ——— رسالة الخطأ ——— */}
        {error && (
          <div className="rounded-2xl bg-amber-50 border border-amber-200/80 p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div className="text-amber-800 text-sm min-w-0">
              <p className="font-medium">{error}</p>
              <p className="mt-1 text-amber-700/90 text-xs">
                تأكد من تشغيل الـ Backend وأنك مسجّل كـ Admin. جرّب تحديث الصفحة.
              </p>
            </div>
          </div>
        )}

        {/* ——— 3) المحتوى الرئيسي: بطاقة كبيرة + Sidebar ——— */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          {/* ——— البطاقة الرئيسية: Platform Activity Overview ——— */}
          <div className="xl:col-span-2">
            <div className={CARD_CLASS}>
              <div className="p-4 sm:p-5 flex flex-wrap items-start justify-between gap-4 border-b border-slate-100">
                <div>
                  <h2 className="text-base font-bold text-slate-800">
                    Platform Activity Overview
                  </h2>
                  <p className="text-sm text-slate-500 mt-0.5">
                    {range === "7d"
                      ? "Last 7 days"
                      : range === "30d"
                        ? "Last 30 days"
                        : "Last 90 days"}
                  </p>
                </div>
                <div className="flex items-center gap-3 flex-wrap">
                  <div className="flex items-center gap-1.5">
                    <span
                      className="w-2.5 h-2.5 rounded-full shrink-0"
                      style={{ backgroundColor: BLUE_SERIES }}
                    />
                    <span className="text-xs font-medium text-slate-600">
                      Projects
                    </span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span
                      className="w-2.5 h-2.5 rounded-full shrink-0"
                      style={{ backgroundColor: PRIMARY }}
                    />
                    <span className="text-xs font-medium text-slate-600">
                      Payments
                    </span>
                  </div>
                </div>
              </div>
              <div className="p-4 sm:p-5 flex flex-col lg:flex-row gap-4">
                <div className="flex-1 min-h-[280px]">
                  {loading ? (
                    <Skeleton className="h-[280px] rounded-xl" />
                  ) : combinedSeries.length > 0 ? (
                    <ResponsiveContainer width="100%" height={280}>
                      <BarChart
                        data={combinedSeries}
                        margin={{
                          top: 12,
                          right: 12,
                          left: 0,
                          bottom: 0,
                        }}
                      >
                        <CartesianGrid
                          strokeDasharray="3 3"
                          stroke="#e2e8f0"
                          horizontal
                          vertical={false}
                        />
                        <XAxis
                          dataKey="date"
                          tick={{ fontSize: 11, fill: "#64748b" }}
                          tickFormatter={(v) =>
                            new Date(v).toLocaleDateString("en", {
                              month: "short",
                              day: "numeric",
                            })
                          }
                        />
                        <YAxis
                          yAxisId="L"
                          tick={{ fontSize: 11, fill: "#64748b" }}
                        />
                        <YAxis
                          yAxisId="R"
                          orientation="right"
                          tick={{ fontSize: 11, fill: "#64748b" }}
                        />
                        <Tooltip content={<ChartTooltip />} />
                        <Bar
                          yAxisId="L"
                          dataKey="projects"
                          fill={BLUE_SERIES}
                          radius={[4, 4, 0, 0]}
                          name="projects"
                        />
                        <Bar
                          yAxisId="R"
                          dataKey="payments"
                          fill={PRIMARY}
                          radius={[4, 4, 0, 0]}
                          name="payments"
                        />
                      </BarChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-[280px] flex items-center justify-center text-slate-400 text-sm">
                      No data for this period
                    </div>
                  )}
                </div>
                {/* عمود إحصائيات صغير داخل البطاقة (مثل الصورة) */}
                <div className="lg:w-44 shrink-0 space-y-3 border-t lg:border-t-0 lg:border-l border-slate-100 pt-4 lg:pt-0 lg:pl-4">
                  <div>
                    <p className="text-xs text-slate-500">Total paid</p>
                    <p className="text-sm font-bold text-slate-900 tabular-nums">
                      {kpisData?.totalPaid != null
                        ? `${Number(kpisData.totalPaid).toLocaleString("en-US", {
                            maximumFractionDigits: 0,
                          })} ${kpisData.currency || "JD"}`
                        : "—"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Total projects</p>
                    <p className="text-sm font-bold text-slate-900 tabular-nums">
                      {kpisData?.projects != null
                        ? Number(kpisData.projects).toLocaleString()
                        : "—"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Escrow held</p>
                    <p className="text-sm font-bold text-slate-900 tabular-nums">
                      {kpisData?.escrowHeld != null
                        ? `${Number(kpisData.escrowHeld).toLocaleString()} ${kpisData.currency || "JD"}`
                        : "—"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Payments count</p>
                    <p className="text-sm font-bold text-slate-900 tabular-nums">
                      {kpisData?.paymentsCount != null
                        ? Number(kpisData.paymentsCount).toLocaleString()
                        : "—"}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ——— العمود الأيمن: Quick Actions + Insights + Payment history ——— */}
          <div className="xl:col-span-1 space-y-4">
            {/* A) Admin Quick Actions */}
            <SectionCard title="Admin Quick Actions">
              <div className="grid grid-cols-2 gap-2">
                {[
                  { label: "Pending approvals", icon: FileCheck },
                  { label: "Manage payouts", icon: DollarSign },
                  { label: "Review disputes", icon: AlertCircle },
                  { label: "View users", icon: Users },
                  { label: "Export report", icon: Zap },
                  { label: "More", icon: ChevronRight },
                ].map(({ label, icon: Icon }) => (
                  <button
                    key={label}
                    type="button"
                    className="flex items-center gap-2 px-3 py-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-100 text-slate-700 text-xs font-medium transition"
                  >
                    <Icon className="w-3.5 h-3.5 shrink-0" />
                    <span className="truncate">{label}</span>
                  </button>
                ))}
              </div>
            </SectionCard>

            {/* B) Quick insights (top projects) */}
            <SectionCard title="Quick insights" actionLabel="View all">
              {loading ? (
                <Skeleton className="h-28 rounded-xl" />
              ) : topProjects.length === 0 ? (
                <p className="text-slate-400 text-sm py-2">
                  No projects in range
                </p>
              ) : (
                <ul className="space-y-2 max-h-40 overflow-y-auto">
                  {topProjects.slice(0, 5).map((p) => (
                    <li
                      key={p.id}
                      className="flex items-center justify-between gap-2 text-sm py-1 border-b border-slate-50 last:border-0"
                    >
                      <span
                        className="truncate flex-1 text-slate-700"
                        title={p.title}
                      >
                        {p.title || `#${p.id}`}
                      </span>
                      <span className="text-slate-500 text-xs shrink-0">
                        {p.applications ?? 0} apps
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </SectionCard>

            {/* C) Payment history */}
            <SectionCard title="Payment history" actionLabel="View all">
              {loading ? (
                <Skeleton className="h-28 rounded-xl" />
              ) : topProjects.length === 0 ? (
                <div className="py-6 text-center">
                  <CreditCard className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                  <p className="text-slate-400 text-sm">No activity yet</p>
                </div>
              ) : (
                <ul className="space-y-2 max-h-40 overflow-y-auto">
                  {topProjects.slice(0, 5).map((p) => (
                    <li
                      key={p.id}
                      className="flex items-center justify-between gap-2 text-sm py-1.5 border-b border-slate-50 last:border-0"
                    >
                      <span
                        className="truncate flex-1 text-slate-700"
                        title={p.title}
                      >
                        {p.title || `Project #${p.id}`}
                      </span>
                      <span
                        className="font-semibold text-slate-900 shrink-0"
                        style={{ color: PRIMARY }}
                      >
                        {p.budget != null
                          ? `${p.budget} JD`
                          : `${p.applications ?? 0}`}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </SectionCard>
          </div>
        </div>

        {/* ——— 4) الصف الأوسط: Donut + Users by country + Platform health + Goal tracker ——— */}
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {/* A) Projects distribution (Donut) */}
          <SectionCard title="Projects distribution">
            {loading ? (
              <Skeleton className="h-48 rounded-xl" />
            ) : byStatus.length === 0 ? (
              <div className="flex items-center justify-center h-40 text-slate-400 text-sm">
                No status data
              </div>
            ) : (
              <div className="flex gap-3 items-center">
                <div className="w-28 h-28 shrink-0">
                  <ResponsiveContainer width="100%" height="100%">
                    <RechartsPie>
                      <Pie
                        data={byStatus.map((s) => ({
                          name: String(s.status),
                          value: Number(s.count),
                        }))}
                        cx="50%"
                        cy="50%"
                        innerRadius={24}
                        outerRadius={40}
                        paddingAngle={2}
                        dataKey="value"
                        nameKey="name"
                      >
                        {byStatus.map((entry, i) => (
                          <Cell
                            key={entry.status}
                            fill={CHART_COLORS[i % CHART_COLORS.length]}
                          />
                        ))}
                      </Pie>
                      <Tooltip formatter={(v) => [v, ""]} />
                    </RechartsPie>
                  </ResponsiveContainer>
                </div>
                <ul className="space-y-1.5 flex-1 min-w-0">
                  {byStatus.map((s, i) => {
                    const total = byStatus.reduce(
                      (sum, x) => sum + Number(x.count || 0),
                      0
                    );
                    const pct =
                      total > 0
                        ? Math.round((Number(s.count) / total) * 100)
                        : 0;
                    return (
                      <li
                        key={s.status}
                        className="flex items-center gap-2 text-xs"
                      >
                        <span
                          className="w-2.5 h-2.5 rounded-full shrink-0"
                          style={{
                            backgroundColor:
                              CHART_COLORS[i % CHART_COLORS.length],
                          }}
                        />
                        <span className="truncate text-slate-700">
                          {String(s.status)}
                        </span>
                        <span className="font-semibold text-slate-900 shrink-0">
                          {s.count} ({pct}%)
                        </span>
                      </li>
                    );
                  })}
                </ul>
              </div>
            )}
          </SectionCard>

          {/* B) Users by country */}
          <SectionCard title="Users by country">
            {loading ? (
              <Skeleton className="h-48 rounded-xl" />
            ) : byCountry.length === 0 ? (
              <div className="flex items-center justify-center h-40 text-slate-400 text-sm">
                No country data
              </div>
            ) : (
              <div className="flex gap-3">
                <ul className="space-y-2 flex-1 min-w-0 max-h-44 overflow-y-auto">
                  {byCountry.slice(0, 8).map((row) => {
                    const total = byCountry.reduce(
                      (s, r) => s + (r.count || 0),
                      0
                    );
                    const pct =
                      total > 0 ? Math.round((row.count / total) * 100) : 0;
                    const barPct =
                      total > 0
                        ? Math.min(
                            100,
                            (row.count / (byCountry[0]?.count || 1)) * 100
                          )
                        : 0;
                    return (
                      <li
                        key={row.country}
                        className="flex items-center gap-2 text-xs"
                      >
                        <span className="truncate text-slate-700 flex-1">
                          {row.country}
                        </span>
                        <div
                          className="h-1.5 rounded-full bg-slate-100 overflow-hidden flex-1 max-w-[60px]"
                          style={{ minWidth: 40 }}
                        >
                          <div
                            className="h-full rounded-full bg-emerald-400/80"
                            style={{ width: `${barPct}%` }}
                          />
                        </div>
                        <span className="font-semibold text-slate-900 w-8 text-right shrink-0">
                          {pct}%
                        </span>
                      </li>
                    );
                  })}
                </ul>
                <div
                  className="w-14 h-14 rounded-xl flex items-center justify-center shrink-0 bg-slate-50 border border-slate-100"
                  aria-hidden
                >
                  <MapPin className="w-6 h-6 text-slate-300" />
                </div>
              </div>
            )}
          </SectionCard>

          {/* C) Platform health (Gauge: completion rate) */}
          <SectionCard title="Platform health">
            {loading ? (
              <Skeleton className="h-48 rounded-xl" />
            ) : (
              <div className="flex flex-col items-center justify-center py-2">
                <div className="relative w-28 h-14">
                  <ResponsiveContainer width="100%" height="100%">
                    <RechartsPie>
                      <Pie
                        data={[
                          {
                            name: "done",
                            value: Math.min(100, completionRate),
                            fill: PRIMARY,
                          },
                          {
                            name: "rest",
                            value: Math.max(0, 100 - completionRate),
                            fill: "#e2e8f0",
                          },
                        ]}
                        cx="50%"
                        cy="100%"
                        startAngle={180}
                        endAngle={0}
                        innerRadius={28}
                        outerRadius={42}
                        dataKey="value"
                      >
                        <Cell key="done" fill={PRIMARY} />
                        <Cell key="rest" fill="#e2e8f0" />
                      </Pie>
                    </RechartsPie>
                  </ResponsiveContainer>
                </div>
                <p className="text-2xl font-bold text-slate-900 mt-1 tabular-nums">
                  {completionRate}%
                </p>
                <p className="text-xs text-slate-500">Completion rate</p>
              </div>
            )}
          </SectionCard>

          {/* D) Goal tracker */}
          <SectionCard title="Goal tracker">
            {kpisLoading ? (
              <Skeleton className="h-48 rounded-xl" />
            ) : (
              <ul className="space-y-3">
                {goals.map((g) => {
                  const pct =
                    g.target > 0
                      ? Math.min(100, Math.round((g.current / g.target) * 100))
                      : 0;
                  return (
                    <li key={g.label}>
                      <div className="flex justify-between text-xs mb-1">
                        <span className="text-slate-600">{g.label}</span>
                        <span className="font-medium text-slate-900 tabular-nums">
                          {g.current} / {g.target}
                        </span>
                      </div>
                      <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                        <div
                          className="h-full rounded-full bg-emerald-500 transition-all"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </SectionCard>
        </div>

        {/* ——— 5) صف سفلي: Top categories, Projects by type, Users by role, Top projects ——— */}
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          <SectionCard title="Top categories" actionLabel="View all">
            {loading ? (
              <Skeleton className="h-32 rounded-xl" />
            ) : topCategories.length === 0 ? (
              <p className="text-slate-400 text-sm">No category data</p>
            ) : (
              <ul className="space-y-1.5 max-h-36 overflow-y-auto">
                {topCategories.map((c) => (
                  <li
                    key={c.name}
                    className="flex items-center justify-between gap-2 text-sm"
                  >
                    <span className="truncate text-slate-700">{c.name}</span>
                    <span className="font-semibold text-slate-900 shrink-0">
                      {c.count}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </SectionCard>

          <SectionCard title="Projects by type">
            {loading ? (
              <Skeleton className="h-32 rounded-xl" />
            ) : byType.length === 0 ? (
              <p className="text-slate-400 text-sm py-4">No type data</p>
            ) : (
              <div className="h-36">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart
                    layout="vertical"
                    data={byType.map((t) => ({
                      name: String(t.type),
                      count: Number(t.count),
                    }))}
                    margin={{ top: 0, right: 8, left: 0, bottom: 0 }}
                  >
                    <XAxis
                      type="number"
                      tick={{ fontSize: 10, fill: "#64748b" }}
                    />
                    <YAxis
                      type="category"
                      dataKey="name"
                      width={72}
                      tick={{ fontSize: 10, fill: "#64748b" }}
                    />
                    <Bar
                      dataKey="count"
                      fill={PRIMARY}
                      radius={[0, 4, 4, 0]}
                    />
                    <Tooltip />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </SectionCard>

          <SectionCard title="Users by role">
            {loading ? (
              <Skeleton className="h-32 rounded-xl" />
            ) : !kpis?.usersByRole?.length ? (
              <p className="text-slate-400 text-sm">No role data</p>
            ) : (
              <div className="space-y-1.5">
                {kpis.usersByRole.map((r) => (
                  <div
                    key={r.label}
                    className="flex items-center justify-between gap-2 text-sm"
                  >
                    <span className="text-slate-700">{r.label}</span>
                    <span
                      className="font-bold tabular-nums"
                      style={{ color: PRIMARY }}
                    >
                      {r.value}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </SectionCard>

          <SectionCard title="Top projects" actionLabel="View all">
            {loading ? (
              <Skeleton className="h-32 rounded-xl" />
            ) : topProjects.length === 0 ? (
              <p className="text-slate-400 text-sm">No projects in range</p>
            ) : (
              <ul className="space-y-1.5 max-h-36 overflow-y-auto">
                {topProjects.slice(0, 5).map((p) => (
                  <li
                    key={p.id}
                    className="flex items-center justify-between gap-2 text-sm py-0.5 border-b border-slate-50 last:border-0"
                  >
                    <span
                      className="truncate flex-1 text-slate-700"
                      title={p.title}
                    >
                      {p.title || `#${p.id}`}
                    </span>
                    <span
                      className="font-semibold shrink-0 text-slate-900"
                      style={{ color: PRIMARY }}
                    >
                      {p.applications}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </SectionCard>
        </div>
      </div>
    </div>
  );
}
