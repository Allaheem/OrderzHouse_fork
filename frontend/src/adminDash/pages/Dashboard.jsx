// src/pages/Dashboard.jsx
import React, {
  useEffect,
  useMemo,
  useState,
  useCallback,
  useRef,
} from "react";
import { useSelector } from "react-redux";
import { useOutletContext, useNavigate, useLocation } from "react-router-dom";
import {
  Search,
  Mail,
  Bell,
  ArrowRight,
  ArrowUpRight,
  Plus,
  FolderPlus,
  ClipboardList,
  Wallet,
  CreditCard,
  RefreshCw,
  HelpCircle,
  Clock,
  ChevronLeft,
  ChevronRight,
  Activity,
  UserCheck,
  Users,
  Check,
  Settings,
} from "lucide-react";

// 🧩 API (كما هو عندك)
import {
  fetchAdminDashboard,
  fetchFreelancerDashboard,
  fetchClientDashboard,
} from "../api/dashboard";
import PageMeta from "../../components/PageMeta.jsx";
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

/* ===================== Helpers (Role + Base paths) ===================== */
function mapRole(roleId) {
  if (roleId === 1) return "admin";
  if (roleId === 2) return "client";
  if (roleId === 3) return "freelancer";
  if (roleId === 5) return "partner";
  return "user";
}

function getBasePrefix(pathname) {
  if (pathname.startsWith("/client")) return "/client";
  if (pathname.startsWith("/freelancer")) return "/freelancer";
  if (pathname.startsWith("/apm")) return "/apm";
  if (pathname.startsWith("/partner")) return "/partner";
  return "/admin";
}

function useRoleBase() {
  const location = useLocation();
  return getBasePrefix(location.pathname);
}

/* ===================== UI tokens ===================== */
const UI = {
  pageBg: "bg-slate-50",
  container: "mx-auto w-full",
  card: "rounded-3xl bg-white border border-slate-100 shadow-sm",
  softCard:
    "rounded-3xl bg-white/80 backdrop-blur border border-slate-200/70 shadow-sm",
  ring: { border: "1px solid rgba(15,23,42,.10)" },
  violetGrad: "bg-gradient-to-b from-orange-400 to-red-500",
  chip: "rounded-2xl bg-white border border-slate-200/70 shadow-sm",
};

function cx(...x) {
  return x.filter(Boolean).join(" ");
}

function parseNumberLike(v) {
  if (v == null) return null;
  const s = String(v);
  const m = s.replace(/[^\d.]/g, "");
  const n = Number(m);
  return Number.isFinite(n) ? n : null;
}

