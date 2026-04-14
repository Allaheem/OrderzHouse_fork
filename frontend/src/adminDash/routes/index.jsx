import { Routes, Route, useLocation, Navigate } from "react-router-dom";
import AdminLayout from "../layout/AdminLayout.jsx";
import Dashboard from "../pages/Dashboard.jsx";

import Admins from "../pages/people/Admins.jsx";
import Clients from "../pages/people/Clients.jsx";
import Freelancers from "../pages/people/Freelancers.jsx";
// import Courses from "../pages/learning/Courses.jsx";
import Categories from "../pages/learning/Categories.jsx";
import SubCategories from "../pages/learning/SubCategories.jsx";
import SubSubCategories from "../pages/learning/SubSubCategories.jsx";
import Verifications from "../pages/operation/Verifications.jsx";
import ContentReports from "../pages/operation/ContentReports.jsx";

import AdminProjects from "../pages/operation/Projects/AdminProjects.jsx";
import AdminPendingProjects from "../pages/operation/Projects/AdminPendingProjects.jsx";
import AdminPendingBiddingApprovals from "../pages/operation/Projects/AdminPendingBiddingApprovals.jsx";
import ClientsProjects from "../pages/operation/Projects/ClientsProjects.jsx";
import FreelancersProjects from "../pages/operation/Projects/FreelancersProjects.jsx";
import ProjectDetails from "../pages/operation/Projects/ProjectDetailsDash.jsx";

import Blogs from "../pages/community/Blogs.jsx";
import Payments from "../pages/finance/Payments.jsx";
import Plans from "../pages/finance/Plans.jsx";
import AdminSubscriptions from "../pages/finance/AdminSubscriptions.jsx";
import Analytics from "../pages/insights/Analytics.jsx";
import PartnerReferrals from "../pages/referrals/PartnerReferrals.jsx";
// import Tasks from "../pages/operation/Tasks.jsx";
import Profile from "../pages/Profile.jsx";

import Settings from "../pages/Settings.jsx";
import EditProfile from "../pages/EditProfile.jsx";
import TenderVaultManager from "../pages/TenderVaultManager.jsx";
import CreateTender from "../pages/CreateTender.jsx";
import TenderDetails from "../pages/TenderDetails.jsx";

function ProjectsSwitch() {
  const { pathname } = useLocation();

  // /client/projects  -> صفحة العميل
  if (pathname.startsWith("/client")) {
    return <ClientsProjects />;
  }
  if (pathname.startsWith("/partner")) {
    return <ClientsProjects />;
  }

  // /freelancer/projects -> صفحة الفريلانسر
  if (pathname.startsWith("/freelancer")) {
    return <FreelancersProjects />;
  }

  // أي شيء آخر (عادة admin) نحوله إلى صفحة إدارة المشاريع
  return <Navigate to="/admin/operation/projects" replace />;
}

export default function AdminRouter() {
  return (
    <Routes>
      <Route path="/" element={<AdminLayout />}>
        {/* index */}
        <Route index element={<Dashboard />} />

        {/* admin-only sections */}
        <Route path="people/admins" element={<Admins />} />
        <Route path="people/clients" element={<Clients />} />
        <Route path="people/freelancers" element={<Freelancers />} />

        {/* <Route path="learning/courses" element={<Courses />} /> */}
        <Route path="learning/categories" element={<Categories />} />
        <Route path="learning/categories/:categoryId" element={<SubCategories />} />
        <Route
          path="learning/categories/:categoryId/sub/:subCategoryId"
          element={<SubSubCategories />}
        />

        <Route path="operation/verifications" element={<Verifications />} />
        <Route path="operation/content-reports" element={<ContentReports />} />

        <Route path="operation/projects" element={<AdminProjects />} />
        <Route path="operation/pending-approvals" element={<AdminPendingProjects />} />
        <Route path="operation/pending-bidding-approvals" element={<AdminPendingBiddingApprovals />} />
        <Route path="operation/projects/:projectId" element={<ProjectDetails />} />
        <Route path="project/:projectId" element={<ProjectDetails />} />

        {/* <Route path="operation/tasks" element={<Tasks />} /> */}
        <Route path="community/blogs" element={<Blogs />} />
        <Route path="finance/payments" element={<Payments />} />
        <Route path="finance/plans" element={<Plans />} />
        <Route path="finance/subscriptions" element={<AdminSubscriptions />} />
        <Route path="analytics" element={<Analytics />} />
        <Route path="referrals" element={<PartnerReferrals />} />

        {/* Profile & Settings */}
        <Route path="profile" element={<Profile />} />
        <Route path="editprofile" element={<EditProfile />} />
        <Route path="settings" element={<Settings />} />

        {/* generic sections —  /admin  /client  /freelancer */}
        <Route path="projects" element={<ProjectsSwitch />} />
        <Route path="payments" element={<Payments />} />
        <Route path="tender-vault" element={<TenderVaultManager />} />
        <Route path="tender-vault/new" element={<CreateTender />} />
        <Route path="tender-vault/:id" element={<TenderDetails />} />
        {/* <Route path="courses" element={<Courses />} /> */}
        {/* <Route path="tasks" element={<Tasks />} /> */}
      </Route>
    </Routes>
  );
}
