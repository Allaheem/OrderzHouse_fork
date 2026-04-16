import { useState, useEffect, useRef } from "react";
import {
  ChevronDown,
  Bell,
  User,
  LogOut,
  Plus,
  LayoutDashboard,
} from "lucide-react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { logout, setUserData } from "../../slice/auth/authSlice";
import API, { clearProactiveRefresh } from "../../api/client.js";
import { disconnectSocket } from "../../services/socketService";
import CategoryMegaMenu from "../Catigories/CategoryMegaMenu";


const ORANGE = "#C2410C";
const ORANGE_DARK = "#9A3412";

// نفس ستايل روابط الهيدر
const TOP_LINK_BASE =
  "px-3 py-2 text-sm font-semibold tracking-wide transition-colors duration-150 rounded-full";

export default function Header() {
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [activeLink, setActiveLink] = useState(null);
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isExploreOpen, setIsExploreOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const userMenuRef = useRef(null);
  const notificationsRef = useRef(null);
  const exploreRef = useRef(null);

  const dispatch = useDispatch();
  const { token, userData, isAuthenticated } = useSelector((state) => state.auth);
  const IsAuthenticated = isAuthenticated && !!token;

  const navigate = useNavigate();
  const location = useLocation();
  const pathname = (location.pathname || "").toLowerCase();

  const isDashboardRoute =
    /^\/(admin|client|freelancer|apm|partner)(\/|$)/.test(pathname);

  // ✅ خلي Projects + Blogs نفس منطق الداشبورد
  // TEMPORARILY HIDDEN FOR LAUNCH - blogs removed from regex but code kept
  const isDashboardLike =
    isDashboardRoute || /^\/(projectspage|projects)(\/|$)/.test(pathname);

  const [dashExpanded, setDashExpanded] = useState(false);

  useEffect(() => {
    if (!isDashboardLike) {
      setDashExpanded(false);
      return;
    }
    setDashExpanded(false);
    requestAnimationFrame(() => setDashExpanded(true));
  }, [isDashboardLike]);

  // ===== Active link (نفس منطق ملفك) =====
  useEffect(() => {
    const p = (location.pathname || "").toLowerCase();
    if (p === "/") setActiveLink("HOME");
    else if (p.startsWith("/about")) setActiveLink("ABOUT US");
    // TEMPORARILY HIDDEN FOR LAUNCH - DO NOT DELETE
    // else if (p.startsWith("/blogs")) setActiveLink("BLOGS");
    else if (p.startsWith("/contact")) setActiveLink("CONTACT");
    else if (p.startsWith("/plans")) setActiveLink("PLANS");
    else if (
      p.startsWith("/projects") ||
      p.startsWith("/projectspage") ||
      p.startsWith("/dashboard/projects")
    ) {
      setActiveLink("PROJECTS");
    } else if (p.startsWith("/create-project")) setActiveLink("ADD PROJECT");
    else setActiveLink(null);
  }, [location.pathname]);

  // ===== Notifications =====
  const fetchNotifications = async () => {
    if (!token) return;
    try {
      const { data } = await API.get("/notifications", {
        headers: { authorization: `Bearer ${token}` },
        params: { limit: 10, unreadOnly: false },
      });
      if (data.success) setNotifications(data.notifications);
    } catch (_) {
    }
  };

  const fetchUnreadCount = async () => {
    if (!token) return;
    try {
      const { data } = await API.get("/notifications/count", {
        headers: { authorization: `Bearer ${token}` },
        params: { unreadOnly: true },
      });
      if (data.success) setUnreadCount(data.count);
    } catch (_) {
    }
  };

  const markAsRead = async (id) => {
    const wasUnread = notifications.some((n) => n.id === id && !n.read_status);
    try {
      await API.put(
        `/notifications/${id}/read`,
        {},
        { headers: { authorization: `Bearer ${token}` } }
      );
      setNotifications((list) =>
        list.map((n) => (n.id === id ? { ...n, read_status: true } : n))
      );
      if (wasUnread) setUnreadCount((prev) => Math.max(0, prev - 1));
    } catch (_) {
    }
  };

  const markAllAsRead = async () => {
    try {
      await API.put(
        "/notifications/read-all",
        {},
        { headers: { authorization: `Bearer ${token}` } }
      );
      setNotifications((list) =>
        list.map((n) => ({ ...n, read_status: true }))
      );
      setUnreadCount(0);
    } catch (_) {
    }
  };

  // ===== Logout =====
  const handleLogout = () => {
    disconnectSocket();
    clearProactiveRefresh();
    API.post("/users/logout").catch(() => {}); // clear refresh cookie
    dispatch(logout());
    navigate("/", { replace: true });
    window.location.reload();
  };

  const handleNavigation = (path, label) => {
    setActiveLink(label);
    navigate(path);
    setIsExploreOpen(false);
    setIsMobileMenuOpen(false);
  };

  // ===== Load user + notifications =====
  useEffect(() => {
    if (!token) return;
    API
      .get("/users/getUserdata", {

        headers: { authorization: `Bearer ${token}` },
      })
      .then((res) => {
        dispatch(setUserData(res.data.user));
        fetchNotifications();
        fetchUnreadCount();
      })
      .catch((error) => {
        const code = error.response?.data?.code;
        const status = error.response?.status;
        // عدم إظهار لوحة قبول الشروط تلقائياً — المستخدم يبقى في الصفحة الحالية
        if (status === 403 && code === "TERMS_NOT_ACCEPTED") {
          return;
        }
        if (status === 401 || status === 403) {
          handleLogout();
          return;
        }
        if (error.code === "ERR_NETWORK" || error.message?.includes("Network Error")) {
          // Network error: Server may be unreachable
        }
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch, token]);

  // ===== Close on outside click =====
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (userMenuRef.current && !userMenuRef.current.contains(e.target))
        setIsUserMenuOpen(false);
      if (
        notificationsRef.current &&
        !notificationsRef.current.contains(e.target)
      )
        setIsNotificationsOpen(false);
      if (exploreRef.current && !exploreRef.current.contains(e.target))
        setIsExploreOpen(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const getDashboardPath = (roleId) => {
    switch (Number(roleId)) {
      case 1:
        return "/admin";
      case 2:
        return "/client";
      case 3:
        return "/freelancer";
      case 4:
        return "/apm";
      case 5:
        return "/partner";
      default:
        return "/login";
    }
  };

  // ===== Links ===== (Dashboard مخفي من الهيدر – متوفر في قائمة المستخدم فقط)
  const navLinks = [
    { label: "Home", path: "/", condition: true },
    {
      label: "Projects",
      path: "/projectsPage",
      condition:
        userData &&
        (userData.role_id === 1 ||
          userData.role_id === 2 ||
          userData.role_id === 3),
    },
  ];

  const exploreItems = [
    { label: "ABOUT US", path: "/about" },
    // TEMPORARILY HIDDEN FOR LAUNCH - DO NOT DELETE
    // { label: "BLOGS", path: "/blogs" },
    { label: "CONTACT", path: "/contact" },
    { label: "PLANS", path: "/plans" },
  ];

  const isExploreActive = exploreItems.some(
    (item) => item.label === activeLink
  );

  // ✅ ألوان الثيم البرتقالي
  const ACCENT = "text-gray-900";
  const ACCENT_HOVER = "hover:text-gray-900";
  const ACCENT_BORDER = "border-gray-600";

  return (
    <header
      className={[
        "z-[9999]",
        isDashboardLike ? "relative" : "fixed inset-x-0 top-0",
      ].join(" ")}
    >
      <div
        className={[
          isDashboardLike
            ? "w-full px-0 transition-[padding] duration-500 ease-[cubic-bezier(.22,1,.36,1)]"
            : "mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 pt-2 sm:pt-3",
          isDashboardLike ? (dashExpanded ? "pt-0" : "pt-6") : "",
        ].join(" ")}
      >
        <nav
          className={[
            "mx-auto bg-white/95 backdrop-blur ring-1 ring-black/10",
            "transition-[max-width,border-radius,box-shadow,transform] duration-500 ease-[cubic-bezier(.22,1,.36,1)]",
            isDashboardLike
              ? "w-full py-3"
              : "max-w-[980px] rounded-full py-3 shadow-[0_18px_45px_rgba(0,0,0,0.12)]",
            isDashboardLike &&
              (dashExpanded ? "rounded-none shadow-sm" : "rounded-full"),
          ].join(" ")}
          style={
            isDashboardLike
              ? { maxWidth: dashExpanded ? "100%" : "980px" }
              : undefined
          }
          aria-label="Primary"
        >
          <div
            className={[
              "mx-auto w-full max-w-[1265px] flex items-center justify-between",
              isDashboardLike ? "px-6" : "px-5 sm:px-6",
            ].join(" ")}
          >
            {/* Left */}
            <div className="flex items-center gap-4 sm:gap-8">
              <button
                onClick={() => handleNavigation("/", "HOME")}
                className="text-[15px] font-extrabold tracking-tight text-gray-900"
              >
                Orderz House
              </button>

              {/* Desktop links (lg+) */}
              <div className="hidden lg:flex items-center gap-1">
                {navLinks.map(
                  (item) =>
                    item.condition && (
                      <button
                        key={item.label}
                        onClick={() => handleNavigation(item.path, item.label)}
                        className={[
                          TOP_LINK_BASE,
                          activeLink === item.label
                            ? ACCENT
                            : `text-gray-600 ${ACCENT_HOVER}`,
                        ].join(" ")}
                      >
                        {item.label}
                      </button>
                    )
                )}

                {/* EXPLORE */}
                <div className="relative" ref={exploreRef}>
                  <button
                    onClick={() => setIsExploreOpen((v) => !v)}
                    className={[
                      TOP_LINK_BASE,
                      isExploreActive
                        ? ACCENT
                        : `text-gray-600 ${ACCENT_HOVER}`,
                    ].join(" ")}
                  >
                    Explore
                    <ChevronDown
                      className={`ml-1 h-4 w-4 inline transition-transform ${
                        isExploreOpen ? "rotate-180" : ""
                      }`}
                    />
                  </button>

                  {isExploreOpen && (
                    <div className="absolute left-0 mt-2 w-52 rounded-2xl bg-white shadow-2xl ring-1 ring-black/10 overflow-hidden">
                      {exploreItems.map((it) => (
                        <button
                          key={it.label}
                          onClick={() => handleNavigation(it.path, it.label)}
                          className={`w-full text-left px-4 py-2.5 text-sm text-gray-700 ${ACCENT_HOVER} hover:bg-gray-50`}
                        >
                          {it.label}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* Categories Mega Menu */}
                <CategoryMegaMenu
                  activeLink={activeLink}
                  onSetActiveLink={setActiveLink}
                />
              </div>
            </div>

            {/* Right */}
            <div className="flex items-center gap-2 sm:gap-4">
              {/* Mobile menu button ( < lg ) */}
              <button
                onClick={() => setIsMobileMenuOpen(true)}
                className={`inline-flex lg:hidden p-2 rounded-full text-gray-700 ${ACCENT_HOVER}`}
                aria-label="Open main menu"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-7 w-7"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                </svg>
              </button>

              {/* Desktop right (lg+) */}
              <div className="hidden lg:flex items-center gap-3">
                {/* Add project (client role) */}
                {userData?.role_id === 2 && (
                  <Link
                    to="/create-project"
                    className={[
                      "inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-full border text-gray-600",
                      ACCENT_BORDER,
                      "hover:text-gray-900 hover:border-gray-900 transition-colors",
                    ].join(" ")}
                  >
                    <Plus className="h-4 w-4" /> Add project
                  </Link>
                )}

                {/* Notifications */}
                {IsAuthenticated && (
                  <div className="relative" ref={notificationsRef}>
                    <button
                      onClick={() => {
                        setIsNotificationsOpen(!isNotificationsOpen);
                        if (!isNotificationsOpen) fetchNotifications();
                      }}
                      className={`p-2 text-gray-600 ${ACCENT_HOVER} relative transition-colors duration-150`}
                      aria-label="Notifications"
                    >
                      <Bell className="h-5 w-5" />
                      {unreadCount > 0 && (
                        <span className="absolute -top-1 -right-1 h-4 w-4 bg-red-500 text-white text-xs flex items-center justify-center rounded-full">
                          {unreadCount > 9 ? "9+" : unreadCount}
                        </span>
                      )}
                    </button>

                    {isNotificationsOpen && (
                      <div className="absolute right-0 mt-2 w-80 bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden z-50">
                        <div className="p-4 border-b flex justify-between items-center">
                          <h3 className="font-semibold text-gray-900">
                            Notifications
                          </h3>
                          {unreadCount > 0 && (
                            <button
                              onClick={markAllAsRead}
                              className="text-xs"
                              style={{ color: ORANGE }}
                            >
                              Mark all as read
                            </button>
                          )}
                        </div>

                        <div className="max-h-96 overflow-y-auto">
                          {notifications.length > 0 ? (
                            notifications.map((n) => {
                              const isUnread = !n.read_status;
                              return (
                                <div
                                  key={n.id}
                                  className={`p-4 cursor-pointer ${
                                    isUnread ? "bg-orange-50/60" : ""
                                  } hover:bg-gray-50`}
                                  onClick={() => markAsRead(n.id)}
                                >
                                  <div className="flex items-start justify-between gap-2">
                                    <p className="text-sm text-gray-900 flex-1">
                                      {n.message}
                                    </p>
                                    {isUnread && (
                                      <span className="shrink-0 px-2 py-0.5 text-xs font-medium rounded-full border border-amber-300 bg-amber-50 text-amber-800">
                                        New
                                      </span>
                                    )}
                                  </div>
                                  <p className="text-xs text-gray-400 mt-2">
                                    {new Date(n.created_at).toLocaleDateString()}
                                  </p>
                                </div>
                              );
                            })
                          ) : (
                            <div className="p-8 text-center text-gray-500 text-sm">
                              No notifications yet
                            </div>
                          )}
                        </div>

                        <div className="p-4 border-t text-center">
                          <Link
                            to="/notifications"
                            onClick={() => setIsNotificationsOpen(false)}
                            className="text-sm"
                            style={{ color: ORANGE }}
                          >
                            View all notifications
                          </Link>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* User menu */}
                {IsAuthenticated && userData ? (
                  <div className="relative" ref={userMenuRef}>
                    <button
                      onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                      className={`flex items-center gap-2 p-2 text-gray-700 ${ACCENT_HOVER} transition-colors duration-150`}
                    >
                      <div
                        className="relative w-8 h-8 rounded-full flex items-center justify-center shrink-0 shadow-sm text-white font-bold text-sm uppercase"
                        style={{ backgroundColor: ORANGE }}
                      >
                        {`${userData.first_name?.[0]}`}
                      </div>

                      <ChevronDown
                        className={`h-4 w-4 transition-transform ${
                          isUserMenuOpen ? "rotate-180" : ""
                        }`}
                      />
                    </button>

                    {isUserMenuOpen && (
                      <div className="absolute right-0 mt-2 w-56 bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden z-50">
                        <div className="p-4 border-b space-y-1">
                          <p className="font-medium text-gray-900">
                            {userData.first_name} {userData.last_name}
                          </p>

                          <p className="text-xs text-gray-500">
                            ID: #{userData.id}
                          </p>

                          <p className="text-sm text-gray-500">
                            {userData.email}
                          </p>
                        </div>

                        <div className="py-2">
                          <Link
                            to={getDashboardPath(userData?.role_id)}
                            onClick={() => setIsUserMenuOpen(false)}
                            className="flex w-full items-center px-4 py-3 text-gray-700 hover:bg-gray-50"
                          >
                            <LayoutDashboard className="h-4 w-4 mr-2 text-orange-600" />
                            Dashboard
                          </Link>
                          <button
                            onClick={handleLogout}
                            className="flex w-full items-center px-4 py-3 text-gray-700 hover:bg-gray-50"
                          >
                            <LogOut className="h-4 w-4 mr-2 text-red-500" />
                            Sign Out
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  // Guest
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => navigate("/login")}
                      className={`hidden sm:inline-flex text-sm font-semibold text-gray-700 ${ACCENT_HOVER}`}
                    >
                      Sign in
                    </button>

                    <button
                      onClick={() => navigate("/register")}
                      className={[
                        "inline-flex items-center justify-center rounded-full bg-black px-6 py-2.5 text-sm font-semibold text-white hover:bg-black/90",

                        ACCENT_BORDER,
                        ACCENT,
                      ].join(" ")}
                    >
                      Get Started
                    </button>
                  </div>
                )}
              </div>

              {/* CTA (مثل ناف بارك الأصلي) */}
              {/* <a
              href="#demo"
              className="hidden sm:inline-flex items-center justify-center rounded-full bg-black px-6 py-2.5 text-sm font-semibold text-white hover:bg-black/90"
            >
              Request a Demo
            </a> */}
            </div>
          </div>
        </nav>
      </div>

      {/* ===== Mobile Drawer ===== */}
      {isMobileMenuOpen && (
        <div
          className="fixed inset-0 z-[10000] bg-black/40 lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        >
          <div
            className="absolute right-0 top-0 h-full w-72 max-w-full bg-white shadow-xl p-6 overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-6">
              <button
                onClick={() => handleNavigation("/", "HOME")}
                className="text-base font-extrabold tracking-tight text-gray-900"
              >
                OrderzHouse
              </button>

              <button
                onClick={() => setIsMobileMenuOpen(false)}
                className={`p-2 text-gray-600 ${ACCENT_HOVER}`}
                aria-label="Close menu"
              >
                <span className="text-2xl leading-none">&times;</span>
              </button>
            </div>

            {/* user info */}
            {IsAuthenticated && userData && (
              <div className="flex items-center gap-3 mb-6">
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center text-white text-base font-bold uppercase"
                  style={{ backgroundColor: ORANGE }}
                >
                  {`${userData.first_name?.[0] || ""}${
                    userData.last_name?.[0] || ""
                  }`}
                </div>

                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {userData.first_name} {userData.last_name}
                  </p>

                  <p className="text-xs text-gray-500">ID: #{userData.id}</p>

                  <p className="text-xs text-gray-500">{userData.email}</p>
                </div>
              </div>
            )}

            <div className="space-y-6">
              {/* Main */}
              <div>
                <p className="text-xs uppercase tracking-wide text-gray-400 mb-2">
                  Main
                </p>
                <div className="flex flex-col">
                  {navLinks.map(
                    (item) =>
                      item.condition && (
                        <button
                          key={item.label}
                          onClick={() =>
                            handleNavigation(item.path, item.label)
                          }
                          className={`w-full text-left py-2 text-base ${
                            activeLink === item.label
                              ? "text-orange-600"
                              : `text-gray-800 ${ACCENT_HOVER}`
                          }`}
                        >
                          {item.label}
                        </button>
                      )
                  )}
                </div>
              </div>

              {/* Explore */}
              <div className="pt-4 border-t">
                <p className="text-xs uppercase tracking-wide text-gray-400 mb-2">
                  Explore
                </p>
                <div className="flex flex-col">
                  {exploreItems.map((it) => (
                    <button
                      key={it.label}
                      onClick={() => handleNavigation(it.path, it.label)}
                      className={`w-full text-left py-2 text-base ${
                        activeLink === it.label
                          ? "text-orange-600"
                          : `text-gray-800 ${ACCENT_HOVER}`
                      }`}
                    >
                      {it.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Add project */}
              {userData?.role_id === 2 && (
                <div className="pt-4 border-t">
                  <button
                    onClick={() => {
                      setIsMobileMenuOpen(false);
                      navigate("/create-project");
                    }}
                    className="flex items-center text-base"
                    style={{ color: ORANGE }}
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Add project
                  </button>
                </div>
              )}

              {/* Notifications shortcut */}
              {IsAuthenticated && (
                <div className="pt-4 border-t">
                  <button
                    onClick={() => {
                      setIsMobileMenuOpen(false);
                      navigate("/notifications");
                    }}
                    className={`flex items-center text-base text-gray-800 ${ACCENT_HOVER}`}
                  >
                    <Bell className="h-4 w-4 mr-2" />
                    Notifications
                    {unreadCount > 0 && (
                      <span className="ml-2 inline-flex items-center justify-center rounded-full bg-red-500 text-white text-xs h-5 min-w-[1.25rem] px-1">
                        {unreadCount > 9 ? "9+" : unreadCount}
                      </span>
                    )}
                  </button>
                </div>
              )}

              {/* Sign out */}
              {IsAuthenticated && userData ? (
                <div className="pt-4 border-t">
                  <button
                    onClick={() => {
                      setIsMobileMenuOpen(false);
                      handleLogout();
                    }}
                    className="flex items-center text-base text-red-600 hover:text-red-700"
                  >
                    <LogOut className="h-4 w-4 mr-2" />
                    Sign Out
                  </button>
                </div>
              ) : (
                <div className="pt-4 border-t space-y-2">
                  <button
                    onClick={() => {
                      setIsMobileMenuOpen(false);
                      navigate("/login");
                    }}
                    className={`w-full text-left py-2 text-base text-gray-800 ${ACCENT_HOVER}`}
                  >
                    Sign In
                  </button>
                  <button
                    onClick={() => {
                      setIsMobileMenuOpen(false);
                      navigate("/register");
                    }}
                    className="w-full text-left py-2 text-base font-semibold"
                    style={{ color: ORANGE }}
                  >
                    Get Started
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
