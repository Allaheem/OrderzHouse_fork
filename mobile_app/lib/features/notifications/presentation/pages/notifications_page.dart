// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/notification_target.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/notifications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);

    return AppScaffold(
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: AppColors.accentOrange,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        // Fallback: navigate to home based on role
                        final location = GoRouterState.of(context).uri.path;
                        if (location.contains('/client')) {
                          context.go('/client');
                        } else if (location.contains('/freelancer')) {
                          context.go('/freelancer');
                        } else {
                          context.go('/client');
                        }
                      }
                    },
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    l10n.notifications,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentOrange,
                  ),
                ),
              ),
              error: (error, stackTrace) => ErrorState(
                message: error.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: l10n.noNotifications,
                    message: l10n.noNotificationsMessage,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  },
                  color: AppColors.accentOrange,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(context, ref, notification);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return InkWell(
      onTap: () => _handleNotificationTap(context, ref, notification),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? AppColors.borderLight
                : AppColors.accentOrange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                notification.iconData,
                color: AppColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notification.body != null &&
                      notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    notification.timeAgo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Mark as read if unread (optimistic UI - don't block navigation on failure)
    if (!notification.isRead) {
      try {
        await ref.read(markNotificationAsReadProvider(notification.id).future);
        // Refresh notifications list
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadCountProvider);
      } catch (_) {
        // Keep navigation resilient even if marking read fails.
      }
    }

    if (!context.mounted) return;

    // Get user role for mapper
    final authState = ref.read(authStateProvider);
    final userRoleId = authState.user?.roleId;

    if (userRoleId == null) {
      _showErrorSnackbar(context, 'User role not found');
      return;
    }

    // Map notification to target using the unified mapper
    final target = NotificationTargetMapper.mapNotificationToTarget(
      notification,
      userRoleId,
    );

    if (target == null) {
      // No valid target - show snackbar
      final l10nNav = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10nNav.thisNotificationHasNoLink),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    // Navigate to target (same go_router route as MyProjects: /project/:id)
    try {
      target.navigate(context);
    } catch (_) {
      _showErrorSnackbar(context, 'Failed to open notification link');
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
