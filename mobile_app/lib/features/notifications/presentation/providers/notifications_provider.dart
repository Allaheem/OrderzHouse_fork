// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository();
});

/// Provider for fetching all notifications
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    ref.watch(authEpochProvider);
    final userId = ref.watch(authStateProvider.select((s) => s.userId));
    if (userId == null) return [];
    final repository = ref.read(notificationsRepositoryProvider);
    final response = await repository.fetchNotifications(
      limit: 50,
      offset: 0,
      unreadOnly: false,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.message ?? 'Failed to fetch notifications');
  },
);

/// Provider for fetching unread notifications count
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(authEpochProvider);
  final userId = ref.watch(authStateProvider.select((s) => s.userId));
  if (userId == null) return 0;
  final repository = ref.read(notificationsRepositoryProvider);
  final response = await repository.fetchUnreadCount(unreadOnly: true);

  if (response.success && response.data != null) {
    return response.data!;
  }

  return 0; // Return 0 on error instead of throwing
});

/// Provider for marking a notification as read
final markNotificationAsReadProvider = FutureProvider.family
    .autoDispose<void, int>((ref, notificationId) async {
      final repository = ref.read(notificationsRepositoryProvider);
      final response = await repository.markAsRead(notificationId);

      if (response.success) {
        // Invalidate providers to refresh data
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadCountProvider);
        return;
      }

      throw Exception(
        response.message ?? 'Failed to mark notification as read',
      );
    });
