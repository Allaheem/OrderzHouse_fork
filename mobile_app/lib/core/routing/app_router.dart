// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/project.dart';
import '../../core/models/user.dart';
import '../../core/routing/route_tracker.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/freelancer/presentation/screens/freelancer_home_screen.dart';
import '../../features/freelancer/presentation/screens/freelancer_projects_screen.dart';
import '../../features/client/presentation/screens/client_home_screen.dart';
import '../../features/client/presentation/screens/client_projects_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_webview_screen.dart';
import '../../features/common/presentation/screens/explore_projects_screen.dart';
import '../../features/common/presentation/screens/project_details_screen.dart';
import '../../features/common/presentation/screens/applicants_screen.dart';
import '../../features/common/presentation/screens/deliveries_screen.dart';
import '../../features/common/presentation/screens/payments_screen.dart';
import '../../features/common/presentation/screens/profile_screen.dart';
import '../../features/common/presentation/screens/edit_profile_screen.dart';
import '../../features/common/presentation/screens/settings_screen.dart';
import '../../features/common/presentation/screens/subscription_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_screen.dart';
import '../../features/legal/presentation/screens/help_faq_screen.dart';
import '../../features/common/presentation/screens/delete_account_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/common/presentation/screens/my_content_screen.dart';
import '../../features/common/presentation/screens/support_screen.dart';
import '../../features/common/presentation/screens/notifications_settings_screen.dart';
import '../../features/common/presentation/screens/security_center_screen.dart';
import '../../features/projects/presentation/pages/create_project_wizard_page.dart';
import '../../features/projects/presentation/screens/project_success_screen.dart';
import '../../features/common/presentation/screens/talent_details_screen.dart';
import '../../features/common/presentation/screens/health_check_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/accept_terms_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_otp_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/common/presentation/screens/language_selection_screen.dart';
import '../../features/common/presentation/screens/blocked_users_screen.dart';
import '../../features/messages/presentation/screens/project_messages_screen.dart';
import '../../features/projects/presentation/screens/change_requests_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final _authRefreshNotifier = _AuthRefreshNotifier();

/// Registers listener so router redirect runs when auth state changes.
final _authRefreshListenableProvider = Provider<_AuthRefreshNotifier>((ref) {
  ref.listen<AuthState>(
    authStateProvider,
    (_, _) => _authRefreshNotifier.refresh(),
  );
  return _authRefreshNotifier;
});

String _defaultHome(AuthState auth) {
  if (auth.user?.isAdmin == true) return '/admin';
  return auth.userRole == 'freelancer' ? '/freelancer' : '/client';
}

/// Admin must not restore a stale /client or /freelancer deep link (those APIs return "Role not allowed").
bool _lastRouteIncompatibleWithUser(String last, AuthState auth) {
  if (auth.user?.isAdmin != true) return false;
  return last.startsWith('/client') || last.startsWith('/freelancer');
}

bool _isPublicRoute(String path) {
  final p = path.startsWith('/') ? path : '/$path';
  return p == '/explore' ||
      p.startsWith('/project/') ||
      p == '/terms' ||
      p == '/terms-conditions' ||
      p == '/privacy-policy' ||
      p == '/help-faq' ||
      p == '/health-check';
}

String? _redirect(BuildContext context, GoRouterState state) {
  final auth = ProviderScope.containerOf(context).read(authStateProvider);
  final path = state.uri.path;

  if (auth.isChecking) return '/splash';
  if (!auth.isAuthenticated) {
    if (path == '/splash') return '/login';
    if (RouteTracker.isAuthRoute(path)) return null;
    if (_isPublicRoute(path)) return null;
    return '/login';
  }
  if (auth.user?.mustAcceptTerms == true) {
    if (path == '/accept-terms') return null;
    return '/accept-terms';
  }
  if (auth.user?.isAdmin == true &&
      (path.startsWith('/client') || path.startsWith('/freelancer'))) {
    return '/admin';
  }
  if (RouteTracker.isAuthRoute(path) || path == '/splash') {
    final last = RouteTracker.getLastRoute();
    final home = _defaultHome(auth);
    if (last != null && !_lastRouteIncompatibleWithUser(last, auth)) {
      return last;
    }
    return home;
  }
  RouteTracker.saveLastRoute(path);
  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(_authRefreshListenableProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: _authRefreshNotifier,
    initialLocation: '/splash',
    redirect: _redirect,
    routes: _appRoutes,
  );
});

