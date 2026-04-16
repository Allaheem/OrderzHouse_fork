import { Routes, Route, useLocation, Navigate } from "react-router-dom";
import "./App.css";
import "./index.css";
import "animate.css";
// import "./components/loadingScreen/axiosLoading.js";
import { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { captureAndLogReferral } from "./utils/partnerReferral.js";
import { hydrateFromStorage, setToken, setUserData } from "./slice/auth/authSlice";
import API, { startProactiveRefresh } from "./api/client";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { Toaster } from "react-hot-toast";

import Navbar from "./components/navbar/Nav";
import EnhancedFooter from "./components/footer/Footer";
import PrivacyPolicyPage from "./components/policy/Policy";
import ModernAboutPage from "./components/about/About";
import OrderzHousePage from "./components/main/Main";
import ContactUsPage from "./components/contact/Contact";
import Login from "./components/login/Login";
import Register from "./components/register/Register";
import ForgotPassword from "./components/auth/ForgotPassword";
import ResetPassword from "./components/auth/ResetPassword";
import AcceptTerms from "./components/auth/AcceptTerms";
import CompleteProfile from "./components/auth/CompleteProfile";

import ProtectedRoute from "./components/ProtectedRoute";
import { initSocket, disconnectSocket } from "./services/socketService";
// import CourseDetail from "./components/coursesManagement/CourseDetail.jsx";
import NotificationsPage from "./components/notifications/NotificationsPage";
import AccountSuspended from "./components/AccountSuspended/AccountSuspended";
import Plans from "./components/plans/Plans.jsx";
import ProjectsPage from "./components/Catigories/ProjectsPage";
import AdminAppointments from "./components/Appointments/AdminAppointments";
import FreelancerAppointments from "./components/Appointments/FreelancerAppointments";
// import AdminCourseAccessControl from "./components/coursesManagement/AdminAccessControl.jsx";
// import AdminCourseManagement from "./components/coursesManagement/AdminCourseManagement";
// import MyRestrictedCourses from "./components/coursesManagement/MyRestrictedCourses";
import AccessDenied from "./components/coursesManagement/AccessDenied";
import Terms from "./components/Terms/Terms.jsx";
import Blogs from "./components/blogs/Blogs.jsx";
import BlogPost from "./components/blogs/BlogPost.jsx";
import AdminRouter from "./adminDash/routes/index";
import ProjectDetails from "./components/Catigories/ProjectDetails.jsx";

import CreateProjectPage from "./components/CreateProjects/CreateProjectPage";
import CreateTaskPage from "./components/CreateProjects/CreateTaskPage";
import CopywritingTest from "./components/CopywritingTest";

// import GlobalLoadingProvider from "./components/loadingScreen/GlobalLoadingProvider.jsx";
// import ChatPage from "./components/Chat/ChatPage";
import PaymentSuccess from "./components/success/PaymentSuccess";
import PaymentCancel from "./components/success/PaymentCancel";
import ProjectSuccess from "./pages/projects/ProjectSuccess";
import FreelancerContractTerms from "./components/Freelancer/FreelancerContractTerms.jsx";
import FreelancerContractSignup from "./components/Freelancer/FreelancerContractSignup.jsx";
import NotFound from "./components/NotFound.jsx";
import Help from "./pages/Help.jsx";
import DashboardRedirect from "./components/DashboardRedirect.jsx";
import MyProjectsRedirect from "./components/MyProjectsRedirect.jsx";
import OfferRedirect from "./components/OfferRedirect.jsx";
import EscrowRedirect from "./components/EscrowRedirect.jsx";


const RoleBasedAppointments = ({ userData }) => {
  if (userData?.role_id === 1) {
    return <AdminAppointments />;
  } else if (userData?.role_id === 3) {
    return <FreelancerAppointments />;
  } else {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center p-4">
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            Access Denied
          </h2>
          <p className="text-gray-600">
            Appointments are only available for admins and freelancers.
          </p>
        </div>
      </div>
    );
  }
};

// Scroll to top on route change
function ScrollToTop() {
  const { pathname, search } = useLocation();
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  }, [pathname, search]);
  return null;
}

