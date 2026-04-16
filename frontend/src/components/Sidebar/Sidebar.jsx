import React, { useEffect, useMemo, useState } from "react";
import {
  LayoutDashboard,
  Inbox,
  BookOpen,
  ClipboardList,
  Users,
  FolderKanban,
  CheckSquare,
  CreditCard,
  Bell,
  User,
  LogOut,
  Menu,
  Home,
  X,
  Settings,
  FolderPlus,
  ListPlus,
} from "lucide-react";
import { Link, useLocation } from "react-router-dom";
import { useSelector } from "react-redux";
import API from "../../api/client.js";

/**
 * Desktop: تصميم مشابه للصورة (Logo + أقسام: OVERVIEW / FRIENDS / SETTINGS)
 * Mobile: نفس التصميم الحالي لكن تغيير الألوان فقط
 */
const Sidebar = ({
  activePage,
  setActivePage,
  isMobileMenuOpen = false,
  setIsMobileMenuOpen,
  navigation = [],
  bottomNavigation = [],
  onLogout,
  showDesktopSidebar = true,

  // Role based mobile behavior
  role = "admin",
  onCreateProject,
  onCreateTask,

  // Optional (Desktop only)
  appName = "Coursue",
  friends = [], // [{ id, name, subtitle, avatarUrl }]
  onFriendClick,
}) => {
  // Avoid undefined crashes
  const safeSetActivePage = setActivePage ?? (() => {});
  const safeSetIsMobileMenuOpen = setIsMobileMenuOpen ?? (() => {});

  const isAdmin = role === "admin";
  const isFreelancer = role === "freelancer";

  const findItemById = (id) =>
    [...navigation, ...bottomNavigation].find((it) => it?.id === id);

  // Bottom bar items (client/freelancer): Overview, Projects, Payments, Profile
  const mobileNav = (() => {
    if (!isAdmin) {
      const desired = ["overview", "projects", "payments", "profile"];
      const picked = desired.map(findItemById).filter(Boolean);
      if (picked.length === 4) return picked;
    }
    return navigation.slice(0, 4);
  })();

  const FabIcon = isAdmin ? Menu : isFreelancer ? ListPlus : FolderPlus;
  const fabAriaLabel = isAdmin
    ? "Open menu"
    : isFreelancer
    ? "Create task"
    : "Create project";

  const handleFabClick = () => {
    if (isAdmin) {
      safeSetIsMobileMenuOpen(!isMobileMenuOpen);
      return;
    }
    if (isFreelancer) {
      if (typeof onCreateTask === "function") onCreateTask();
      return;
    }
    if (typeof onCreateProject === "function") onCreateProject();
  };

  // Brand colors (غيرها مرة واحدة هنا)
  const BRAND = {
    primary: "#F97316", // بنفسجي مثل الصورة
    primarySoft: "#F97316",
    primaryRing: "#F97316",
    danger: "#F97316", // لون Logout بالصورة (برتقالي/أحمر)
  };


  const location = useLocation();
  const pathname = location?.pathname || "/";

  // ===== User profile (same endpoint used in Nav.jsx) =====
  const { token, userData } = useSelector((s) => s.auth || {});
  const [profile, setProfile] = useState(userData || null);
  const [profileLoading, setProfileLoading] = useState(false);

  useEffect(() => {
    if (userData) setProfile(userData);
  }, [userData]);

  useEffect(() => {
    if (!token) return;
    if (profile?.email) return;

    setProfileLoading(true);
    API
      .get("/users/getUserdata", {
        headers: { authorization: `Bearer ${token}` },
      })
      .then((res) => {
        const u =
          res?.data?.user ||
          res?.data?.data?.user ||
          res?.data?.data ||
          res?.data?.result ||
          null;
        if (u) setProfile(u);
      })
      .catch(() => {
        // Silently fail - don't crash the UI
        // Don't set profile to avoid infinite retries
      })
      .finally(() => setProfileLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, profile?.email]);

  const displayName = useMemo(() => {
    const name =
      profile?.username ||
      profile?.user_name ||
      profile?.name ||
      [profile?.first_name, profile?.last_name].filter(Boolean).join(" ") ||
      "";
    return name || appName || "User";
  }, [profile, appName]);

  const avatarChar = useMemo(() => {
    const c = (displayName || "U").trim().charAt(0);
    return (c || "U").toUpperCase();
  }, [displayName]);


  // Default icons (يدعم IDs قديمة + IDs جديدة مثل الصورة)
  const defaultIcons = {
    // new-like ids
    dashboard: LayoutDashboard,
    inbox: Inbox,
    lesson: BookOpen,
    task: ClipboardList,
    group: Users,

    // legacy ids (backwards compatible)
    projects: FolderKanban,
    tasks: CheckSquare,
    payments: CreditCard,
    notifications: Bell,
    profile: User,
    logout: LogOut,
    overview: Home,
    settings: Settings,
  };

  const isItemActive = (item) => {
    if (item?.path) {
      return pathname === item.path || pathname.startsWith(item.path + "/");
    }
    return activePage === item?.id;
  };

  const Clickable = ({
    item,
    children,
    onClick,
    className,
    "data-active": dataActive,
  }) => {
    const handleClick = (event) => {
      if (typeof item?.onClick === "function") item.onClick(event);
      if (typeof onClick === "function") onClick(event);
    };

    if (item?.path) {
      return (
        <Link
          to={item.path}
          onClick={handleClick}
          className={className}
          data-active={dataActive}
        >
          {children}
        </Link>
      );
    }

    return (
      <button
        type="button"
        onClick={handleClick}
        className={className}
        data-active={dataActive}
      >
        {children}
      </button>
    );
  };

  return (
    <>
      {/* ===================== Desktop Sidebar (NEW DESIGN) ===================== */}
      <aside
        className={`
          hidden lg:flex
          sticky top-0 self-start
          h-screen min-h-0
          bg-white border-r border-gray-100 shadow-sm
          flex-col overflow-hidden
          transition-all duration-300 ease-in-out
          ${showDesktopSidebar ? "lg:w-64" : "lg:w-0 overflow-hidden"}
        `}
      >
        {/* Top profile section - لا يتقلص */}
        <div className="flex-shrink-0 p-4 border-b border-gray-100">
          <div className="flex items-center gap-3 rounded-lg border border-gray-100 bg-white px-3 py-3 overflow-hidden">
            <div
              className="relative h-12 w-12 rounded-full flex items-center justify-center shrink-0 shadow-sm"
              style={{ background: BRAND.primary }}
              aria-hidden="true"
            >
              <span className="text-white font-extrabold text-lg uppercase">
                {avatarChar}
              </span>
            </div>

            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <div className="text-sm font-bold text-slate-900 truncate">
                  {displayName}
                </div>
                {profileLoading && (
                  <span className="text-[10px] text-slate-400 whitespace-nowrap">
                    Loading…
                  </span>
                )}
              </div>
              <div className="text-xs text-slate-500 truncate">
                {profile?.email || "—"}
              </div>
            </div>
          </div>
        </div>

        {/* منطقة OVERVIEW + spacer يملأ المساحة المتبقية حتى SETTINGS */}
        <nav
          className="sidebar-nav-scroll flex-1 min-h-0 flex flex-col overflow-y-auto overflow-x-hidden px-2 py-3"
          style={{ WebkitOverflowScrolling: "touch" }}
        >
          {/* OVERVIEW */}
          <div className="w-full flex-shrink-0">
            <div className="px-2 mb-3 text-[11px] font-semibold tracking-wider text-slate-400 uppercase">
              OVERVIEW
            </div>
            <div className="flex flex-col space-y-1">
              {navigation.map((item) => {
                const Icon = item.icon || defaultIcons[item.id] || User;
                const active = isItemActive(item);

                return (
                  <Clickable
                    key={item.id}
                    item={item}
                    onClick={() => safeSetActivePage(item.id)}
                    data-active={active ? "true" : "false"}
                    className={`
                      relative w-full flex items-center min-h-[44px] px-4 py-3 rounded-lg text-sm font-medium transition-all
                      hover:bg-gray-100 active:scale-[0.98]
                      ${active ? "bg-gray-100 text-slate-900" : "text-slate-700"}
                    `}
                  >
                    {active && (
                      <span className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 rounded-r-full bg-orange-500" />
                    )}
                    <Icon
                      className={`w-5 h-5 flex-shrink-0 mr-3 ${
                        active ? "text-orange-600" : "text-slate-500"
                      }`}
                    />
                    <span className="flex-1 min-w-0 text-center truncate">{item.name}</span>
                  </Clickable>
                );
              })}
            </div>
          </div>

          {/* FRIENDS */}
          {friends?.length > 0 && (
            <div className="w-full mt-6 flex-shrink-0">
              <div className="px-2 mb-3 text-[11px] font-semibold tracking-wider text-slate-400 uppercase">
                FRIENDS
              </div>
              <div className="flex flex-col gap-2">
                {friends.map((f) => (
                  <button
                    key={f.id ?? f.name}
                    type="button"
                    onClick={() => onFriendClick?.(f)}
                    className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left hover:bg-gray-50 transition-colors overflow-hidden"
                  >
                    <div
                      className="w-8 h-8 rounded-full flex items-center justify-center overflow-hidden flex-shrink-0"
                      style={{ background: BRAND.primarySoft }}
                    >
                      {f.avatarUrl ? (
                        <img
                          src={f.avatarUrl}
                          alt={f.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <span
                          className="text-xs font-semibold"
                          style={{ color: BRAND.primary }}
                        >
                          {(f.name?.charAt(0) || "U").toUpperCase()}
                        </span>
                      )}
                    </div>

                    <div className="min-w-0 flex-1">
                      <div className="text-sm font-medium text-slate-900 truncate">
                        {f.name}
                      </div>
                      <div className="text-xs text-slate-400 truncate">
                        {f.subtitle ?? ""}
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* مساحة مرنة تملأ الأسفل (كلينت/فريلانسر) + تذييل خفيف */}
          <div className="flex-1 min-h-[60px] flex flex-col justify-end pt-4">
            {!isAdmin && (
              <div className="px-2 pb-2 pt-3 flex-shrink-0 rounded-lg bg-slate-50/80 border border-slate-100">
                <p className="text-xs font-semibold text-slate-600 truncate">
                  {appName}
                </p>
                <a
                  href="/help"
                  className="text-[11px] text-slate-500 hover:text-orange-600 transition mt-1 inline-block"
                >
                  Need help?
                </a>
              </div>
            )}
          </div>
        </nav>

        {/* قسم SETTINGS ثابت في الأسفل */}
        <div className="flex-shrink-0 border-t border-gray-100 pt-4 pb-4 px-2 bg-white">
          <div className="px-2 mb-3 text-[11px] font-semibold tracking-wider text-slate-400 uppercase">
            SETTINGS
          </div>
          <div className="flex flex-col space-y-1">
            {bottomNavigation.map((item) => {
              const Icon = item.icon || defaultIcons[item.id] || User;
              const active = isItemActive(item);
              const isLogout = item.id === "logout";

              return (
                <Clickable
                  key={item.id}
                  item={item}
                  onClick={() => {
                    if (isLogout) onLogout?.();
                    else safeSetActivePage(item.id);
                  }}
                  data-active={active ? "true" : "false"}
                  className={`
                    relative w-full flex items-center min-h-[44px] px-4 py-3 rounded-lg text-sm font-medium transition-all
                    hover:bg-gray-100 active:scale-[0.98]
                    ${active ? "bg-gray-100 text-slate-900" : "text-slate-700"}
                    ${isLogout ? "text-orange-600 hover:text-orange-700" : ""}
                  `}
                >
                  {active && !isLogout && (
                    <span className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 rounded-r-full bg-orange-500" />
                  )}
                  <Icon
                    className={`w-5 h-5 flex-shrink-0 mr-3 ${
                      isLogout
                        ? "text-orange-600"
                        : active
                        ? "text-orange-600"
                        : "text-slate-500"
                    }`}
                  />
                  <span className="flex-1 min-w-0 text-center truncate">{item.name}</span>
                </Clickable>
              );
            })}
          </div>
        </div>
      </aside>

      {/* ===================== Mobile Bottom Tab Bar (SAME LAYOUT, NEW COLORS) ===================== */}
      <div className="lg:hidden fixed inset-x-0 bottom-0 z-50 pb-[env(safe-area-inset-bottom)]">
        <div className="mx-auto max-w-screen-sm">
          <div className="relative">
            {/* Bar */}
            <div className="h-16 bg-white/95 backdrop-blur border-t border-slate-200 shadow-sm rounded-t-2xl"></div>

            {/* Tabs */}
            <div className="absolute inset-0 flex items-center justify-between px-6">
              {/* Left */}
              <div className="flex items-center gap-6">
                {mobileNav.slice(0, 2).map((item) => {
                  const Icon = item.icon || defaultIcons[item.id] || User;
                  const active = isItemActive(item);
                  return (
                    <Clickable
                      key={item.id}
                      item={item}
                      onClick={() => {
                        safeSetActivePage(item.id);
                        safeSetIsMobileMenuOpen(false);
                      }}
                      className="flex flex-col items-center justify-center"
                    >
                      <>
                        <Icon
                          className="w-6 h-6"
                          style={{ color: active ? BRAND.primary : "#475569" }}
                        />
                        <span
                          className="text-[11px] mt-1"
                          style={{ color: active ? BRAND.primary : "#475569" }}
                        >
                          {item.name?.split(" ")[0] ?? item.name}
                        </span>
                      </>
                    </Clickable>
                  );
                })}
              </div>

              {/* Fab */}
              <div className="absolute left-1/2 -translate-x-1/2 -top-8 w-20 h-20 z-10">
                <span className="absolute inset-1 rounded-full bg-slate-400/20 shadow-[0_4px_20px_rgba(0,0,0,0.06)] pointer-events-none" />
                <button
                  onClick={handleFabClick}
                  className="absolute inset-0 m-auto w-14 h-14 rounded-full text-white shadow-lg ring-4 ring-white/60 flex items-center justify-center active:scale-95 transition"
                  style={{ background: BRAND.primary }}
                  aria-label={fabAriaLabel}
                >
                  <FabIcon className="w-6 h-6" />
                </button>
              </div>

              {/* Right */}
              <div className="flex items-center gap-6">
                {mobileNav.slice(2, 4).map((item) => {
                  const Icon = item.icon || defaultIcons[item.id] || User;
                  const active = isItemActive(item);
                  return (
                    <Clickable
                      key={item.id}
                      item={item}
                      onClick={() => {
                        safeSetActivePage(item.id);
                        safeSetIsMobileMenuOpen(false);
                      }}
                      className="flex flex-col items-center justify-center"
                    >
                      <>
                        <Icon
                          className="w-6 h-6"
                          style={{ color: active ? BRAND.primary : "#475569" }}
                        />
                        <span
                          className="text-[11px] mt-1"
                          style={{ color: active ? BRAND.primary : "#475569" }}
                        >
                          {item.name?.split(" ")[0] ?? item.name}
                        </span>
                      </>
                    </Clickable>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ===================== Mobile Command Sheet (SAME LAYOUT, NEW COLORS) ===================== */}
      {isAdmin && (
      <div
        className={`
          lg:hidden fixed inset-0 z-[60]
          transition-opacity duration-300
          ${
            isMobileMenuOpen
              ? "opacity-100 pointer-events-auto"
              : "opacity-0 pointer-events-none"
          }
        `}
      >
        {/* Backdrop */}
        <button
          className={`absolute inset-0 bg-black/40 transition-opacity duration-300 ${
            isMobileMenuOpen ? "opacity-100" : "opacity-0"
          }`}
          onClick={() => safeSetIsMobileMenuOpen(false)}
          aria-label="Close menu backdrop"
        />

        {/* Panel */}
        <div
          className={`
            absolute inset-x-0 bottom-0 max-h-[75vh] overflow-y-auto
            bg-white rounded-t-3xl shadow-xl p-4 pt-4
            pb-[max(16px,env(safe-area-inset-bottom))]
            transform transition-transform duration-300
            ${isMobileMenuOpen ? "translate-y-0" : "translate-y-full"}
          `}
        >
          {/* Close */}
          <div className="flex justify-center mb-3">
            <button
              onClick={() => safeSetIsMobileMenuOpen(false)}
              className="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:bg-slate-100 active:scale-95 transition"
              aria-label="Close menu"
              title="Close"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Grid main */}
          <div className="grid grid-cols-4 gap-3">
            {navigation.map((item) => {
              const Icon = item.icon || defaultIcons[item.id] || User;
              const active = isItemActive(item);
              return (
                <Clickable
                  key={item.id}
                  item={item}
                  onClick={() => {
                    safeSetActivePage(item.id);
                    safeSetIsMobileMenuOpen(false);
                  }}
                  className="flex flex-col items-center justify-center rounded-xl py-3"
                  style={{
                    background: active ? BRAND.primarySoft : "transparent",
                  }}
                >
                  <>
                    <Icon
                      className="w-6 h-6"
                      style={{ color: active ? BRAND.primary : "#334155" }}
                    />
                    <span className="text-[11px] mt-1 text-slate-700 text-center line-clamp-1">
                      {item.name}
                    </span>
                  </>
                </Clickable>
              );
            })}
          </div>

          {/* Divider */}
          <div className="mt-4 pt-3 border-t border-slate-200" />

          {/* Bottom grid */}
          <div className="grid grid-cols-4 gap-3 mt-2">
            {bottomNavigation.map((item) => {
              const Icon = item.icon || defaultIcons[item.id] || User;
              const active = isItemActive(item);
              const isLogout = item.id === "logout";

              return (
                <Clickable
                  key={item.id}
                  item={item}
                  onClick={() => {
                    if (isLogout) onLogout?.();
                    else safeSetActivePage(item.id);
                    safeSetIsMobileMenuOpen(false);
                  }}
                  className="flex flex-col items-center justify-center rounded-xl py-3"
                  style={{
                    background: active ? BRAND.primarySoft : "transparent",
                  }}
                >
                  <>
                    <Icon
                      className="w-6 h-6"
                      style={{
                        color: isLogout
                          ? BRAND.danger
                          : active
                          ? BRAND.primary
                          : "#334155",
                      }}
                    />
                    <span className="text-[11px] mt-1 text-slate-700 text-center line-clamp-1">
                      {item.name}
                    </span>
                  </>
                </Clickable>
              );
            })}
          </div>
        </div>
      </div>
      )}

      <style>{`
        .sidebar-scroll {
          scrollbar-width: thin;
          scrollbar-color: ${BRAND.primaryRing} transparent;
        }
        .sidebar-scroll::-webkit-scrollbar { width: 6px; }
        .sidebar-scroll::-webkit-scrollbar-track { background: transparent; }
        .sidebar-scroll::-webkit-scrollbar-thumb {
          background-color: ${BRAND.primaryRing};
          border-radius: 999px;
        }
        .sidebar-scroll::-webkit-scrollbar-thumb:hover {
          background-color: ${BRAND.primaryRing};
        }
      `}</style>
    </>
  );
};

export default Sidebar;
