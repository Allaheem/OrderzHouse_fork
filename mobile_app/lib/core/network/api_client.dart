// ??? ????????
import 'package:dio/dio.dart';
import 'dio_client.dart';

/// Typed API layer on top of Dio. All endpoint paths live here to avoid 404 mistakes.
/// Repositories call these methods and parse response.data; error handling stays in repositories.
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  Dio get _dio => DioClient.instance;

  // ——— Projects ———
  /// GET /projects/myprojects
  /// [statusKey] optional filter e.g. "in_progress" for workspace In progress tab
  Future<Response> getMyProjects({
    int page = 1,
    int limit = 20,
    String? statusKey,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (statusKey != null && statusKey.isNotEmpty) {
      params['status'] = statusKey;
    }
    return _dio.get('/projects/myprojects', queryParameters: params);
  }

  /// GET /projects/category/:categoryId (authenticated)
  Future<Response> getProjectsByCategory(
    int categoryId, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(
      '/projects/category/$categoryId',
      queryParameters: queryParameters,
    );
  }

  /// GET /projects/public/category/:categoryId (public fallback)
  Future<Response> getPublicProjectsByCategory(
    int categoryId, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(
      '/projects/public/category/$categoryId',
      queryParameters: queryParameters,
    );
  }

  /// GET /category/ (all categories)
  Future<Response> getCategories() {
    return _dio.get('/category/');
  }

  /// GET /projects/:projectId/change-requests
  Future<Response> getChangeRequests(int projectId) {
    return _dio.get('/projects/$projectId/change-requests');
  }

  /// PATCH /projects/:projectId/change-requests/mark-read
  Future<Response> markChangeRequestsRead(int projectId) {
    return _dio.patch('/projects/$projectId/change-requests/mark-read');
  }

  /// POST /projects/:projectId/request-changes
  Future<Response> requestChanges(
    int projectId, {
    required Map<String, dynamic> body,
  }) {
    return _dio.post('/projects/$projectId/request-changes', data: body);
  }

  /// GET /projects/project/:projectId/applications
  Future<Response> getProjectApplications(int projectId) {
    return _dio.get('/projects/project/$projectId/applications');
  }

  /// POST /projects/applications/decision
  Future<Response> postApplicationsDecision(Map<String, dynamic> body) {
    return _dio.post('/projects/applications/decision', data: body);
  }

  /// POST /projects/:projectId/apply
  Future<Response> applyToProject(int projectId, {Map<String, dynamic>? body}) {
    return _dio.post('/projects/$projectId/apply', data: body ?? {});
  }

  /// POST /projects
  Future<Response> createProject(FormData formData) {
    return _dio.post('/projects', data: formData);
  }

  /// POST /projects/:projectId/files
  Future<Response> addProjectFiles(int projectId, FormData formData) {
    return _dio.post('/projects/$projectId/files', data: formData);
  }

  /// POST /projects/:projectId/deliver
  Future<Response> deliverProject(int projectId, FormData formData) {
    return _dio.post('/projects/$projectId/deliver', data: formData);
  }

  /// GET /projects/:projectId/deliveries
  Future<Response> getProjectDeliveries(int projectId) {
    return _dio.get('/projects/$projectId/deliveries');
  }

  /// PUT /projects/:projectId/approve
  Future<Response> approveProject(int projectId, {Map<String, dynamic>? body}) {
    return _dio.put('/projects/$projectId/approve', data: body ?? {});
  }

  /// GET /assignments/:projectId/my-assignment
  Future<Response> getMyAssignment(int projectId) {
    return _dio.get('/assignments/$projectId/my-assignment');
  }

  /// GET /assignments/:projectId/check
  Future<Response> checkAssignment(int projectId) {
    return _dio.get('/assignments/$projectId/check');
  }

  /// GET /offers/project/:projectId/offers
  Future<Response> getProjectOffers(int projectId) {
    return _dio.get('/offers/project/$projectId/offers');
  }

  // ——— Notifications ———
  /// GET /notifications
  Future<Response> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) {
    return _dio.get(
      '/notifications',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'unreadOnly': unreadOnly.toString(),
      },
    );
  }

  /// PUT /notifications/:notificationId/read
  Future<Response> markNotificationRead(int notificationId) {
    return _dio.put('/notifications/$notificationId/read');
  }

  /// GET /notifications/count
  Future<Response> getNotificationsCount({bool unreadOnly = true}) {
    return _dio.get(
      '/notifications/count',
      queryParameters: {'unreadOnly': unreadOnly.toString()},
    );
  }

  // ——— Auth / Users (for reference; auth_repository can keep using Dio directly or use this) ———
  /// GET /users/getUserdata
  Future<Response> getUserData() {
    return _dio.get('/users/getUserdata');
  }

  /// POST /users/login
  Future<Response> login(Map<String, dynamic> data) {
    return _dio.post('/users/login', data: data);
  }

  /// POST /users/verify-otp
  Future<Response> verifyOtp(Map<String, dynamic> data) {
    return _dio.post('/users/verify-otp', data: data);
  }

  /// POST /users/register
  Future<Response> register(Map<String, dynamic> data) {
    return _dio.post('/users/register', data: data);
  }

  /// POST /users/verify-email
  Future<Response> verifyEmail(Map<String, dynamic> data) {
    return _dio.post('/users/verify-email', data: data);
  }

  /// POST /auth/accept-terms
  Future<Response> acceptTerms() {
    return _dio.post('/auth/accept-terms');
  }

  /// PUT /users/deactivate
  Future<Response> deactivateUser({Map<String, dynamic>? body}) {
    return _dio.put('/users/deactivate', data: body ?? {});
  }

  /// PATCH /auth/change-password
  Future<Response> changePassword(Map<String, dynamic> data) {
    return _dio.patch('/auth/change-password', data: data);
  }

  /// POST /auth/forgot-password
  Future<Response> forgotPassword(Map<String, dynamic> data) {
    return _dio.post('/auth/forgot-password', data: data);
  }

  /// POST /auth/verify-reset-otp
  Future<Response> verifyResetOtp(Map<String, dynamic> data) {
    return _dio.post('/auth/verify-reset-otp', data: data);
  }

  /// POST /auth/reset-password
  Future<Response> resetPassword(Map<String, dynamic> data) {
    return _dio.post('/auth/reset-password', data: data);
  }

  // ——— Payments ———
  /// GET /payments/client/history
  Future<Response> getPaymentsClientHistory() {
    return _dio.get('/payments/client/history');
  }

  /// GET /payments/freelancer/wallet/transactions
  Future<Response> getPaymentsFreelancerTransactions() {
    return _dio.get('/payments/freelancer/wallet/transactions');
  }

  /// GET /payments/freelancer/wallet
  Future<Response> getPaymentsFreelancerWallet() {
    return _dio.get('/payments/freelancer/wallet');
  }

  // ——— Categories ———
  /// GET /category/:categoryId/sub-categories
  Future<Response> getSubCategories(int categoryId) {
    return _dio.get('/category/$categoryId/sub-categories');
  }

  /// GET /category/:categoryId/sub-sub-categories
  Future<Response> getSubSubCategories(int categoryId) {
    return _dio.get('/category/$categoryId/sub-sub-categories');
  }

  // ——— Chat / Messages ———
  /// GET /chat/project/:projectId/messages
  Future<Response> getChatProjectMessages(
    int projectId, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(
      '/chat/project/$projectId/messages',
      queryParameters: queryParameters,
    );
  }

  /// POST /chat/project/:projectId/messages
  Future<Response> postChatMessage(int projectId, Map<String, dynamic> body) {
    return _dio.post('/chat/project/$projectId/messages', data: body);
  }

  /// GET /chat/project/:projectId/unread
  Future<Response> getChatProjectUnreadCount(int projectId) {
    return _dio.get('/chat/project/$projectId/unread');
  }

  /// POST /chat/project/:projectId/read
  Future<Response> markChatProjectRead(int projectId) {
    return _dio.post('/chat/project/$projectId/read');
  }
}
