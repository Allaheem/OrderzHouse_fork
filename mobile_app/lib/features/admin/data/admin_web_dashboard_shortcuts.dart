import 'package:flutter/material.dart';

/// Same paths as [frontend/src/adminDash/routes/index.jsx] under `/admin/*`.
class AdminWebDashboardShortcut {
  const AdminWebDashboardShortcut({
    required this.path,
    required this.titleEn,
    required this.titleAr,
    required this.icon,
  });

  final String path;
  final String titleEn;
  final String titleAr;
  final IconData icon;

  String titleForLocale(Locale? locale) {
    if (locale?.languageCode.toLowerCase() == 'ar') return titleAr;
    return titleEn;
  }
}

/// Ordered roughly like the web sidebar: People → Learning → Operation → Community → Finance → Insights.
const List<AdminWebDashboardShortcut> kAdminWebDashboardShortcuts = [
  AdminWebDashboardShortcut(
    path: '/admin',
    titleEn: 'Dashboard',
    titleAr: 'لوحة التحكم',
    icon: Icons.dashboard_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/people/admins',
    titleEn: 'Admins',
    titleAr: 'المسؤولون',
    icon: Icons.admin_panel_settings_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/people/clients',
    titleEn: 'Clients',
    titleAr: 'العملاء',
    icon: Icons.groups_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/people/freelancers',
    titleEn: 'Freelancers',
    titleAr: 'المستقلون',
    icon: Icons.work_outline,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/learning/categories',
    titleEn: 'Categories',
    titleAr: 'التصنيفات',
    icon: Icons.category_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/operation/verifications',
    titleEn: 'Verifications',
    titleAr: 'التوثيقات',
    icon: Icons.verified_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/operation/content-reports',
    titleEn: 'Content reports',
    titleAr: 'بلاغات المحتوى',
    icon: Icons.flag_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/operation/projects',
    titleEn: 'Projects',
    titleAr: 'المشاريع',
    icon: Icons.folder_open_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/operation/pending-approvals',
    titleEn: 'Pending approvals',
    titleAr: 'موافقات معلقة',
    icon: Icons.pending_actions_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/operation/pending-bidding-approvals',
    titleEn: 'Bidding approvals',
    titleAr: 'موافقات العروض',
    icon: Icons.gavel_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/community/blogs',
    titleEn: 'Blogs',
    titleAr: 'المدونة',
    icon: Icons.article_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/finance/payments',
    titleEn: 'Finance · Payments',
    titleAr: 'المالية · المدفوعات',
    icon: Icons.account_balance_wallet_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/finance/plans',
    titleEn: 'Finance · Plans',
    titleAr: 'المالية · الخطط',
    icon: Icons.layers_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/finance/subscriptions',
    titleEn: 'Finance · Subscriptions',
    titleAr: 'المالية · الاشتراكات',
    icon: Icons.subscriptions_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/analytics',
    titleEn: 'Analytics',
    titleAr: 'التحليلات',
    icon: Icons.bar_chart_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/referrals',
    titleEn: 'Referrals',
    titleAr: 'الإحالات',
    icon: Icons.share_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/tender-vault',
    titleEn: 'Tender vault',
    titleAr: 'مستودع العطاءات',
    icon: Icons.inventory_2_outlined,
  ),
  AdminWebDashboardShortcut(
    path: '/admin/settings',
    titleEn: 'Settings',
    titleAr: 'الإعدادات',
    icon: Icons.settings_outlined,
  ),
];