function InfoTip({ text }) {
  if (!text) return null;
  return (
    <span className="relative inline-flex items-center group">
      <button
        type="button"
        className="inline-flex items-center justify-center rounded-full hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-orange-200/70"
        aria-label="Help"
      >
        <HelpCircle className="w-4 h-4 text-slate-400 group-hover:text-slate-600" />
      </button>

      <span
        className="
          pointer-events-none absolute left-1/2 top-0
          -translate-x-1/2 -translate-y-[120%]
          w-[260px] max-w-[75vw]
          rounded-xl bg-slate-900 text-white
          text-[11px] leading-5 px-3 py-2
          opacity-0 scale-95
          group-hover:opacity-100 group-hover:scale-100
          group-focus-within:opacity-100 group-focus-within:scale-100
          transition shadow-[0_18px_40px_rgba(0,0,0,0.35)]
          z-50
        "
        role="tooltip"
      >
        {text}
        <span
          className="
            absolute left-1/2 bottom-[-6px] -translate-x-1/2
            h-0 w-0 border-x-[6px] border-x-transparent
            border-t-[6px] border-t-slate-900
          "
        />
      </span>
    </span>
  );
}
function HelloSticker({ name, subtitle }) {
  const safeName = (name || "there").trim();

  return (
    // يظهر فقط تحت lg (موبايل + آيباد) ويختفي على اللابتوب
    <div className="lg:hidden">
      <div className="relative inline-block max-w-full">
        <div className="relative overflow-hidden px-4 py-1 sm:px-5 sm:py-4">
          {/* Title: smaller + lighter + wraps nicely */}
          <div className="text-2xl sm:text-[26px] font-semibold tracking-tight text-slate-900 leading-[1.05]">
            <span className="whitespace-nowrap">Hello,</span>{" "}
            <span className="font-medium break-words [overflow-wrap:anywhere]">
              {safeName}
            </span>
          </div>

          {/* Subtitle: slightly smaller */}
          <div className="mt-1 text-[11px] sm:text-xs text-slate-500">
            {subtitle || "Keep your projects moving—fast."}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ===================== Hero banner (Join now -> Create project) ===================== */
function HeroBanner({
  eyebrow,
  title,
  subtitle,
  subtitleMobile,
  ctaLabel,
  onCta,
  rightSlot,
}) {
  return (
    <div className={cx(UI.card, UI.violetGrad, "relative overflow-hidden")}>
      <div className="absolute -right-20 -top-16 h-56 w-56 sm:h-64 sm:w-64 rounded-full bg-white/10 blur-2xl" />
      <div className="absolute left-6 sm:left-10 -bottom-24 h-56 w-56 sm:h-64 sm:w-64 rounded-full bg-black/10 blur-2xl" />

      <div className="relative p-4 sm:p-5 lg:p-6">
        {/* ✅ لا تجعلها flex إلا على lg حتى لا تنضغط داخل عمود ضيق */}
        <div className="lg:flex lg:items-end lg:justify-between lg:gap-6">
          <div className="min-w-0 lg:max-w-[68%]">
            {eyebrow ? (
              <div className="text-[10px] sm:text-[11px] uppercase tracking-[0.22em] text-white/70 font-semibold">
                {eyebrow}
              </div>
            ) : null}

            <h2 className="mt-2 text-[18px] sm:text-[22px] lg:text-[26px] font-extrabold leading-tight text-white">
              {title}
            </h2>

            {/* ✅ خلي النسخة القصيرة إلى lg */}
            <div className="hidden sm:block">
              {subtitle || subtitleMobile ? (
                <>
                  <p className="mt-2 text-[12px] sm:text-sm text-white/80 max-w-xl lg:hidden">
                    {subtitleMobile ?? subtitle}
                  </p>
                  <p className="mt-2 hidden lg:block text-sm text-white/80 max-w-xl">
                    {subtitle}
                  </p>
                </>
              ) : null}
            </div>

            <div className="mt-3 sm:mt-4 flex items-center gap-2">
              <button
                type="button"
                onClick={onCta}
                className={cx(
                  "rounded-2xl bg-black/80 hover:bg-black text-white font-semibold inline-flex items-center gap-2",
                  "h-10 sm:h-11 px-3.5 sm:px-4 text-[13px] sm:text-sm"
                )}
              >
                {ctaLabel}
                <ArrowRight className="h-4 w-4" />
              </button>

              <span className="hidden sm:inline-flex text-xs text-white/70">
                Fast &amp; clear flow
              </span>
            </div>
          </div>

          {/* ✅ rightSlot يظهر فقط على lg عشان ما يضغط المحتوى */}
          {rightSlot ? (
            <div className="hidden lg:block shrink-0">{rightSlot}</div>
          ) : null}
        </div>
      </div>
    </div>
  );
}

/* ===================== Mini KPI chips (scroll on mobile) ===================== */
/* ===================== Mini KPI chips (mobile grid, no horizontal scroll) ===================== */
function MiniKpi({
  icon: Icon,
  label,
  value,
  tone = "orange",
  compact = false,
}) {
  const toneBg =
    tone === "orange"
      ? "bg-orange-50 text-orange-700 border-orange-200/70"
      : tone === "red"
      ? "bg-red-50 text-red-700 border-red-200/70"
      : tone === "emerald"
      ? "bg-emerald-50 text-emerald-700 border-emerald-200/70"
      : "bg-orange-50 text-orange-700 border-orange-200/70";

  const SafeIcon = typeof Icon === "function" ? Icon : null;

  return (
    <div
      className={cx(
        UI.chip,
        compact ? "px-3 py-3 rounded-2xl" : "px-3 py-2.5",
        "min-w-0 w-full"
      )}
      style={UI.ring}
    >
      <div className="flex items-center gap-3 min-w-0">
        <div
          className={cx(
            "grid place-items-center border shrink-0",
            toneBg,
            compact ? "h-9 w-9 rounded-2xl" : "h-9 w-9 rounded-2xl"
          )}
        >
          {SafeIcon ? (
            <SafeIcon className={compact ? "h-4 w-4" : "h-4 w-4"} />
          ) : (
            <Activity className={compact ? "h-4 w-4" : "h-4 w-4"} />
          )}
        </div>

        <div className="min-w-0 flex-1">
          <div
            className={cx(
              "font-semibold truncate",
              compact
                ? "text-[10px] text-slate-500"
                : "text-[11px] text-slate-500"
            )}
          >
            {label}
          </div>
          <div
            className={cx(
              "font-extrabold text-slate-900 truncate",
              compact ? "text-sm" : "text-sm"
            )}
          >
            {value ?? "—"}
          </div>
        </div>
      </div>
    </div>
  );
}

function KpiRow({ items }) {
  const list = Array.isArray(items) ? items : [];

  return (
    <div className="mt-4">
      {/* desktop/tablet */}
      <div className="hidden sm:grid grid-cols-2 lg:grid-cols-3 gap-3">
        {list.map((it, i) => (
          <MiniKpi
            key={it?.id || it?.title || i}
            icon={it?.icon}
            label={it?.title || it?.label || "KPI"}
            value={it?.value}
            tone={i % 3 === 0 ? "orange" : i % 3 === 1 ? "red" : "emerald"}
          />
        ))}
      </div>

      {/* mobile: grid 2x2 (or more rows) */}
      <div className="sm:hidden grid grid-cols-2 gap-3">
        {list.map((it, i) => (
          <MiniKpi
            key={it?.id || it?.title || i}
            compact
            icon={it?.icon}
            label={it?.title || it?.label || "KPI"}
            value={it?.value}
            tone={i % 3 === 0 ? "orange" : i % 3 === 1 ? "red" : "emerald"}
          />
        ))}
      </div>
    </div>
  );
}
function ContinueRowCard({ badge, title, metaLeft, metaRight, onOpen }) {
  return (
    <button
      type="button"
      onClick={onOpen}
      className={cx(
        UI.card,
        "w-full text-left px-3 py-3 flex items-center gap-3 hover:shadow-md transition-shadow"
      )}
      style={UI.ring}
    >
      {/* mini cover */}
      <div className="h-12 w-12 rounded-2xl bg-slate-100 relative overflow-hidden shrink-0">
        <div className="absolute inset-0 bg-gradient-to-tr from-slate-200 via-white to-slate-200 opacity-90" />
      </div>

      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2 min-w-0">
          {badge ? (
            <span className="shrink-0 inline-flex items-center rounded-full bg-slate-50 border border-slate-200 px-2 py-0.5 text-[10px] font-semibold text-slate-700">
              {badge}
            </span>
          ) : null}
          <div className="text-xs font-extrabold text-slate-900 truncate">
            {title || "Untitled"}
          </div>
        </div>

        <div className="mt-1 flex items-center justify-between gap-2 text-[11px] text-slate-500">
          <span className="truncate">{metaLeft || "—"}</span>
          <span className="shrink-0 font-semibold text-slate-800">
            {metaRight || ""}
          </span>
        </div>
      </div>

      <ArrowRight className="h-4 w-4 text-slate-300 shrink-0" />
    </button>
  );
}

/* ===================== Continue cards (carousel on mobile) ===================== */
function ContinueCarouselCard({ badge, title, metaLeft, metaRight, onOpen }) {
  return (
    <button
      type="button"
      onClick={onOpen}
      className={cx(
        UI.card,
        "w-full text-left overflow-hidden hover:shadow-md transition-shadow min-w-0"
      )}
      style={UI.ring}
    >
      {/* wide thumbnail like the screenshot */}
      <div className="relative aspect-[16/9] bg-slate-100">
        <div className="absolute inset-0 bg-gradient-to-tr from-slate-200 via-white to-slate-200 opacity-90" />

        {/* badge (top-left) */}
        {badge ? (
          <div className="absolute left-3 top-3">
            <span className="inline-flex items-center rounded-full bg-white/85 border border-slate-200 px-2.5 py-1 text-[10px] font-semibold text-slate-700 truncate">
              {badge}
            </span>
          </div>
        ) : null}

      </div>

      {/* Footer content below image */}
      <div className="p-3 border-t border-slate-100 min-w-0">
        <div className="text-sm font-extrabold text-slate-900 line-clamp-2">
          {title || "Untitled"}
        </div>
        <div className="mt-1 flex items-center justify-between gap-3 text-[11px] text-slate-500">
          <span className="truncate min-w-0">{metaLeft || "—"}</span>
          <span className="shrink-0 font-semibold text-slate-800">{metaRight || ""}</span>
        </div>
      </div>
    </button>
  );
}

function ContinueSection({ title, rightAction, items, renderItem }) {
  const list = Array.isArray(items) ? items : [];
  const scrollerRef = useRef(null);
  const navigate = useNavigate();
  const location = useLocation();

  const [canLeft, setCanLeft] = useState(false);
  const [canRight, setCanRight] = useState(false);

  const update = useCallback(() => {
    const el = scrollerRef.current;
    if (!el) return;
    const max = el.scrollWidth - el.clientWidth;
    setCanLeft(el.scrollLeft > 2);
    setCanRight(el.scrollLeft < max - 2);
  }, []);

  useEffect(() => {
    update();
    const el = scrollerRef.current;
    if (!el) return;

    const onScroll = () => update();
    el.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", update);

    return () => {
      el.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", update);
    };
  }, [update]);

  const scrollByStep = (dir) => {
    const el = scrollerRef.current;
    if (!el) return;

    const first = el.querySelector("[data-carousel-item]");
    const cardW = first
      ? first.getBoundingClientRect().width
      : el.clientWidth * 0.9;

    const styles = window.getComputedStyle(el);
    const gap = parseFloat(styles.gap || styles.columnGap || "16") || 16;

    el.scrollBy({ left: dir * (cardW + gap), behavior: "smooth" });
  };

  // Extract props from item for mobile layout (matches renderItem pattern)
  const extractItemProps = useCallback((item, index) => {
    const badge = item?.status || item?.completion_status || "Project";
    const title = item?.title || "Untitled";
    const metaLeft =
      (item?.completion_status && `Status: ${item.completion_status}`) ||
      (item?.status && `Status: ${item.status}`) ||
      "—";
    const metaRight = item?.amount_to_pay ?? item?.budget ?? "";
    
    // Determine base path from current location
    const getBasePrefix = (pathname) => {
      if (pathname.startsWith("/client")) return "/client";
      if (pathname.startsWith("/freelancer")) return "/freelancer";
      if (pathname.startsWith("/apm")) return "/apm";
      if (pathname.startsWith("/partner")) return "/partner";
      return "/admin";
    };
    const base = getBasePrefix(location.pathname);
    
    // Create onOpen handler - try to extract from renderItem, fallback to navigation
    let onOpenHandler = () => {
      const itemId = item?.id ?? item?._id ?? item?.project_id;
      if (itemId) {
        navigate(`${base}/project/${itemId}`);
      } else {
        navigate(`${base}/projects`);
      }
    };
    
    // Try to extract onClick from renderItem result
    try {
      const rendered = renderItem?.(item, index);
      if (rendered) {
        const wrapper = rendered;
        if (wrapper.props && wrapper.props.children) {
          const card = wrapper.props.children;
          if (card && card.props && card.props.onClick) {
            onOpenHandler = card.props.onClick;
          }
        }
      }
    } catch (_) {
      // Use fallback handler
    }
    
    return { badge, title, metaLeft, metaRight, onOpen: onOpenHandler };
  }, [renderItem, navigate, location.pathname]);

  return (
    <div className="mt-6 overflow-hidden rounded-3xl bg-white border border-slate-200 shadow-sm p-5">
      {/* Mobile Layout: Vertical List */}
      <div className="sm:hidden">
        <div className="flex items-center justify-between gap-3">
          <div className="text-sm font-extrabold text-slate-900">{title}</div>
          {rightAction}
        </div>

        <div className="mt-3 space-y-3">
          {list.slice(0, 5).map((it, i) => {
            const { badge, title: itemTitle, metaLeft, metaRight, onOpen } = extractItemProps(it, i);
            
            return (
              <div
                key={it?.id || it?._id || i}
                role="button"
                tabIndex={0}
                onClick={onOpen || (() => {})}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    (onOpen || (() => {}))();
                  }
                }}
                className="w-full text-left min-w-0 cursor-pointer rounded-2xl focus:outline-none focus-visible:ring-2 focus-visible:ring-orange-500/50"
              >
                <div className="flex gap-3 rounded-2xl border border-slate-200/70 bg-white p-3 shadow-sm active:scale-[0.99] transition">
                  {/* Thumbnail */}
                  <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl bg-slate-100">
                    <div className="absolute inset-0 bg-gradient-to-tr from-slate-200 via-white to-slate-200 opacity-90" />
                    {/* Badge */}
                    {badge ? (
                      <span className="absolute left-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-[10px] font-semibold text-slate-700 truncate max-w-[70px]">
                        {badge}
                      </span>
                    ) : null}
                  </div>

                  {/* Content */}
                  <div className="min-w-0 flex-1">
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0 flex-1">
                        <div className="text-sm font-extrabold text-slate-900 line-clamp-2">
                          {itemTitle}
                        </div>
                        <div className="mt-1 text-[11px] text-slate-500 line-clamp-1">
                          {metaLeft}
                        </div>
                      </div>

                    </div>

                    <div className="mt-2 flex items-center justify-between">
                      <span className="text-[11px] font-semibold text-slate-700">
                        {metaRight}
                      </span>
                      <span className="text-[11px] font-semibold text-orange-700">
                        Open →
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Desktop Layout: Carousel (unchanged) */}
      <div className="hidden sm:block">
        <div className="flex items-center justify-between gap-3">
          <div className="text-sm font-extrabold text-slate-900">{title}</div>

          <div className="flex items-center gap-2">
            {rightAction}

            {/* arrows like the screenshot (desktop/tablet) */}
            <div className="hidden sm:flex items-center gap-2">
              <button
                type="button"
                onClick={() => scrollByStep(-1)}
                disabled={!canLeft}
                className={cx(
                  "h-9 w-9 rounded-full border grid place-items-center transition",
                  canLeft
                    ? "bg-white border-slate-200/70 text-slate-700 hover:bg-slate-50"
                    : "bg-slate-100 border-slate-200 text-slate-400 cursor-not-allowed"
                )}
                aria-label="Scroll left"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>

              <button
                type="button"
                onClick={() => scrollByStep(1)}
                disabled={!canRight}
                className={cx(
                  "h-9 w-9 rounded-full border grid place-items-center transition",
                  canRight
                    ? "bg-white border-slate-200/70 text-slate-700 hover:bg-slate-50"
                    : "bg-slate-100 border-slate-200 text-slate-400 cursor-not-allowed"
                )}
                aria-label="Scroll right"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>

        {/* carousel */}
        <div
          ref={scrollerRef}
          className="
            mt-3 flex gap-4
            overflow-x-auto scroll-smooth
            snap-x snap-mandatory
            overscroll-x-contain touch-pan-x
            pl-4 pr-10 sm:pr-16 pb-2
            [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden
          "
        >
          {list.map((it, i) => (
            <div
              key={it?.id || it?._id || i}
              data-carousel-item
              className="
                snap-start flex-none min-w-0
                w-[92%] max-w-[420px]
                sm:w-[70%]
                md:w-[52%]
                lg:w-[calc((100%-1rem)/2.5)]
                xl:w-[calc((100%-1rem)/2.6)]
              "
            >
              {renderItem?.(it, i)}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ===================== Right column: Statistic + List ===================== */
function RingProgress({ percent = 0, label, subLabel, extra }) {
  const p = Math.max(0, Math.min(100, Number(percent) || 0));
  const r = 36;
  const c = 2 * Math.PI * r;
  const dash = (p / 100) * c;

  return (
    <div className={cx(UI.card, "p-5")} style={UI.ring}>
      <div className="flex items-start justify-between">
        <div className="text-sm font-extrabold text-slate-900">Statistic</div>
        {/* <button type="button" className="text-slate-400 hover:text-slate-600">
          •••
        </button> */}
      </div>

      <div className="mt-4 flex flex-col items-center">
        <div className="relative h-28 w-28">
          <svg viewBox="0 0 100 100" className="h-28 w-28">
            <circle
              cx="50"
              cy="50"
              r={r}
              stroke="rgba(15,23,42,.10)"
              strokeWidth="10"
              fill="none"
            />
            <circle
              cx="50"
              cy="50"
              r={r}
              stroke="rgb(249 115 22)"
              strokeWidth="10"
              fill="none"
              strokeDasharray={`${dash} ${c - dash}`}
              strokeLinecap="round"
              transform="rotate(-90 50 50)"
            />
          </svg>

          <div className="absolute inset-0 grid place-items-center">
            <div className="h-14 w-14 rounded-full bg-slate-100 grid place-items-center">
              <Users className="h-6 w-6 text-slate-500" />
            </div>
          </div>

          <div className="absolute right-0 top-2">
            <span className="inline-flex items-center rounded-full bg-orange-50 text-orange-700 border border-orange-200/70 px-2 py-0.5 text-[10px] font-bold">
              {Math.round(p)}%
            </span>
          </div>
        </div>

        <div className="mt-3 text-sm font-extrabold text-slate-900">
          {label || "Keep going 🚀"}
        </div>
        {subLabel ? (
          <div className="mt-1 text-[11px] text-slate-500 text-center">
            {subLabel}
          </div>
        ) : null}


        {extra ? (
          <div className="mt-4 pt-4 b">
            {extra}
          </div>
        ) : null}
      </div>
    </div>
  );
}

function RightListCard({ title, items, onSeeAll, renderRow, emptyMessage = "Nothing to show." }) {
  const list = Array.isArray(items) ? items : [];
  return (
    <div className={cx(UI.card, "p-5")} style={UI.ring}>
      <div className="flex items-center justify-between">
        <div className="text-sm font-extrabold text-slate-900">{title}</div>
      </div>

      <div className="mt-4 space-y-3">
        {list.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-3 py-3 text-[11px] text-slate-500 text-center">
            {emptyMessage}
          </div>
        ) : (
          list.slice(0, 5).map((it, idx) => (
            <div
              key={it?.id || it?.assignment_id || idx}
              className="flex items-center justify-between gap-3 rounded-2xl bg-slate-50 border border-slate-200/70 px-3 py-2.5"
            >
              {renderRow?.(it, idx)}
            </div>
          ))
        )}

        {onSeeAll && list.length > 0 ? (
          <button
            type="button"
            onClick={onSeeAll}
            className="w-full h-10 rounded-2xl bg-orange-50 text-orange-700 border border-orange-200/70 text-sm font-semibold hover:bg-orange-100"
          >
            See All
          </button>
        ) : null}
      </div>
    </div>
  );
}

/* ===================== Financial Overview Card ===================== */
function FinancialOverviewCard({ moneyInEscrow = 0, totalReleased = 0, totalRefunded = 0 }) {
  const formatAmount = (amount) => {
    const num = Number(amount) || 0;
    const formatted = num % 1 === 0 ? num.toString() : num.toFixed(2);
    return `${formatted} JD`;
  };

  return (
    <div className={cx(UI.card, "p-5")} style={UI.ring}>
      <div className="flex items-center justify-between mb-4">
        <div className="text-sm font-extrabold text-slate-900">💰 Financial Overview</div>
      </div>

      <div className="space-y-3">
        {/* Money in Escrow */}
        <div className="rounded-2xl bg-amber-50 border border-amber-200/70 px-3 py-2.5">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-[11px] font-semibold text-amber-700">Money in Escrow</div>
              <div className="text-xs text-amber-600 mt-0.5">Held for active projects</div>
            </div>
            <div className="text-base font-extrabold text-amber-900">
              {formatAmount(moneyInEscrow)}
            </div>
          </div>
        </div>

        {/* Total Released */}
        <div className="rounded-2xl bg-emerald-50 border border-emerald-200/70 px-3 py-2.5">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-[11px] font-semibold text-emerald-700">Total Released</div>
              <div className="text-xs text-emerald-600 mt-0.5">Paid to freelancers</div>
            </div>
            <div className="text-base font-extrabold text-emerald-900">
              {formatAmount(totalReleased)}
            </div>
          </div>
        </div>

        {/* Total Refunded (if > 0) */}
        {totalRefunded > 0 && (
          <div className="rounded-2xl bg-slate-50 border border-slate-200/70 px-3 py-2.5">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-[11px] font-semibold text-slate-700">Total Refunded</div>
                <div className="text-xs text-slate-600 mt-0.5">Returned to you</div>
              </div>
              <div className="text-base font-extrabold text-slate-900">
                {formatAmount(totalRefunded)}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

/* ===================== Subscription Card ===================== */
function SubscriptionCard({ subscriptionStatus, loading }) {
  if (loading) {
    return (
      <div className={cx(UI.card, "p-6")} style={{ ...UI.ring, boxShadow: "0 1px 3px 0 rgba(0,0,0,0.08), 0 1px 2px -1px rgba(0,0,0,0.04)" }}>
        <div className="flex items-center justify-between mb-4">
          <div className="text-sm font-extrabold text-slate-900">Subscription</div>
        </div>
        <div className="text-xs text-slate-500">Loading subscription...</div>
      </div>
    );
  }

  if (!subscriptionStatus || !subscriptionStatus.subscription) {
    return (
      <div className={cx(UI.card, "p-6")} style={{ ...UI.ring, boxShadow: "0 1px 3px 0 rgba(0,0,0,0.08), 0 1px 2px -1px rgba(0,0,0,0.04)" }}>
        <div className="flex items-center justify-between mb-4">
          <div className="text-sm font-extrabold text-slate-900">Subscription</div>
        </div>
        <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-3 py-3 text-[11px] text-slate-500">
          No active subscription
        </div>
      </div>
    );
  }

  const sub = subscriptionStatus.subscription;
  const status = subscriptionStatus.status || sub.status;
  const remainingDays = subscriptionStatus.remaining_days || 0;
  const statusMessage = subscriptionStatus.status_message || "";

  // Status badge styling
  const getStatusBadge = () => {
    if (status === "pending_start") {
      return (
        <span className="inline-flex items-center rounded-full bg-amber-50 text-amber-700 border border-amber-200/70 px-2.5 py-1 text-[10px] font-semibold">
          Not started
        </span>
      );
    }
    if (status === "active") {
      return (
        <span className="inline-flex items-center rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200/70 px-2.5 py-1 text-[10px] font-semibold">
          Active
        </span>
      );
    }
    return (
      <span className="inline-flex items-center rounded-full bg-slate-100 text-slate-600 border border-slate-200/70 px-2.5 py-1 text-[10px] font-semibold">
        Expired
      </span>
    );
  };

  // Format end date
  const formatDate = (dateStr) => {
    if (!dateStr) return "";
    try {
      const date = new Date(dateStr);
      return date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
    } catch {
      return "";
    }
  };

  return (
    <div className={cx(UI.card, "p-6")} style={{ ...UI.ring, boxShadow: "0 1px 3px 0 rgba(0,0,0,0.08), 0 1px 2px -1px rgba(0,0,0,0.04)" }}>
      {/* Title row with status badge */}
      <div className="flex items-center justify-between mb-5">
        <div className="text-sm font-extrabold text-slate-900">Subscription</div>
        {getStatusBadge()}
      </div>

      <div className="space-y-4">
        {/* Plan name - more prominent */}
        <div>
          <div className="text-base font-extrabold text-slate-900">
            {sub.plan_name || "Plan"}
          </div>
        </div>

        {/* Main value area */}
        {status === "active" && remainingDays > 0 ? (
          <div>
            <div className="text-3xl font-extrabold text-slate-900 mb-1">
              {remainingDays}
            </div>
            <div className="text-sm text-slate-600 font-medium">
              days remaining
            </div>
          </div>
        ) : status === "pending_start" ? (
          <div>
            <div className="text-base text-slate-700 font-semibold leading-relaxed">
              Starts when you start your first project
            </div>
          </div>
        ) : (
          <div>
            <div className="text-2xl font-extrabold text-slate-600">
              Expired
            </div>
          </div>
        )}

        {/* End date (only if active/expired) */}
        {(status === "active" || status === "expired") && sub.end_date && (
          <div className="text-xs text-slate-500 pt-1">
            Ends: {formatDate(sub.end_date)}
          </div>
        )}
      </div>
    </div>
  );
}


/* ===================== Activation steps (embedded) ===================== */
function ActivationStepperCard({
  title,
  stepsLeft,
  steps,
  ctaLabel = "Continue",
  onCta,
  onStep,
  embedded = false,
}) {
  const list = Array.isArray(steps) ? steps : [];

  const stepsLeftLabel =
    stepsLeft == null
      ? ""
      : stepsLeft <= 0
      ? "All set"
      : `${stepsLeft} step${stepsLeft > 1 ? "s" : ""} left`;

  const nodeStyle = (status) => {
    if (status === "done") return "bg-orange-600 ring-1 ring-orange-200";
    if (status === "current") return "bg-orange-50 ring-1 ring-orange-200";
    return "bg-white ring-1 ring-slate-200";
  };

  const lineStyle = (status) => {
    if (status === "done") return "bg-orange-600/70";
    if (status === "current") return "bg-orange-500/25";
    return "bg-slate-200";
  };

  const nodeInner = (status) => {
    if (status === "done") return <Check className="h-4 w-4 text-white" />;
    if (status === "current")
      return <span className="h-3 w-3 rounded-md bg-orange-600" />;
    return <span className="h-3 w-3 rounded-md bg-slate-300" />;
  };

  const Header = (
    <div className="flex items-start justify-between gap-3">
      <div className="text-[13px] font-extrabold text-slate-900">{title}</div>
      {stepsLeftLabel ? (
        <div className="text-[11px] font-semibold text-slate-500 whitespace-nowrap">
          {stepsLeftLabel}
        </div>
      ) : null}
    </div>
  );

  const Body = (
    <div className="mt-3">
      {list.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-3 py-3 text-[11px] text-slate-500">
          Nothing to show.
        </div>
      ) : (
        <div className="space-y-1">
          {list.map((s, idx) => {
            const status = s?.status || "pending";
            const clickable = Boolean(s?.href) && typeof onStep === "function";

            return (
              <button
                key={s?.id || idx}
                type="button"
                disabled={!clickable}
                onClick={() => clickable && onStep(s.href)}
                className={cx(
                  "w-full text-left group",
                  clickable ? "cursor-pointer" : "cursor-default"
                )}
              >
                <div
                  className={cx(
                    "rounded-2xl px-2.5 py-2.5 transition",
                    clickable ? "hover:bg-white/70" : ""
                  )}
                >
                  <div className="flex items-start gap-3">
                    {/* left rail */}
                    <div className="flex flex-col items-center shrink-0">
                      <div
                        className={cx(
                          "h-6 w-6 rounded-2xl grid place-items-center",
                          nodeStyle(status)
                        )}
                      >
                        {nodeInner(status)}
                      </div>

                      {idx !== list.length - 1 ? (
                        <div
                          className={cx("mt-2 h-10 w-1 rounded-full", lineStyle(status))}
                        />
                      ) : null}
                    </div>

                    {/* content */}
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <div className="text-[13px] font-extrabold text-slate-900 truncate">
                            {s?.title || "Step"}
                          </div>
                          <div className="mt-0.5 text-[11px] text-slate-500 break-words">
                            {s?.description || s?.meta || "—"}
                          </div>
                        </div>

                        {clickable ? (
                          <span className="shrink-0 mt-0.5 inline-flex items-center text-[11px] font-semibold text-slate-400 group-hover:text-slate-600">
                            <ArrowUpRight className="h-4 w-4" />
                          </span>
                        ) : null}
                      </div>
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );

  const Footer =
    onCta && list.length > 0 ? (
      <button
        type="button"
        onClick={onCta}
        className={cx(
          "mt-3 w-full h-10 rounded-2xl text-sm font-semibold transition",
          "bg-orange-50 text-orange-700 border border-orange-200/70 hover:bg-orange-100"
        )}
      >
        {ctaLabel}
      </button>
    ) : null;

  if (embedded) {
    return (
      <div className="rounded-2xl bg-slate-50 border border-slate-200/70 p-3">
        {Header}
        {Body}
        {Footer}
      </div>
    );
  }

  return (
    <div className={cx(UI.card, "p-5")} style={UI.ring}>
      {Header}
      {Body}
      {Footer}
    </div>
  );
}

/* ===================== Helpers: verification/profile ===================== */
function isAccountVerified(u) {
  const raw =
    u?.is_verified ??
    u?.verified ??
    u?.isVerified ??
    u?.verification_status ??
    u?.verificationStatus ??
    u?.account_status ??
    u?.accountStatus ??
    u?.status;

  if (raw === true) return true;
  if (raw === false || raw == null) return false;
  if (typeof raw === "number") return raw === 1;

  const s = String(raw).trim().toLowerCase();
  if (!s) return false;

  if (
    ["pending", "rejected", "declined", "unverified", "not_verified", "not verified"].some(
      (k) => s.includes(k)
    )
  ) {
    return false;
  }

  return ["verified", "approved", "active", "done", "completed", "success"].some((k) =>
    s.includes(k)
  );
}

function isProfileComplete(u) {
  const first = u?.first_name ?? u?.firstName;
  const last = u?.last_name ?? u?.lastName;
  const username = u?.username ?? u?.user_name ?? u?.userName;
  const phone = u?.phone_number ?? u?.phoneNumber;
  const country = u?.country ?? u?.location;

  return Boolean(((first && last) || username) && phone && country);
}


/* ===================== Skeletons ===================== */
function Sk({ className = "" }) {
  return (
    <div className={`shimmer rounded-xl bg-slate-200/60 ${className}`} />
  );
}

function DashboardSkeletonV2() {
  return (
    <div
      className={cx(UI.pageBg, "overflow-x-hidden min-w-0 pt-3 sm:pt-0")}
      aria-busy="true"
      aria-live="polite"
    >
      <div className={cx(UI.container, "px-0 max-w-full")}>
        <div className="space-y-4">
          {/* Main grid - matches real dashboard layout */}
          <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px] min-w-0">
            {/* LEFT COLUMN */}
            <div className="min-w-0">
              {/* HelloSticker skeleton (mobile only) */}
              <div className="lg:hidden mb-4">
                <Sk className="h-12 w-48 max-w-full" />
              </div>

              {/* Hero Banner Skeleton */}
              <div className={cx(UI.card, UI.violetGrad, "relative overflow-hidden min-w-0")} style={UI.ring}>
                <div className="absolute -right-20 -top-16 h-56 w-56 sm:h-64 sm:w-64 rounded-full bg-white/10 blur-2xl" />
                <div className="absolute left-6 sm:left-10 -bottom-24 h-56 w-56 sm:h-64 sm:w-64 rounded-full bg-black/10 blur-2xl" />
                
                <div className="relative p-4 sm:p-5 lg:p-6 min-w-0">
                  <div className="lg:flex lg:items-end lg:justify-between lg:gap-6">
                    <div className="min-w-0 flex-1 lg:max-w-[68%]">
                      {/* Eyebrow */}
                      <Sk className="h-3 w-32 mb-2 opacity-70" />
                      
                      {/* Title */}
                      <div className="space-y-2 mt-2">
                        <Sk className="h-6 w-full max-w-md opacity-90" />
                        <Sk className="h-6 w-full max-w-sm opacity-90" />
                      </div>
                      
                      {/* Subtitle */}
                      <Sk className="h-4 w-full max-w-lg mt-2 opacity-80" />
                      
                      {/* CTA buttons */}
                      <div className="flex items-center gap-3 mt-3 sm:mt-4">
                        <Sk className="h-10 sm:h-11 w-32 rounded-2xl opacity-80" />
                        <Sk className="h-4 w-24 hidden sm:block opacity-70" />
                      </div>
                    </div>
                    
                    {/* Right slot (refresh button on desktop) */}
                    <div className="hidden lg:block shrink-0">
                      <Sk className="h-11 w-24 rounded-2xl opacity-70" />
                    </div>
                  </div>
                </div>
              </div>

              {/* KPI Row Skeleton */}
              <div className="mt-4 min-w-0">
                {/* Desktop/Tablet */}
                <div className="hidden sm:grid grid-cols-2 lg:grid-cols-3 gap-3 min-w-0">
                  {[1, 2, 3, 4, 5, 6].map((i) => (
                    <div key={i} className={cx(UI.chip, "px-3 py-2.5")} style={UI.ring}>
                      <div className="flex items-center gap-3">
                        <Sk className="h-9 w-9 rounded-2xl shrink-0" />
                        <div className="min-w-0 flex-1 space-y-1.5">
                          <Sk className="h-3 w-16" />
                          <Sk className="h-4 w-20" />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                
                {/* Mobile */}
                <div className="sm:hidden grid grid-cols-2 gap-3 min-w-0">
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className={cx(UI.chip, "px-3 py-3 min-w-0")} style={UI.ring}>
                      <div className="flex items-center gap-3">
                        <Sk className="h-9 w-9 rounded-2xl shrink-0" />
                        <div className="min-w-0 flex-1 space-y-1.5">
                          <Sk className="h-3 w-12" />
                          <Sk className="h-4 w-16" />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Continue Section Skeleton */}
              <div className="mt-6 min-w-0">
                {/* Header */}
                <div className="flex items-center justify-between mb-3 min-w-0">
                  <Sk className="h-5 w-32" />
                  <Sk className="h-4 w-16" />
                </div>
                
                {/* Carousel cards */}
                <div className="flex gap-4 overflow-x-auto overflow-y-hidden scroll-smooth snap-x snap-mandatory pr-2 sm:pr-16 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden min-w-0">
                  {[1, 2, 3].map((i) => (
                    <div
                      key={i}
                      className="snap-start flex-none min-w-0 w-[82%] sm:w-[70%] md:w-[52%] lg:w-[calc((100%-1rem)/2.5)] xl:w-[calc((100%-1rem)/2.6)]"
                    >
                      <div className={cx(UI.card, "overflow-hidden")} style={UI.ring}>
                        {/* Image area */}
                        <div className="relative aspect-[16/9] bg-slate-100">
                          <Sk className="absolute inset-0" />
                          {/* Badge */}
                          <div className="absolute left-3 top-3">
                            <Sk className="h-5 w-16 rounded-full" />
                          </div>
                        </div>
                        {/* Bottom text */}
                        <div className="p-3 border-t border-slate-100 space-y-2">
                          <Sk className="h-4 w-full" />
                          <div className="flex items-center justify-between">
                            <Sk className="h-3 w-24" />
                            <Sk className="h-3 w-16" />
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* RIGHT COLUMN */}
            <div className="space-y-6 w-full min-w-0 xl:w-[360px] xl:justify-self-end">
              {/* RingProgress Skeleton */}
              <div className={cx(UI.card, "p-5 min-w-0")} style={UI.ring}>
                <Sk className="h-5 w-24 mb-4" />
                <div className="flex flex-col items-center mt-4">
                  <div className="relative h-28 w-28">
                    {/* Circular progress skeleton */}
                    <div className="h-28 w-28 rounded-full border-8 border-slate-200" />
                    <div className="absolute inset-0 grid place-items-center">
                      <Sk className="h-14 w-14 rounded-full" />
                    </div>
                    {/* Badge */}
                    <div className="absolute right-0 top-2">
                      <Sk className="h-5 w-10 rounded-full" />
                    </div>
                  </div>
                  <Sk className="h-4 w-32 mt-3" />
                  <Sk className="h-3 w-40 mt-1" />
                </div>
              </div>

              {/* RightListCard Skeleton */}
              <div className={cx(UI.card, "p-5 min-w-0")} style={UI.ring}>
                <Sk className="h-5 w-32 mb-4" />
                <div className="mt-4 space-y-3">
                  {[1, 2, 3].map((i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between gap-3 rounded-2xl bg-slate-50 border border-slate-200/70 px-3 py-2.5"
                    >
                      <div className="min-w-0 flex-1 space-y-1.5">
                        <Sk className="h-3 w-full" />
                        <Sk className="h-2.5 w-3/4" />
                      </div>
                      <Sk className="h-9 w-16 rounded-2xl shrink-0" />
                    </div>
                  ))}
                  {/* See All button */}
                  <Sk className="h-10 w-full rounded-2xl" />
                </div>
              </div>

              {/* Quick Actions Skeleton */}
              <div className={cx(UI.card, "p-5 min-w-0")} style={UI.ring}>
                <Sk className="h-5 w-28 mb-4" />
                <div className="mt-4 grid gap-2">
                  {[1, 2, 3].map((i) => (
                    <div
                      key={i}
                      className="h-11 rounded-2xl bg-white border border-slate-200/70 flex items-center justify-between px-4"
                    >
                      <div className="flex items-center gap-2">
                        <Sk className="h-4 w-4 rounded" />
                        <Sk className="h-4 w-24" />
                      </div>
                      <Sk className="h-4 w-4 rounded" />
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ===================== Admin Dashboard — نفس أسلوب الداش في الصورة (3 أعمدة، كروت مالية) ===================== */
const ADMIN_CARD = "bg-white rounded-2xl border border-slate-200/70 shadow-sm overflow-hidden";

function AdminDashboard() {
  const navigate = useNavigate();
  const base = useRoleBase();

  const [topStats, setTopStats] = useState([]);
  const [pendingVerifications, setPendingVerifications] = useState([]);
  const [revenuePoints, setRevenuePoints] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        setError("");
        const payload = await fetchAdminDashboard();
        setTopStats(Array.isArray(payload?.topStats) ? payload.topStats : []);
        setPendingVerifications(
          Array.isArray(payload?.pendingVerifications)
            ? payload.pendingVerifications
            : []
        );
        setRevenuePoints(
          Array.isArray(payload?.revenuePoints) ? payload.revenuePoints : []
        );
      } catch (_) {
        setError("حدث خطأ أثناء تحميل بيانات لوحة التحكم.");
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const totalRevenue = topStats.find((s) => s?.id === "revenue")?.value ?? "—";
  const projectsCount = topStats.find((s) => s?.id === "projects")?.value ?? 0;
  const freelancersCount = topStats.find((s) => s?.id === "freelancers")?.value ?? 0;
  const tasksCount = topStats.find((s) => s?.id === "tasks")?.value ?? 0;

  const chartData = (revenuePoints || []).map((val, i) => {
    const d = new Date();
    d.setMonth(d.getMonth() - (11 - i));
    return {
      name: d.toLocaleDateString("en", { month: "short" }),
      value: Number(val) || 0,
    };
  });

  const pieData = [
    { name: "Projects", value: Number(projectsCount) || 0, color: "#f97316" },
    { name: "Freelancers", value: Number(freelancersCount) || 0, color: "#22c55e" },
    { name: "Tasks", value: Number(tasksCount) || 0, color: "#3b82f6" },
  ].filter((d) => d.value > 0);
  if (pieData.length === 0) pieData.push({ name: "No data", value: 1, color: "#e2e8f0" });

  const pendingTotal = pendingVerifications.length;

  if (loading && topStats.length === 0) {
    return (
      <div className="min-h-[60vh] bg-[#F7F8FA] p-4 md:p-6">
        <div className="max-w-[1600px] mx-auto space-y-4">
          <div className="h-10 w-48 rounded-xl bg-slate-200 animate-pulse" />
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className={ADMIN_CARD} style={{ minHeight: "180px" }}>
                <div className="p-4 animate-pulse bg-slate-100 rounded-2xl m-3" />
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F7F8FA] p-4 md:p-6">
      <div className="max-w-[1600px] mx-auto space-y-4">
        {error ? (
          <div className="text-sm text-rose-600 bg-rose-50 border border-rose-200 rounded-2xl px-4 py-3">
            {error}
          </div>
        ) : null}

        {/* Top bar: Quick search + actions (مثل الصورة) */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="relative flex-1 min-w-[200px] max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              placeholder="Quick search..."
              className="w-full h-10 pl-10 pr-4 rounded-xl border border-slate-200 bg-white text-sm text-slate-800 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-orange-200/70"
            />
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => navigate(`${base}/operation/verifications`)}
              className="h-10 px-4 rounded-xl bg-white border border-slate-200 text-sm font-semibold text-slate-700 hover:bg-slate-50 inline-flex items-center gap-2"
            >
              <UserCheck className="h-4 w-4" />
              Verifications
            </button>
            <button
              type="button"
              className="h-10 px-4 rounded-xl bg-orange-500 text-white text-sm font-semibold hover:bg-orange-600 inline-flex items-center gap-2"
              onClick={() => navigate(`${base}/analytics`)}
            >
              <Plus className="h-4 w-4" />
              Add widget
            </button>
          </div>
        </div>

        {/* 3 columns like the reference dashboard */}
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-4">
          {/* ——— Left column: Balance overview + Limit + Distribution ——— */}
          <div className="xl:col-span-4 space-y-4">
            <div className={ADMIN_CARD}>
              <div className="p-4 border-b border-slate-100 flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Revenue overview
                </span>
                <span className="text-xs text-slate-400">12 months</span>
              </div>
              <div className="p-4">
                <div className="text-2xl font-bold text-slate-900">
                  {totalRevenue}
                </div>
                <div className="mt-2 flex gap-2 text-[11px]">
                  <span className="flex items-center gap-1">
                    <span className="w-2 h-2 rounded-full bg-amber-400" />
                    Revenue
                  </span>
                </div>
                <div className="mt-3 h-[180px]">
                  {chartData.length > 0 ? (
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={chartData} margin={{ top: 4, right: 4, left: 0, bottom: 0 }}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                        <XAxis dataKey="name" tick={{ fontSize: 10, fill: "#64748b" }} />
                        <YAxis tick={{ fontSize: 10, fill: "#64748b" }} />
                        <Tooltip
                          contentStyle={{ borderRadius: "12px", border: "1px solid #e2e8f0" }}
                          formatter={(v) => [`${v}`, "Revenue"]}
                        />
                        <Bar dataKey="value" fill="#f97316" radius={[4, 4, 0, 0]} name="Revenue" />
                      </BarChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-full flex items-center justify-center text-slate-400 text-sm">
                      No revenue data
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4 flex items-center justify-between">
                <div>
                  <div className="text-sm font-bold text-slate-900">
                    Pending verifications
                  </div>
                  <div className="text-xs text-slate-500">Recipient accounts</div>
                </div>
                <button
                  type="button"
                  onClick={() => navigate(`${base}/operation/verifications`)}
                  className="text-slate-400 hover:text-slate-600"
                  aria-label="Edit"
                >
                  <Settings className="w-4 h-4" />
                </button>
              </div>
              <div className="px-4 pb-4">
                <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-orange-500 transition-all"
                    style={{
                      width: `${Math.min(100, (pendingTotal / Math.max(pendingTotal, 1)) * 100)}%`,
                    }}
                  />
                </div>
                <div className="mt-2 text-sm font-semibold text-slate-700">
                  {pendingTotal} pending
                </div>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4 border-b border-slate-100">
                <div className="text-sm font-bold text-slate-900">Platform distribution</div>
                <div className="text-xs text-slate-500">Overview</div>
              </div>
              <div className="p-4 space-y-2">
                {(topStats || []).slice(0, 4).map((s, i) => {
                  const numVal = Number(s?.value);
                  const isNum = Number.isFinite(numVal);
                  const total = (topStats || []).slice(0, 4).reduce(
                    (sum, x) => sum + (Number(x?.value) || 0),
                    0
                  );
                  const pct =
                    isNum && total > 0 ? Math.round((numVal / total) * 100) : null;
                  return (
                    <div
                      key={s?.id || i}
                      className="flex items-center justify-between gap-2 text-sm"
                    >
                      <span className="text-slate-700">{s?.title || "—"}</span>
                      {pct != null ? (
                        <span className="font-semibold text-slate-900">{pct}%</span>
                      ) : (
                        <span className="font-semibold text-slate-900">{s?.value ?? "—"}</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* ——— Middle column: Summary stats + Tips + Doughnut + Goals ——— */}
          <div className="xl:col-span-4 space-y-4">
            <div className={ADMIN_CARD}>
              <div className="p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-slate-600">Total revenue</span>
                  <span className="text-sm font-bold text-emerald-600">↑</span>
                </div>
                <div className="text-lg font-bold text-slate-900">{totalRevenue}</div>

                <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                  <span className="text-sm text-slate-600">Total projects</span>
                </div>
                <div className="text-lg font-bold text-slate-900">{projectsCount}</div>

                <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                  <span className="text-sm text-slate-600">Freelancers</span>
                </div>
                <div className="text-lg font-bold text-slate-900">{freelancersCount}</div>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4 bg-gradient-to-br from-orange-50/80 to-emerald-50/50 rounded-2xl">
                <div className="text-sm font-bold text-slate-900">
                  Optimize your platform
                </div>
                <p className="mt-2 text-xs text-slate-600">
                  Review pending verifications and analytics to keep the platform healthy.
                </p>
                <button
                  type="button"
                  onClick={() => navigate(`${base}/analytics`)}
                  className="mt-3 text-xs font-semibold text-orange-600 hover:text-orange-700"
                >
                  Read more →
                </button>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4">
                <div className="text-sm font-bold text-slate-900">Platform health</div>
                <div className="text-xs text-slate-500 mt-0.5">Current status</div>
                <div className="mt-4 flex items-center gap-4">
                  <div className="w-28 h-28 shrink-0">
                    <ResponsiveContainer width="100%" height="100%">
                      <RechartsPie>
                        <Pie
                          data={pieData}
                          cx="50%"
                          cy="50%"
                          innerRadius={24}
                          outerRadius={40}
                          paddingAngle={2}
                          dataKey="value"
                          nameKey="name"
                        >
                          {pieData.map((entry, i) => (
                            <Cell key={entry.name} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip formatter={(v) => [v, ""]} />
                      </RechartsPie>
                    </ResponsiveContainer>
                  </div>
                  <div className="text-2xl font-bold text-emerald-600">
                    {projectsCount + freelancersCount + tasksCount > 0
                      ? "Active"
                      : "—"}
                  </div>
                </div>
                <p className="mt-2 text-[11px] text-slate-500">
                  Based on platform metrics
                </p>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4 flex items-center justify-between">
                <div className="text-sm font-bold text-slate-900">Pending queue</div>
                <button
                  type="button"
                  onClick={() => navigate(`${base}/operation/verifications`)}
                  className="text-xs font-semibold text-orange-600 hover:text-orange-700"
                >
                  Add goals
                </button>
              </div>
              <div className="p-4 pt-0 space-y-3">
                <div>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-600">Verifications</span>
                    <span className="font-semibold text-slate-900">
                      {pendingTotal} pending
                    </span>
                  </div>
                  <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                    <div
                      className="h-full rounded-full bg-orange-500"
                      style={{
                        width: `${Math.min(100, (pendingTotal / 10) * 100)}%`,
                      }}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ——— Right column: Quick stats + Quick payment + Transaction history ——— */}
          <div className="xl:col-span-4 space-y-4">
            <div className={ADMIN_CARD}>
              <div className="p-4 border-b border-slate-100">
                <div className="text-sm font-bold text-slate-900">Quick stats</div>
                <div className="text-xs text-slate-500">Quick actions</div>
              </div>
              <div className="p-4">
                <div className="grid grid-cols-2 gap-2">
                  {(topStats || []).slice(0, 4).map((s, i) => (
                    <div
                      key={s?.id || i}
                      className="rounded-xl bg-slate-50 border border-slate-100 p-3"
                    >
                      <div className="text-[11px] font-medium text-slate-500">
                        {s?.title}
                      </div>
                      <div className="text-sm font-bold text-slate-900 mt-0.5">
                        {s?.value ?? "—"}
                      </div>
                    </div>
                  ))}
                </div>
                <button
                  type="button"
                  onClick={() => navigate(`${base}/analytics`)}
                  className="mt-3 w-full h-10 rounded-xl bg-slate-100 hover:bg-slate-200 text-sm font-semibold text-slate-700 flex items-center justify-center gap-2"
                >
                  <Plus className="w-4 h-4" />
                  View analytics
                </button>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4">
                <div className="text-sm font-bold text-slate-900">Quick actions</div>
                <div className="mt-3 flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/people/freelancers`)}
                    className="h-9 px-3 rounded-full bg-white border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                  >
                    Freelancers
                  </button>
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/people/clients`)}
                    className="h-9 px-3 rounded-full bg-white border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                  >
                    Clients
                  </button>
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/operation/projects`)}
                    className="h-9 px-3 rounded-full bg-white border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                  >
                    Projects
                  </button>
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/finance/payments`)}
                    className="h-9 px-3 rounded-full bg-white border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                  >
                    Payments
                  </button>
                </div>
              </div>
            </div>

            <div className={ADMIN_CARD}>
              <div className="p-4 border-b border-slate-100 flex items-center justify-between">
                <div className="text-sm font-bold text-slate-900">
                  Pending verifications
                </div>
                <span className="text-xs text-slate-500">{pendingTotal} items</span>
              </div>
              <div className="p-4 max-h-64 overflow-y-auto space-y-2">
                {pendingVerifications.length === 0 ? (
                  <div className="text-xs text-slate-500 py-4 text-center">
                    No pending verifications
                  </div>
                ) : (
                  pendingVerifications.slice(0, 6).map((p, idx) => (
                    <div
                      key={p?.id || p?.email || idx}
                      className="flex items-center gap-3 rounded-xl bg-slate-50 border border-slate-100 px-3 py-2"
                    >
                      <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600 shrink-0">
                        {p?.initials || "?"}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="text-xs font-semibold text-slate-800 truncate">
                          {p?.name || "—"}
                        </div>
                        <div className="text-[11px] text-slate-500 truncate">
                          {p?.email || p?.role || "—"}
                        </div>
                      </div>
                      <span className="text-[11px] font-medium text-amber-600 shrink-0">
                        Pending
                      </span>
                    </div>
                  ))
                )}
                {pendingVerifications.length > 0 && (
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/operation/verifications`)}
                    className="w-full h-9 rounded-xl border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50"
                  >
                    See all
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ===================== Freelancer (v2 like screenshot) ===================== */
function FreelancerDashboard() {
  const navigate = useNavigate();
  const base = useRoleBase();
  const { userData, user } = useSelector((s) => s.auth || {});
  const userLabel =
    userData?.username ||
    [userData?.first_name, userData?.last_name].filter(Boolean).join(" ") ||
    user?.username ||
    "Freelancer";

  const [query, setQuery] = useState("");
  const [balanceCards, setBalanceCards] = useState([]);
  const [activeProjects, setActiveProjects] = useState([]);
  const [myProjects, setMyProjects] = useState([]);
  const [subscriptionStatus, setSubscriptionStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    try {
      setLoading(true);
      setError("");
      const payload = await fetchFreelancerDashboard();

      setBalanceCards(
        Array.isArray(payload?.balanceCards) ? payload.balanceCards : []
      );
      setActiveProjects(
        Array.isArray(payload?.activeProjects) ? payload.activeProjects : []
      );
      setMyProjects(
        Array.isArray(payload?.myProjects) ? payload.myProjects : []
      );
      setSubscriptionStatus(payload?.subscriptionStatus || null);
    } catch (_) {
      setError("حدث خطأ أثناء تحميل بيانات لوحة التحكم.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const filteredActive = useMemo(() => {
    const q = String(query || "")
      .trim()
      .toLowerCase();
    if (!q) return myProjects;
    return (myProjects || []).filter((p) =>
      [p?.title, p?.client, p?.status, p?.due, p?.budget]
        .map((x) => String(x ?? "").toLowerCase())
        .join(" ")
        .includes(q)
    );
  }, [myProjects, query]);

  const openFreelancerProject = useCallback(
    (p) => {
      const pid = p?.id ?? p?._id ?? p?.project_id;
      if (!pid) navigate(`${base}/projects`);
      else navigate(`${base}/project/${pid}`);
    },
    [navigate, base]
  );

  // progress percent (best effort): available/total if values exist
  const totalBal = parseNumberLike(balanceCards?.[0]?.value);
  const availBal = parseNumberLike(balanceCards?.[1]?.value);
  const pct =
    totalBal && availBal != null && totalBal > 0
      ? Math.round((availBal / totalBal) * 100)
      : 32;

  // ✅ Account activation steps (hidden until ready — set to true when verification flow is complete)
  const SHOW_ACCOUNT_ACTIVATION = false;
  const verifyHref = `${base}/contract-terms`;
  const accountVerified = isAccountVerified(userData);

  const _stepsRaw = [
    {
      id: "verify",
      title: "Verify your account",
      description: "Verify your identity to unlock full features.",
      href: verifyHref,
      done: accountVerified,
    },
  ];

  let _foundCurrent = false;
  const activationSteps = _stepsRaw.map((s) => {
    if (s.done) return { ...s, status: "done" };
    if (_stepsRaw.length === 1) return { ...s, status: "pending" }; // grey
    if (!_foundCurrent) {
      _foundCurrent = true;
      return { ...s, status: "current" };
    }
    return { ...s, status: "pending" };
  });

  const stepsLeft = activationSteps.filter((s) => s.status !== "done").length;
  const currentStep =
    activationSteps.find((s) => s.status === "current") || activationSteps[0];

  const activationCtaHref = currentStep?.href || verifyHref;
  const activationCtaLabel = accountVerified
    ? "View profile"
    : currentStep?.id === "verify"
    ? "Start verification"
    : "Continue";

  const showSkeleton =
    loading &&
    !error &&
    balanceCards.length === 0 &&
    myProjects.length === 0 &&
    activeProjects.length === 0;

  if (showSkeleton) return <DashboardSkeletonV2 />;

  return (
    <div className={cx(UI.pageBg)}>
      <div className={UI.container}>
        <div className="space-y-4">
          {/* Top bar */}
          {/* <DashTopBar
            query={query}
            setQuery={setQuery}
            userLabel={userLabel}
            onInbox={() => navigate(`${base}/inbox`)}
          /> */}

          {error ? (
            <div className="text-xs text-rose-600 bg-rose-50 border border-rose-100 rounded-2xl px-3 py-2">
              {error}
            </div>
          ) : null}

          {/* Main grid */}
          <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px]">
            {/* LEFT */}
            <div>
              <HelloSticker
                name={userLabel}
                subtitle="help you reach your full potential"
              />
              <HeroBanner
                eyebrow="FREELANCER DASHBOARD"
                title="Manage your work, deliver faster, earn more."
                subtitle="Track active projects and jump into new client opportunities."
                ctaLabel="Browse projects"
                onCta={() => navigate(`${base}/projects`)}
                rightSlot={
                  <button
                    type="button"
                    onClick={load}
                    className="h-11 px-4 rounded-2xl bg-white/15 hover:bg-white/20 text-white border border-white/20 text-sm font-semibold inline-flex items-center gap-2"
                  >
                    <RefreshCw
                      className={cx("h-4 w-4", loading ? "animate-spin" : "")}
                    />
                    Refresh
                  </button>
                }
              />

              {/* KPI row */}
              <KpiRow items={balanceCards} />

              {/* My projects: last 8, incomplete first */}
              <ContinueSection
                title="My projects"
                rightAction={
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/projects`)}
                    className="text-[11px] font-semibold text-slate-500 hover:text-slate-700 inline-flex items-center gap-1"
                  >
                    See all <ArrowUpRight className="h-3.5 w-3.5" />
                  </button>
                }
                items={filteredActive}
                renderItem={(p, i) => (
                  <ContinueCarouselCard
                    key={p?.id || p?._id || i}
                    badge={p?.status || p?.completion_status || "Project"}
                    title={p?.title || "Untitled"}
                    metaLeft={
                      (p?.completion_status &&
                        `Status: ${p.completion_status}`) ||
                      (p?.status && `Status: ${p.status}`) ||
                      "—"
                    }
                    metaRight={p?.amount_to_pay ?? p?.budget ?? ""}
                    onOpen={() =>
                      p?.id
                        ? navigate(`${base}/project/${p.id}`)
                        : navigate(`${base}/projects`)
                    }
                  />
                )}
              />

              {/* Latest Projects mini-table (Your Lesson style) */}
            
            </div>

            {/* RIGHT */}
            <div className="space-y-6 w-full xl:w-[360px] xl:justify-self-end">
              <RingProgress
                percent={pct}
                label={`Good morning ${userLabel} 🔥`}
                subLabel="Stay on top of deliveries and deadlines."
                extra={SHOW_ACCOUNT_ACTIVATION ? (
                  <ActivationStepperCard
                    embedded
                    title="Account activation"
                    stepsLeft={stepsLeft}
                    steps={activationSteps}
                    ctaLabel={activationCtaLabel}
                    onCta={() => navigate(activationCtaHref)}
                    onStep={(href) => href && navigate(href)}
                  />
                ) : null}
              />

              <div className={cx(UI.card, "p-5")} style={UI.ring}>
                <div className="text-sm font-extrabold text-slate-900">
                  Quick actions
                </div>
                <div className="mt-4 grid gap-2">
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/projects`)}
                    className="h-11 rounded-2xl bg-white border border-slate-200/70 hover:bg-slate-50 text-sm font-semibold text-slate-800 px-4 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      <ClipboardList className="h-4 w-4 text-orange-600" />
                      View my projects
                    </span>
                    <ArrowRight className="h-4 w-4 text-slate-400" />
                  </button>

                  <button
                    type="button"
                    onClick={() => navigate(`${base}/payments`)}
                    className="h-11 rounded-2xl bg-white border border-slate-200/70 hover:bg-slate-50 text-sm font-semibold text-slate-800 px-4 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      <CreditCard className="h-4 w-4 text-orange-600" />
                      Go to payouts
                    </span>
                    <ArrowRight className="h-4 w-4 text-slate-400" />
                  </button>
                </div>
              </div>
              <SubscriptionCard subscriptionStatus={subscriptionStatus} loading={loading} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ===================== Latest Projects mini-table (Your Lesson style) ===================== */
function getProjectTime(p) {
  const raw = p?.created_at ?? p?.createdAt ?? p?.posted_at ?? p?.updated_at ?? "";
  if (raw) {
    const t = new Date(raw).getTime();
    if (!Number.isNaN(t)) return t;
  }
  const id = Number(p?.id ?? p?._id ?? p?.project_id ?? 0);
  return id;
}

function formatProjectDate(p) {
  const raw = p?.created_at ?? p?.createdAt ?? p?.posted_at ?? p?.updated_at ?? "";
  if (!raw) return "";
  try {
    const d = new Date(raw);
    return Number.isNaN(d.getTime()) ? "" : d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
  } catch {
    return "";
  }
}

function pickType(p) {
  return p?.type ?? p?.project_type ?? p?.category ?? p?.category_name ?? p?.status ?? "PROJECT";
}

function pickDesc(p) {
  const d = p?.description ?? p?.short_description ?? p?.title ?? "";
  return typeof d === "string" ? d : String(d || "—");
}

function LatestProjectsMiniTable({ title = "Your Lesson", items = [], loading, onSeeAll, onOpen, mode = "client" }) {
  const list = Array.isArray(items) ? items : [];
  const col1Label = mode === "freelancer" ? "Client" : "Project";

  function getRowLabel(p) {
    if (mode === "freelancer") {
      return p?.client_name ?? p?.client ?? p?.owner_name ?? p?.title ?? "—";
    }
    return p?.title ?? "Untitled";
  }

  function getAvatarUrl(p) {
    return p?.avatar_url ?? p?.client_avatar ?? p?.cover ?? p?.image ?? "";
  }

 
}

/* ===================== Client/Partner (v2 like screenshot) ===================== */
function ClientDashboard() {
  const navigate = useNavigate();
  const base = useRoleBase();
  const { userData, user } = useSelector((s) => s.auth || {});
  const userLabel =
    userData?.username ||
    [userData?.first_name, userData?.last_name].filter(Boolean).join(" ") ||
    user?.username ||
    "Client";

  const [query, setQuery] = useState("");
  const [stats, setStats] = useState([]);
  const [recentProjects, setRecentProjects] = useState([]);
  const [myProjects, setMyProjects] = useState([]);
  const [actionableItems, setActionableItems] = useState([]);
  const [financialOverview, setFinancialOverview] = useState({
    moneyInEscrow: 0,
    totalReleased: 0,
    totalRefunded: 0,
  });
  const [attention, setAttention] = useState({
    pendingReviews: [],
  });
  const { pathname } = useLocation();
  const roleBase = useMemo(() => {
    const seg = (pathname.split("/")[1] || "").toLowerCase();
    return ["admin", "client", "freelancer", "partner"].includes(seg)
      ? `/${seg}`
      : "/admin";
  }, [pathname]);
  const openProjectDetails = (p) => {
    const pid = p?.id ?? p?._id ?? p?.project_id;
    if (!pid) return navigate(`${roleBase}/projects`);

    const role = roleBase.replace("/", ""); // "client" | "freelancer" | "admin" ...
    navigate(`${roleBase}/project/${pid}`, {
      state: { project: p, readOnly: true, role },
    });
  };

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    try {
      setLoading(true);
      setError("");

      const payload = await fetchClientDashboard();

      setStats(Array.isArray(payload?.stats) ? payload.stats : []);
      setRecentProjects(
        Array.isArray(payload?.recentProjects) ? payload.recentProjects : []
      );
      setMyProjects(Array.isArray(payload?.myProjects) ? payload.myProjects : []);
      setActionableItems(
        Array.isArray(payload?.actionableItems) ? payload.actionableItems : []
      );
      setFinancialOverview(
        payload?.financialOverview || {
          moneyInEscrow: 0,
          totalReleased: 0,
          totalRefunded: 0,
        }
      );
      setAttention({
        pendingReviews: Array.isArray(payload?.attention?.pendingReviews)
          ? payload.attention.pendingReviews
          : [],
      });
    } catch (_) {
      setError("Failed to load dashboard data. Please try again.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const filteredRecent = useMemo(() => {
    const q = String(query || "")
      .trim()
      .toLowerCase();
    if (!q) return recentProjects;
    return (recentProjects || []).filter((p) =>
      [p?.title, p?.status, p?.completion_status, p?.budget]
        .map((x) => String(x ?? "").toLowerCase())
        .join(" ")
        .includes(q)
    );
  }, [recentProjects, query]);

  const filteredMyProjects = useMemo(() => {
    const q = String(query || "")
      .trim()
      .toLowerCase();
    if (!q) return myProjects;
    return (myProjects || []).filter((p) =>
      [p?.title, p?.status, p?.completion_status, p?.budget]
        .map((x) => String(x ?? "").toLowerCase())
        .join(" ")
        .includes(q)
    );
  }, [myProjects, query]);

  // Latest 5 projects (newest first) for mini-table
  const latestClientFive = useMemo(() => {
    const list = Array.isArray(recentProjects) ? [...recentProjects] : [];
    list.sort((a, b) => getProjectTime(b) - getProjectTime(a));
    return list.slice(0, 5);
  }, [recentProjects]);

  const showSkeleton =
    loading &&
    !error &&
    stats.length === 0 &&
    recentProjects.length === 0 &&
    myProjects.length === 0 &&
    !attention.pendingReviews.length;

  if (showSkeleton) return <DashboardSkeletonV2 />;

  return (
    <div className={cx(UI.pageBg)} dir="ltr">
      <div className={UI.container}>
        <div className="space-y-4">
          {/* Top bar */}
          {/* <DashTopBar
            query={query}
            setQuery={setQuery}
            userLabel={userLabel}
            onInbox={() => navigate(`${base}/inbox`)}
          /> */}

          {error ? (
            <div className="text-xs text-rose-600 bg-rose-50 border border-rose-100 rounded-2xl px-3 py-2">
              {error}
            </div>
          ) : null}

          {/* Main grid */}
          <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px]">
            {/* LEFT */}
            <div>
              <HelloSticker
                name={userLabel}
                subtitle="help you reach your full potential"
              />

              <HeroBanner
                eyebrow="CLIENT DASHBOARD"
                title="Create projects, review deliveries, and pay securely."
                subtitle="Everything you need to keep your projects moving—fast."
                ctaLabel="Create project"
                onCta={() => navigate(`/create-project`)}
                rightSlot={
                  <button
                    type="button"
                    onClick={load}
                    className="h-11 px-4 rounded-2xl bg-white/15 hover:bg-white/20 text-white border border-white/20 text-sm font-semibold inline-flex items-center gap-2"
                  >
                    <RefreshCw
                      className={cx("h-4 w-4", loading ? "animate-spin" : "")}
                    />
                    Refresh
                  </button>
                }
              />

              {/* KPI row (from stats) */}
              <KpiRow items={(stats || []).slice(0, 6)} />

              {/* My projects: last 8, incomplete first */}
              <ContinueSection
                title="My projects"
                rightAction={
                  <button
                    type="button"
                    onClick={() => navigate(`${base}/projects`)}
                    className="text-[11px] font-semibold text-slate-500 hover:text-slate-700 inline-flex items-center gap-1"
                  >
                    See all <ArrowUpRight className="h-3.5 w-3.5" />
                  </button>
                }
                items={filteredMyProjects}
                renderItem={(p, i) => (
                  <ContinueCarouselCard
                    key={p?.id || p?._id || i}
                    badge={p?.status || p?.completion_status || "Project"}
                    title={p?.title || "Untitled"}
                    metaLeft={
                      (p?.completion_status &&
                        `Status: ${p.completion_status}`) ||
                      (p?.status && `Status: ${p.status}`) ||
                      "—"
                    }
                    metaRight={p?.amount_to_pay ?? p?.budget ?? ""}
                    onOpen={() =>
                      p?.id
                        ? openProjectDetails(p)
                        : navigate(`${base}/projects`)
                    }
                  />
                )}
              />

              {/* Latest Projects mini-table (Your Lesson style) */}
              <LatestProjectsMiniTable
                title="Your Lesson"
                items={latestClientFive}
                loading={loading}
                mode="client"
                onSeeAll={() => navigate(`${base}/projects`)}
                onOpen={openProjectDetails}
              />
            </div>

            {/* RIGHT */}
            <div className="space-y-6 w-full xl:w-[360px] xl:justify-self-end">
              {/* Financial Overview Card */}
              <FinancialOverviewCard
                moneyInEscrow={financialOverview.moneyInEscrow}
                totalReleased={financialOverview.totalReleased}
                totalRefunded={financialOverview.totalRefunded}
              />

              {/* Needs your action - Real actionable items */}
              <RightListCard
                title="Needs your action"
                items={actionableItems.map((item) => ({
                  id: item.id,
                  _type: item.type,
                  title: item.title,
                  projectTitle: item.projectTitle,
                  reason: item.reason,
                  amount: item.amount,
                  actionLabel: item.actionLabel,
                  href: item.href,
                  projectId: item.projectId,
                }))}
                onSeeAll={() => {
                  // Navigate to most relevant page based on action types
                  const hasDeliveries = actionableItems.some((a) => a.type === "approve_delivery");
                  const hasPayments = actionableItems.some((a) => a.type === "complete_payment" || a.type === "release_escrow");
                  
                  if (hasDeliveries) {
                    // Navigate to projects filtered by delivered status
                    navigate(`${base}/projects?status=delivered`);
                  } else if (hasPayments) {
                    navigate(`${base}/payments`);
                  } else {
                    navigate(`${base}/projects`);
                  }
                }}
                renderRow={(it) => (
                  <>
                    <div className="min-w-0 flex-1">
                      <div className="text-xs font-extrabold text-slate-900 truncate">
                        {it?.title || "Action required"}
                      </div>
                      <div className="text-[11px] text-slate-500 truncate mt-0.5">
                        {it?.projectTitle || "Project"} {it?.reason ? ` • ${it.reason}` : ""}
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        if (it?.href) {
                          navigate(it.href);
                        } else if (it?._type === "complete_payment" || it?._type === "release_escrow") {
                          navigate(`${base}/payments`);
                        } else if (it?.projectId) {
                          navigate(`${base}/project/${it.projectId}`);
                        } else {
                          navigate(`${base}/projects`);
                        }
                      }}
                      className="shrink-0 h-9 px-3 rounded-2xl bg-white border border-slate-200/70 text-xs font-semibold text-slate-700 hover:bg-slate-50 whitespace-nowrap"
                    >
                      {it?.actionLabel || "View"}
                    </button>
                  </>
                )}
                emptyMessage="You're all caught up 🎉"
              />

              <div className={cx(UI.card, "p-5")} style={UI.ring}>
                <div className="text-sm font-extrabold text-slate-900">
                  Quick actions
                  <span className="ml-2 align-middle">
                    <InfoTip text="Shortcuts to keep things moving." />
                  </span>
                </div>

                <div className="mt-4 grid gap-2">
                  <button
                    type="button"
                    onClick={() => navigate(`/create-project`)}
                    className="h-11 rounded-2xl bg-white border border-slate-200/70 hover:bg-slate-50 text-sm font-semibold text-slate-800 px-4 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      <FolderPlus className="h-4 w-4 text-orange-600" />
                      Post a new project
                    </span>
                    <ArrowRight className="h-4 w-4 text-slate-400" />
                  </button>

                  <button
                    type="button"
                    onClick={() => navigate(`${base}/projects`)}
                    className="h-11 rounded-2xl bg-white border border-slate-200/70 hover:bg-slate-50 text-sm font-semibold text-slate-800 px-4 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      <ClipboardList className="h-4 w-4 text-orange-600" />
                      Go to my projects
                    </span>
                    <ArrowRight className="h-4 w-4 text-slate-400" />
                  </button>

                  <button
                    type="button"
                    onClick={() => navigate(`${base}/payments`)}
                    className="h-11 rounded-2xl bg-white border border-slate-200/70 hover:bg-slate-50 text-sm font-semibold text-slate-800 px-4 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      <Wallet className="h-4 w-4 text-emerald-600" />
                      Payments
                    </span>
                    <ArrowRight className="h-4 w-4 text-slate-400" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* (اختياري) مساحة تحت مثل "Your lesson" لو تبغى نضيف جدول/قائمة */}
        </div>
      </div>
    </div>
  );
}

/* ===================== Main exported component ===================== */
export default function Dashboard() {
  const { userData, roleId: storeRoleId } = useSelector((s) => s.auth || {});
  const outletCtx = useOutletContext() || {};
  const { clearTopBarRight } = outletCtx;

  useEffect(() => {
    clearTopBarRight?.();
  }, [clearTopBarRight]);

  const rawRoleId =
    userData?.role_id ??
    (typeof storeRoleId === "number"
      ? storeRoleId
      : Number(localStorage.getItem("roled")));

  const role = mapRole(Number(rawRoleId));

  return (
    <>
      <PageMeta title="Dashboard – OrderzHouse" description="Your OrderzHouse dashboard for projects and activity." />
      {role === "freelancer" && <FreelancerDashboard />}
      {(role === "client" || role === "partner") && <ClientDashboard />}
      {(role === "admin" || role === "user") && <AdminDashboard />}
    </>
  );
}
