// ??? ????????
/// Central API path constants. Use these instead of string literals in data layer.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // ——— Projects ———
  static const String myProjects = '/projects/myprojects';
  static const String projectCategory = '/projects/category';
  static const String projectPublicCategory = '/projects/public/category';
  static const String projectPublicSubcategory = '/projects/public/subcategory';
  static const String projectPublicSubSubcategory =
      '/projects/public/subsubcategory';
  static const String categories = '/category/';
  static String projectCategoryId(int id) => '$projectCategory/$id';
  static String projectPublicCategoryId(int id) => '$projectPublicCategory/$id';
  static String projectPublicSubcategoryId(int id) =>
      '$projectPublicSubcategory/$id';
  static String projectPublicSubSubcategoryId(int id) =>
      '$projectPublicSubSubcategory/$id';

  static String projectApply(int projectId) => '/projects/$projectId/apply';
  static String projectDetail(int projectId) => '/projects/$projectId';
  static String projectChangeRequests(int projectId) =>
      '/projects/$projectId/change-requests';
  static String projectRequestChanges(int projectId) =>
      '/projects/$projectId/request-changes';
  static String projectDeliveries(int projectId) =>
      '/projects/$projectId/deliveries';
  static String projectDeliver(int projectId) => '/projects/$projectId/deliver';
  static String projectApprove(int projectId) => '/projects/$projectId/approve';
  static String projectFiles(int projectId) => '/projects/$projectId/files';
  static String projectApplications(int projectId) =>
      '/projects/project/$projectId/applications';

  // ——— Assignments ———
  static String assignmentMyAssignment(int projectId) =>
      '/assignments/$projectId/my-assignment';
  static String assignmentCheck(int projectId) =>
      '/assignments/$projectId/check';

  // ——— Offers ———
  static String offersByProject(int projectId) =>
      '/offers/project/$projectId/offers';
  static const String offersApproveReject = '/offers/approve-reject';

  // ——— Notifications ———
  static const String notifications = '/notifications';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsCount = '/notifications/count';

  // ——— Auth / Users ———
  static const String getUserData = '/users/getUserdata';
  static const String login = '/users/login';
  static const String verifyOtp = '/users/verify-otp';
  static const String register = '/users/register';
  static const String verifyEmail = '/users/verify-email';
  static const String acceptTerms = '/auth/accept-terms';
  static const String deactivateUser = '/users/deactivate';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';

  // ——— Payments ———
  static const String paymentsClientHistory = '/payments/client/history';
  static const String paymentsFreelancerTransactions =
      '/payments/freelancer/wallet/transactions';
  static const String paymentsFreelancerWallet = '/payments/freelancer/wallet';

  // ——— Chat ———
  static String chatProjectMessages(int projectId) =>
      '/chat/project/$projectId/messages';
  static String chatProjectUnread(int projectId) =>
      '/chat/project/$projectId/unread';
  static String chatProjectRead(int projectId) =>
      '/chat/project/$projectId/read';
}
