import React, { useEffect, useState, useCallback } from "react";
import { Outlet, useNavigate, useLocation } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import Sidebar from "../../components/Sidebar/Sidebar.jsx";
import {
  Home,
  Users,
  BookOpen,
  FolderKanban,
  Calendar,
  Shield,
  Clipboard,
  FileText,
  CreditCard,
  DollarSign,
  BarChart2,
  User,
  LogOut,
  Settings,
  ListChecks,
  Star,
  CalendarDays,
  History,
  HelpCircle,
  ListChecks as SurveyIcon,
  PlaySquare,
  Clock,
  Share2,
  Flag,
} from "lucide-react";
import { logout } from "../../slice/auth/authSlice";
import API, { clearProactiveRefresh } from "../../api/client.js";
import { disconnectSocket } from "../../services/socketService";
import TopBar from "../components/TopBar.jsx";
import { useToast } from "../../components/toast/ToastProvider.jsx";
import EnhancedFooter from "../../components/footer/Footer.jsx";
import ComingSoonModal from "../components/ComingSoonModal.jsx";

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

function getActiveFromPath(pathname) {
  const base = getBasePrefix(pathname);
  const p = pathname.replace(base, "") || "/";

  // مشترك بين الكل
  if (p === "/" || p === "") return "overview";

  // ===== admin =====
  if (base === "/admin") {
    if (p.startsWith("/people/admins")) return "admins";
    if (p.startsWith("/people/clients")) return "clients";
    if (p.startsWith("/people/freelancers")) return "freelancers";
    // if (p.startsWith("/learning/courses")) return "courses";
    if (p.startsWith("/learning/categories")) return "categories";
    if (p.startsWith("/operation/verifications")) return "verifications";
    if (p.startsWith("/operation/content-reports")) return "content-reports";
    if (p.startsWith("/operation/projects")) return "projects";
    if (p.startsWith("/operation/pending-approvals")) return "pending-approvals";
    // if (p.startsWith("/operation/tasks")) return "tasks";
    if (p.startsWith("/community/blogs")) return "blogs";
    if (p.startsWith("/finance/payments")) return "payments";
    if (p.startsWith("/finance/plans")) return "plans";
    if (p.startsWith("/subscriptions")) return "subscriptions";
    if (p.startsWith("/analytics")) return "analytics";
    if (p.startsWith("/referrals")) return "referrals";
    if (p.startsWith("/projects")) return "projects";
    if (p.startsWith("/payments")) return "payments";
    if (p.startsWith("/profile")) return "profile";
    if (p.startsWith("/settings")) return "settings";
  }

  // ===== client =====
  if (base === "/client") {
    if (p.startsWith("/tender-vault")) return "tender-vault";
    if (p.startsWith("/projects")) return "projects";
    if (p.startsWith("/payments")) return "payments";
    if (p.startsWith("/profile")) return "profile";
    if (p.startsWith("/settings")) return "settings";
  }

  if (base === "/partner") {
    if (p.startsWith("/projects")) return "projects";
    if (p.startsWith("/payments")) return "payments";
    if (p.startsWith("/profile")) return "profile";
    if (p.startsWith("/settings")) return "settings";
  }

  // ===== freelancer =====
  if (base === "/freelancer") {
    if (p.startsWith("/projects")) return "projects";
    if (p.startsWith("/payments")) return "payments";
    if (p.startsWith("/profile")) return "profile";
    if (p.startsWith("/settings")) return "settings";
  }

  // ===== apm =====
  if (base === "/apm") {
    if (p.startsWith("/history")) return "history";
    if (p.startsWith("/questions")) return "questions";
    if (p.startsWith("/survey")) return "survey";
    if (p.startsWith("/videos")) return "videos";
    if (p.startsWith("/settings")) return "settings";
    if (p.startsWith("/profile")) return "profile";
  }

  return "overview";
}

