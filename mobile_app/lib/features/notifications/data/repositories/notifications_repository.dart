// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/api_client.dart';

class NotificationsRepository {
  NotificationsRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Fetch notifications for the authenticated user
  /// Endpoint: GET /notifications
  /// Query params: limit, offset, unreadOnly
  /// Response: { success: true, notifications: [...] }
  Future<ApiResponse<List<AppNotification>>> fetchNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _api.getNotifications(
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
      );

      // Handle multiple response formats:
      // 1. { success: true, notifications: [...] }
      // 2. { notifications: [...] }
      // 3. { data: [...] }
      // 4. { data: { notifications: [...] } }
      // 5. Just an array [...]
      List<dynamic>? notificationsList;

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['notifications'] != null && data['notifications'] is List) {
          notificationsList = data['notifications'] as List<dynamic>;
        } else if (data['data'] != null) {
          if (data['data'] is List) {
            notificationsList = data['data'] as List<dynamic>;
          } else if (data['data'] is Map &&
              data['data']['notifications'] is List) {
            notificationsList =
                (data['data'] as Map<String, dynamic>)['notifications']
                    as List<dynamic>;
          }
        }
      } else if (response.data is List<dynamic>) {
        notificationsList = response.data as List<dynamic>;
      }

      if (notificationsList == null || notificationsList.isEmpty) {
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No notifications found',
        );
      }

      final notifications = notificationsList
          .map((item) {
            try {
              return AppNotification.fromJson(item as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();

      return ApiResponse(
        success: true,
        data: notifications,
        message: 'Notifications fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to fetch notifications',
        error: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch notifications',
      );
    }
  }

  /// Fetch unread notifications count
  /// Endpoint: GET /notifications/count
  /// Query params: unreadOnly (default: true)
  /// Response: { success: true, count: <int> }
  Future<ApiResponse<int>> fetchUnreadCount({bool unreadOnly = true}) async {
    try {
      final response = await _api.getNotificationsCount(unreadOnly: unreadOnly);

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final count = data['count'] as int? ?? 0;
        return ApiResponse(
          success: true,
          data: count,
          message: 'Unread count fetched successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: 0,
        message: data['message'] as String? ?? 'Failed to fetch unread count',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: 0,
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to fetch unread count',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: 0,
        message: 'Failed to fetch unread count',
      );
    }
  }

  /// Mark a notification as read
  /// Endpoint: PUT /notifications/:id/read
  /// Response: { success: true, message: "..." }
  Future<ApiResponse<void>> markAsRead(int notificationId) async {
    try {
      final response = await _api.markNotificationRead(notificationId);

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return ApiResponse(
          success: true,
          data: null,
          message: data['message'] as String? ?? 'Notification marked as read',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            data['message'] as String? ?? 'Failed to mark notification as read',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to mark notification as read',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to mark notification as read',
      );
    }
  }

  String? _extractErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