final List<RouteBase> _appRoutes = [
  GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
  GoRoute(
    path: '/onboarding',
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  GoRoute(
    path: '/register',
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: '/explore',
    builder: (context, state) => const ExploreProjectsScreen(readOnly: true),
  ),
  GoRoute(
    path: '/verify-email',
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      return VerifyEmailScreen(email: email);
    },
  ),
  GoRoute(
    path: '/verify-otp',
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      return VerifyOtpScreen(email: email);
    },
  ),
  GoRoute(
    path: '/accept-terms',
    builder: (context, state) => const AcceptTermsScreen(),
  ),
  // Forgot Password Flow
  GoRoute(
    path: '/forgot-password',
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: '/reset-otp',
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      return ResetPasswordOtpScreen(email: email);
    },
  ),
  GoRoute(
    path: '/reset-password',
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      final otp = state.uri.queryParameters['otp'] ?? '';
      return ResetPasswordScreen(email: email, otp: otp);
    },
  ),
  // Freelancer Routes
  GoRoute(
    path: '/freelancer',
    builder: (context, state) => const FreelancerHomeScreen(),
    routes: [
      GoRoute(
        path: 'projects',
        builder: (context, state) => const FreelancerProjectsScreen(),
      ),
      GoRoute(
        path: 'explore',
        builder: (context, state) =>
            const ExploreProjectsScreen(readOnly: false),
      ),
      GoRoute(
        path: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: 'notifications',
        name: 'freelancerNotifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  ),
  // Admin: in-app explore/payments/profile + web shortcuts on AdminHomeScreen
  GoRoute(
    path: '/admin',
    builder: (context, state) => const AdminHomeScreen(),
    routes: [
      GoRoute(
        path: 'explore',
        builder: (context, state) =>
            const ExploreProjectsScreen(readOnly: false),
      ),
      GoRoute(
        path: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: 'notifications',
        name: 'adminNotifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: 'web-console',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AdminWebViewParams) {
            return AdminWebViewScreen(params: extra);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Admin')),
            body: const Center(
              child: Text('Could not open this page. Go back and try again.'),
            ),
          );
        },
      ),
    ],
  ),
  // Client Routes
  GoRoute(
    path: '/client',
    builder: (context, state) => const ClientHomeScreen(),
    routes: [
      GoRoute(
        path: 'projects',
        builder: (context, state) => const ClientProjectsScreen(),
      ),
      GoRoute(
        path: 'explore',
        builder: (context, state) =>
            const ExploreProjectsScreen(readOnly: true),
      ),
      GoRoute(
        path: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: 'notifications',
        name: 'clientNotifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  ),
  // Common Routes
  GoRoute(
    path: '/project/:id',
    builder: (context, state) {
      // Parse deep-link query parameters for notification navigation
      final openApplicants =
          state.uri.queryParameters['openApplicants'] == 'true';
      final openReceiveModal =
          state.uri.queryParameters['openReceiveModal'] == 'true';
      final showDeliveries =
          state.uri.queryParameters['showDeliveries'] == 'true';

      // Try to get project from extra (when navigating from explore/my projects)
      final project = state.extra;
      if (project != null && project is Project) {
        return ProjectDetailsScreen(
          project: project,
          openApplicants: openApplicants,
          openReceiveModal: openReceiveModal,
          showDeliveries: showDeliveries,
        );
      }

      // Otherwise, parse projectId from path and fetch from API
      final idString = state.pathParameters['id'] ?? '0';
      final id = int.tryParse(idString);
      if (id == null || id == 0) {
        // Invalid ID, show error screen
        return const Scaffold(body: Center(child: Text('Invalid project ID')));
      }

      // Pass projectId to screen, which will fetch the project
      return ProjectDetailsScreen(
        projectId: id,
        openApplicants: openApplicants,
        openReceiveModal: openReceiveModal,
        showDeliveries: showDeliveries,
      );
    },
  ),
  GoRoute(
    path: '/project/:id/applicants',
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id'] ?? '0');
      return ApplicantsScreen(projectId: id);
    },
  ),
  GoRoute(
    path: '/project/:id/deliveries',
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id'] ?? '0');
      return DeliveriesScreen(projectId: id);
    },
  ),
  GoRoute(
    path: '/project/:id/messages',
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id'] ?? '0');
      return ProjectMessagesScreen(projectId: id);
    },
  ),
  GoRoute(
    path: '/project/:id/change-requests',
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id'] ?? '0');
      final title = state.uri.queryParameters['title'] ?? '';
      return ChangeRequestsScreen(projectId: id, projectTitle: title);
    },
  ),
  GoRoute(
    path: '/create-project',
    builder: (context, state) => const CreateProjectWizardPage(),
  ),
  GoRoute(
    path: '/project-success/:id',
    builder: (context, state) {
      final idStr = state.pathParameters['id'] ?? '0';
      final id = int.tryParse(idStr) ?? 0;
      return ProjectSuccessScreen(projectId: id);
    },
  ),
  GoRoute(
    path: '/talent/:id',
    builder: (context, state) {
      final id = int.parse(state.pathParameters['id'] ?? '0');
      return TalentDetailsScreen(freelancerId: id);
    },
  ),
  GoRoute(
    path: '/edit-profile',
    builder: (context, state) => const EditProfileScreen(),
  ),
  GoRoute(
    path: '/change-password',
    builder: (context, state) => const ChangePasswordScreen(),
  ),
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: '/subscription',
    redirect: (context, state) {
      // Guard: Check user role - redirect handled in SubscriptionScreen
      // This allows the screen to handle the check with proper provider access
      return null;
    },
    builder: (context, state) => const SubscriptionScreen(),
  ),
  GoRoute(
    path: '/health-check',
    builder: (context, state) => const HealthCheckScreen(),
  ),
  GoRoute(
    path: '/help-faq',
    builder: (context, state) => const HelpFaqScreen(),
  ),
  GoRoute(
    path: '/privacy-policy',
    builder: (context, state) => const PrivacyPolicyScreen(),
  ),
  GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
  GoRoute(
    path: '/terms-conditions',
    builder: (context, state) => const TermsScreen(),
  ),
  GoRoute(
    path: '/settings/delete-account',
    builder: (context, state) => const DeleteAccountScreen(),
  ),
  GoRoute(
    path: '/settings/my-content',
    builder: (context, state) => const MyContentScreen(),
  ),
  GoRoute(
    path: '/settings/blocked-users',
    builder: (context, state) => const BlockedUsersScreen(),
  ),
  GoRoute(path: '/support', builder: (context, state) => const SupportScreen()),
  GoRoute(
    path: '/settings/notifications',
    builder: (context, state) => const NotificationsSettingsScreen(),
  ),
  GoRoute(
    path: '/settings/security',
    builder: (context, state) => const SecurityCenterScreen(),
  ),
  GoRoute(
    path: '/settings/language',
    builder: (context, state) => const LanguageSelectionScreen(),
  ),
];