function getNav(role, navigate, base, onLogout, userData = null) {
  if (role === "admin") {
    const navigation = [
      {
        id: "overview",
        name: "Overview",
        icon: Home,
        onClick: () => navigate(`${base}/`),
      },
      {
        id: "admins",
        name: "Admins",
        icon: Users,
        onClick: () => navigate(`${base}/people/admins`),
      },
      {
        id: "clients",
        name: "Clients",
        icon: Users,
        onClick: () => navigate(`${base}/people/clients`),
      },
      {
        id: "freelancers",
        name: "Freelancers",
        icon: Users,
        onClick: () => navigate(`${base}/people/freelancers`),
      },
      // { id: "courses", name: "Courses", icon: BookOpen, onClick: () => navigate(`${base}/learning/courses`) },
      {
        id: "categories",
        name: "Categories",
        icon: FolderKanban,
        onClick: () => navigate(`${base}/learning/categories`),
      },
      {
        id: "verifications",
        name: "Verifications",
        icon: Shield,
        onClick: () => navigate(`${base}/operation/verifications`),
      },
      {
        id: "content-reports",
        name: "Content reports",
        icon: Flag,
        onClick: () => navigate(`${base}/operation/content-reports`),
      },
      {
        id: "projects",
        name: "Projects",
        icon: Clipboard,
        onClick: () => navigate(`${base}/operation/projects`),
      },
      {
        id: "pending-approvals",
        name: "Pending Approvals",
        icon: Clipboard,
        onClick: () => navigate(`${base}/operation/pending-approvals`),
      },
      {
        id: "pending-bidding-approvals",
        name: "Bidding Approvals",
        icon: Clock,
        onClick: () => navigate(`${base}/operation/pending-bidding-approvals`),
      },
      // { id: "tasks", name: "Tasks", icon: Clipboard, onClick: () => navigate(`${base}/operation/tasks`) },
      {
        id: "blogs",
        name: "Blogs",
        icon: FileText,
        onClick: () => navigate(`${base}/community/blogs`),
      },
      {
        id: "payments",
        name: "Payments",
        icon: CreditCard,
        onClick: () => navigate(`${base}/finance/payments`),
      },
      {
        id: "plans",
        name: "Plans",
        icon: DollarSign,
        onClick: () => navigate(`${base}/finance/plans`),
      },
      {
        id: "subscriptions",
        name: "Subscriptions",
        icon: CreditCard,
        onClick: () => navigate(`${base}/finance/subscriptions`),
      },
      {
        id: "analytics",
        name: "Analytics",
        icon: BarChart2,
        onClick: () => navigate(`${base}/analytics`),
      },
      {
        id: "referrals",
        name: "Referrals",
        icon: Share2,
        onClick: () => navigate(`${base}/referrals`),
      },
    ];
    const bottomNavigation = [
      {
        id: "settings",
        name: "Settings",
        icon: Settings,
        path: `${base}/settings`,
      },
      {
        id: "profile",
        name: "Profile",
        icon: User,
        onClick: () => navigate(`${base}/profile`),
      },
      {
        id: "logout",
        name: "Logout",
        icon: LogOut,
        onClick: onLogout || (() => {}),
      },
    ];
    return { navigation, bottomNavigation };
  }

  if (role === "apm") {
    const navigation = [
      {
        id: "overview",
        name: "Overview",
        icon: Home,
        onClick: () => navigate(`${base}/`),
      },
      {
        id: "history",
        name: "History",
        icon: History,
        onClick: () => navigate(`${base}/history`),
      },
      {
        id: "questions",
        name: "Questions",
        icon: HelpCircle,
        onClick: () => navigate(`${base}/questions`),
      },
      {
        id: "survey",
        name: "Survey",
        icon: SurveyIcon,
        onClick: () => navigate(`${base}/survey`),
      },
      {
        id: "videos",
        name: "Videos",
        icon: PlaySquare,
        onClick: () => navigate(`${base}/videos`),
      },
    ];
    const bottomNavigation = [
      {
        id: "settings",
        name: "Settings",
        icon: Settings,
        path: `${base}/settings`,
      },
      {
        id: "profile",
        name: "Profile",
        icon: User,
        onClick: () => navigate(`${base}/profile`),
      },
      {
        id: "logout",
        name: "Logout",
        icon: LogOut,
        onClick: onLogout || (() => {}),
      },
    ];
    return { navigation, bottomNavigation };
  }

  if (role === "client" || role === "partner") {
    const navigation = [
      {
        id: "overview",
        name: "Overview",
        icon: Home,
        onClick: () => navigate(`${base}/`),
      },
      {
        id: "projects",
        name: "Projects",
        icon: Clipboard,
        onClick: () => navigate(`${base}/projects`),
      },
      // Add Tender Vault only for clients with permission
      ...(role === "client" && userData?.can_manage_tender_vault === true
        ? [
            {
              id: "tender-vault",
              name: "Tender Vault",
              icon: FolderKanban,
              path: `${base}/tender-vault`,
            },
          ]
        : []),
      {
        id: "payments",
        name: "Payments",
        icon: CreditCard,
        onClick: () => navigate(`${base}/payments`),
      },
    ];
    const bottomNavigation = [
      {
        id: "settings",
        name: "Settings",
        icon: Settings,
        path: `${base}/settings`,
      },
      {
        id: "profile",
        name: "Profile",
        icon: User,
        onClick: () => navigate(`${base}/profile`),
      },
      {
        id: "logout",
        name: "Logout",
        icon: LogOut,
        onClick: onLogout || (() => {}),
      },
    ];
    return { navigation, bottomNavigation };
  }

  if (role === "freelancer") {
    const navigation = [
      {
        id: "overview",
        name: "Overview",
        icon: Home,
        onClick: () => navigate(`${base}/`),
      },
      {
        id: "projects",
        name: "Projects",
        icon: Clipboard,
        onClick: () => navigate(`${base}/projects`),
      },
      {
        id: "payments",
        name: "Payments",
        icon: CreditCard,
        onClick: () => navigate(`${base}/payments`),
      },
    ];
    const bottomNavigation = [
      {
        id: "settings",
        name: "Settings",
        icon: Settings,
        path: `${base}/settings`,
      },
      {
        id: "profile",
        name: "Profile",
        icon: User,
        onClick: () => navigate(`${base}/profile`),
      },
      {
        id: "logout",
        name: "Logout",
        icon: LogOut,
        onClick: onLogout || (() => {}),
      },
    ];
    return { navigation, bottomNavigation };
  }

  const navigation = [
    {
      id: "overview",
      name: "Overview",
      icon: Home,
      onClick: () => navigate(`${base}/`),
    },
  ];
  const bottomNavigation = [
    {
      id: "settings",
      name: "Settings",
      icon: Settings,
      path: "/admin/settings",
    },
    {
      id: "profile",
      name: "Profile",
      icon: User,
      onClick: () => navigate(`/profile`),
    },
    {
      id: "logout",
      name: "Logout",
      icon: LogOut,
      onClick: onLogout || (() => {}),
    },
  ];
  return { navigation, bottomNavigation };
}