function App() {
  const location = useLocation();
  const dispatch = useDispatch();
  const token = useSelector((state) => state.auth.token);
  const userId = useSelector((state) => state.auth.userId);
  const userData = useSelector((state) => state.auth.userData);

  const hideNavbarRoutes = ["/account/suspended"];
  const shouldHideNavbar = hideNavbarRoutes.includes(location.pathname);
  
  // Hide footer for admin dashboard routes
  const isAdminRoute = location.pathname.startsWith("/admin") || 
                       location.pathname.startsWith("/client") || 
                       location.pathname.startsWith("/freelancer") || 
                       location.pathname.startsWith("/partner");

  useEffect(() => {
    const bootstrapSession = async () => {
      dispatch(hydrateFromStorage());
      try {
        const refreshRes = await API.post("/users/refresh");
        const newToken = refreshRes?.data?.token;
        if (newToken) {
          dispatch(setToken(newToken));
          try {
            const me = await API.get("/users/getUserdata", {
              headers: { Authorization: `Bearer ${newToken}` },
            });
            const user = me?.data?.user ?? me?.data?.data ?? me?.data;
            if (user) dispatch(setUserData(user));
          } catch (err) {
            console.warn("Session bootstrap user fetch failed:", err);
          }
          startProactiveRefresh();
        }
      } catch (_) {
        // No valid refresh cookie/session at startup
      }
    };
    bootstrapSession();
  }, [dispatch]);

  useEffect(() => {
    if (token && userId) {
      console.log("🔌 Initializing socket in App useEffect...");
      initSocket(token, userId);
    }

    return () => {
      console.log("Disconnecting socket in App useEffect cleanup...");
      disconnectSocket();
    };
  }, [token, userId]);

  // Partner referral: ONE call site only — App.jsx on route/search change. Lock+done in partnerReferral prevents duplicate POSTs (StrictMode).
  const referralApiPost = (url, body) =>
    API.post(url, body, { withCredentials: true }).then((r) => r.data);
  useEffect(() => {
    if (location.search) captureAndLogReferral(location.search, referralApiPost);
  }, [location.search]);

  return (
    <>
      <ScrollToTop />
      {/* <GlobalLoadingProvider> */}
      {!shouldHideNavbar && <Navbar />}

      <Routes
        future={{
          v7_startTransition: true,
          v7_relativeSplatPath: true,
        }}
      >
        {/* --- Blogs --- TEMPORARILY HIDDEN FOR LAUNCH - DO NOT DELETE */}
        {/* <Route path="/blogs" element={<Blogs />} /> */}
        {/* <Route path="/blogs/:id" element={<BlogPost />} /> */}
        {/* Redirect /blogs to home to prevent direct access */}
        <Route path="/blogs" element={<Navigate to="/" replace />} />
        <Route path="/blogs/:id" element={<Navigate to="/" replace />} />

        {/* --- Account Suspended --- */}
        <Route path="/account/suspended" element={<AccountSuspended />} />

        {/* --- Dashboard alias: redirect to role base or login --- */}
        <Route path="/dashboard" element={<DashboardRedirect />} />
        <Route path="/admin/dashboard" element={<Navigate to="/admin" replace />} />
        <Route path="/client/dashboard" element={<Navigate to="/client" replace />} />
        <Route path="/freelancer/dashboard" element={<Navigate to="/freelancer" replace />} />

        {/* --- My projects alias: redirect to role-based projects list --- */}
        <Route path="/my-projects" element={<MyProjectsRedirect />} />

        {/* --- Offer/Escrow notification links: redirect to role-based payments with query --- */}
        <Route path="/offers/:id" element={<OfferRedirect />} />
        <Route path="/escrow/:id" element={<EscrowRedirect />} />

        {/* --- Public Pages --- */}
        <Route path="/" element={<OrderzHousePage />} />
        <Route path="/privacy" element={<PrivacyPolicyPage />} />
        <Route path="/about" element={<ModernAboutPage />} />
        <Route path="/plans" element={<Plans />} />
        <Route path="/contact" element={<ContactUsPage />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />
        <Route path="/reset-password/:token" element={<ResetPassword />} />


        <Route path="/terms" element={<Terms />} />
        <Route path="/help" element={<Help />} />
        <Route
          path="/accept-terms"
          element={
            <ProtectedRoute>
              <AcceptTerms />
            </ProtectedRoute>
          }
        />
        <Route
          path="/complete-profile"
          element={
            <ProtectedRoute>
              <CompleteProfile />
            </ProtectedRoute>
          }
        />

        {/* --- Protected Pages --- */}

        <Route
          path="/create-project"
          element={
            <ProtectedRoute>
              <CreateProjectPage />
            </ProtectedRoute>
          }
        />

        {/* --- Tasks --- */}
        <Route
          path="/tasks"
          element={
            <ProtectedRoute>
              <ProjectsPage mode="tasks" />
            </ProtectedRoute>
          }
        />

        <Route
          path="/tasks/create"
          element={
            <ProtectedRoute>
              <CreateTaskPage /> {/* 👈 صفحة إنشاء التاسك */}
            </ProtectedRoute>
          }
        />

        <Route
          path="/tasks/:id"
          element={
            <ProtectedRoute>
              <ProjectDetails mode="tasks" />
            </ProtectedRoute>
          }
        />

        {/* --- Course Management --- */}
        {/* <Route
            path="/courses/:id"
            element={
              <ProtectedRoute>
                <CourseDetail />
              </ProtectedRoute>
            }
          />
          <Route
            path="/my-courses"
            element={
              <ProtectedRoute>
                <MyRestrictedCourses />
              </ProtectedRoute>
            }
          />
          <Route path="/access-denied" element={<AccessDenied />} />
          <Route
            path="/admin/courses"
            element={
              <ProtectedRoute allowedRoles={[1]}>
                <AdminCourseManagement />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/course-access"
            element={
              <ProtectedRoute allowedRoles={[1]}>
                <AdminCourseAccessControl />
              </ProtectedRoute>
            }
          />  */}

        <Route path="/access-denied" element={<AccessDenied />} />

        {/* --- Notifications & Projects --- */}
        <Route
          path="/notifications"
          element={
            <ProtectedRoute>
              <NotificationsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/projectsPage"
          element={
            <ProtectedRoute>
              <ProjectsPage />
            </ProtectedRoute>
          }
        />

        {/* --- Appointments --- */}
        <Route
          path="/appointments"
          element={
            <ProtectedRoute>
              <RoleBasedAppointments userData={userData} />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/appointments"
          element={
            <ProtectedRoute>
              <AdminAppointments />
            </ProtectedRoute>
          }
        />
        <Route
          path="/my-appointments"
          element={
            <ProtectedRoute>
              <FreelancerAppointments />
            </ProtectedRoute>
          }
        />

        {/* --- Chat ---
          <Route
            path="/chat"
            element={
              <ProtectedRoute>
                <ChatPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/chat/:chatType/:chatId"
            element={
              <ProtectedRoute>
                <ChatPage />
              </ProtectedRoute>
            }
          /> */}

        {/* --- Admin / Client / Freelancer --- */}
        <Route
          path="/admin/*"
          element={
            <ProtectedRoute allowedRoles={[1]}>
              <AdminRouter />
            </ProtectedRoute>
          }
        />
        <Route
          path="/client/*"
          element={
            <ProtectedRoute allowedRoles={[2]}>
              <AdminRouter />
            </ProtectedRoute>
          }
        />
        <Route
          path="/freelancer/*"
          element={
            <ProtectedRoute allowedRoles={[3]}>
              <AdminRouter />
            </ProtectedRoute>
          }
        />
        <Route
          path="/partner/*"
          element={
            <ProtectedRoute allowedRoles={[5]}>
              <AdminRouter />
            </ProtectedRoute>
          }
        />

        {/* مسارات الدفع ثابتة قبل المسار الديناميكي حتى لا يُفسَّر payment-cancel كـ id */}
        <Route path="/projects/payment-success" element={<PaymentSuccess />} />
        <Route path="/projects/payment-cancel" element={<PaymentCancel />} />
        <Route path="/projects/success/:id" element={<ProjectSuccess />} />
        <Route
          path="/projects/:id"
          element={
            <ProtectedRoute>
              <ProjectDetails />
            </ProtectedRoute>
          }
        />

        {/* --- Copywriting Test --- */}
        <Route
          path="/copywriting-test"
          element={
            <ProtectedRoute allowedRoles={[3]}>
              <CopywritingTest />
            </ProtectedRoute>
          }
        />
        <Route path="/payment/success" element={<PaymentSuccess />} />

        <Route path="/freelancer/contract-terms" element={<FreelancerContractTerms />} />
        <Route path="/freelancer/contract-signup" element={<FreelancerContractSignup />} />


        {/* --- 404 Fallback --- */}
        <Route path="*" element={<NotFound />} />
      </Routes>

      {!shouldHideNavbar && !isAdminRoute && <EnhancedFooter />}
      <ToastContainer
        position="top-right"
        autoClose={5000}
        draggable
        pauseOnHover
      />
      <Toaster position="bottom-right" />
      {/* </GlobalLoadingProvider> */}
    </>
  );
}

export default App;