export default function AdminLayout() {
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch();
  const { userData } = useSelector((s) => s.auth);

  const roleId = userData?.role_id ?? Number(localStorage.getItem("roled"));
  const role = mapRole(roleId);

  const handleLogout = () => {
    try {
      disconnectSocket();
    } catch (_) {}
    clearProactiveRefresh();
    API.post("/users/logout").catch(() => {}); // clear refresh cookie
    dispatch(logout());
    try {
      localStorage.removeItem("roled");
    } catch (_) {}
    navigate("/");
    window.location.reload();
  };

  const base = getBasePrefix(location.pathname);
  const { navigation, bottomNavigation } = getNav(
    role,
    navigate,
    base,
    handleLogout,
    userData
  );

  // Center FAB action (mobile bottom bar) for client/freelancer
  const handleCreateProject = useCallback(() => {
    // عدّل المسار حسب الراوت عندك
    navigate(`/create-project`);
  }, [navigate, base]);

  const [showTaskComingSoon, setShowTaskComingSoon] = useState(false);

  const handleCreateTask = useCallback(() => {
    if (role === "freelancer") {
      setShowTaskComingSoon(true);
      return;
    }
    navigate(`${base}/tasks/create`);
  }, [navigate, base, role]);

  const [activePage, setActivePage] = useState(() =>
    getActiveFromPath(location.pathname)
  );
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // NEW: تحكم في ظهور السايدبار الديسكتوب + محتوى التوب بار
  const [showDesktopSidebar, setShowDesktopSidebar] = useState(true);
  const [pageTitle, setPageTitle] = useState("Overview");
  const [topBarRight, setTopBarRight] = useState(null);

  const clearTopBarRight = useCallback(() => {
    setTopBarRight(null);
  }, []);

  // تحديث الصفحة النشطة من الـ path
  useEffect(() => {
    setActivePage(getActiveFromPath(location.pathname));
  }, [location.pathname]);

  // تحديث عنوان الصفحة حسب الـ navigation
  useEffect(() => {
    const allItems = [...navigation, ...bottomNavigation];
    const found = allItems.find((item) => item.id === activePage);
    setPageTitle(found?.name || "Overview");
  }, [navigation, bottomNavigation, activePage]);

  // زر إظهار/إخفاء السايدبار
  const handleToggleSidebar = () => {
    if (typeof window !== "undefined" && window.innerWidth < 1024) {
      // موبايل: افتح/اغلق المنيو فقط في رول الادمن (لأن باقي الرولات عندها زر إنشاء بالمنتصف)
      if (role === "admin") setIsMobileMenuOpen((prev) => !prev);
    } else {
      // ديسكتوب → اخفي/اظهر السايدبار
      setShowDesktopSidebar((prev) => !prev);
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-gray-50 text-slate-800">
      <div className="flex-1 flex min-h-0">
        <Sidebar
          activePage={activePage}
          setActivePage={(id) => {
            setActivePage(id);
            const found = [...navigation, ...bottomNavigation].find(
              (item) => item.id === id
            );
            if (found?.onClick) found.onClick();
          }}
          isMobileMenuOpen={isMobileMenuOpen}
          setIsMobileMenuOpen={setIsMobileMenuOpen}
          navigation={navigation}
          bottomNavigation={bottomNavigation}
          onLogout={handleLogout}
          showDesktopSidebar={showDesktopSidebar}
          role={role}
          onCreateProject={handleCreateProject}
          onCreateTask={handleCreateTask}
        />

        <main
          className="flex-1 flex flex-col min-h-0 overflow-auto"
          style={{ backgroundColor: "#f8fafc" }}
        >
          <TopBar
            title={pageTitle}
            onToggleSidebar={handleToggleSidebar}
            rightContent={topBarRight}
          />
          <div className="flex-1 p-3 md:p-5 min-h-0">
            <Outlet
              context={{
                setTopBarRight,
                clearTopBarRight,
              }}
            />
          </div>
        </main>
      </div>
      <div className="flex-shrink-0 w-full">
        <EnhancedFooter />
      </div>

      {/* Freelancer: Create Task → Coming Soon (feature disabled) */}
      <ComingSoonModal
        open={showTaskComingSoon}
        onClose={() => setShowTaskComingSoon(false)}
        title="Coming soon"
        description="We're preparing a better task workflow for freelancers. This feature will be available soon."
        buttonText="Got it"
      />
    </div>
  );
}
