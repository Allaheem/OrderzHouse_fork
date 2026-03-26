// ??? ????????
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'notification_model.dart';

/// Target route and parameters for notification navigation
class NotificationTarget {
  final String route;
  final Map<String, String> pathParams;
  final Map<String, String> queryParams;
  final Map<String, dynamic>? extra;

  const NotificationTarget({
    required this.route,
    this.pathParams = const {},
    this.queryParams = const {},
    this.extra,
  });

  /// Navigate using go_router
  void navigate(BuildContext context) {
    // Build path with params
    String path = route;
    for (final entry in pathParams.entries) {
      path = path.replaceAll(':${entry.key}', entry.value);
    }

    // Build URI with query params
    final uri = Uri(
      path: path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (extra != null) {
      context.push(uri.toString(), extra: extra);
    } else {
      context.push(uri.toString());
    }
  }
}

/// Mapper to convert notification to navigation target
class NotificationTargetMapper {
  /// Map notification to target based on type and role
  /// Returns null if notification cannot be navigated
  static NotificationTarget? mapNotificationToTarget(
    AppNotification notification,
    int userRoleId, // 2 = CLIENT, 3 = FREELANCER
  ) {
    final isClient = userRoleId == 2;
    final type = notification.type?.toLowerCase() ?? '';
    // Use primaryProjectId which handles projectId and referenceId fallback
    final projectId = notification.primaryProjectId;

    // PROJECT-RELATED NOTIFICATIONS
    if (notification.isProjectRelated && projectId != null) {
      // Work submitted - client sees deliveries, freelancer sees their submission
      if (notification.isDeliveryRelated) {
        if (isClient) {
          return NotificationTarget(
            route: '/project/:id',
            pathParams: {'id': projectId.toString()},
            queryParams: {'openReceiveModal': 'true'},
          );
        } else {
          // Freelancer: for work_revision_requested, navigate to project (they can see messages)
          // For other delivery types, just show project details
          if (type == NotificationType.workRevisionRequested.toLowerCase()) {
            return NotificationTarget(
              route: '/project/:id',
              pathParams: {'id': projectId.toString()},
            );
          }
          // Freelancer: just show project details
          return NotificationTarget(
            route: '/project/:id',
            pathParams: {'id': projectId.toString()},
          );
        }
      }

      // Offer-related - client sees applicants/offers, freelancer sees their offer
      if (notification.isOfferRelated) {
        if (isClient) {
          return NotificationTarget(
            route: '/project/:id',
            pathParams: {'id': projectId.toString()},
            queryParams: {'openApplicants': 'true'},
          );
        } else {
          // Freelancer: navigate to their projects or offers screen
          return const NotificationTarget(route: '/freelancer/projects');
        }
      }

      // Freelancer assigned/removed - both roles see project
      if (type.contains('freelancer_assigned') ||
          type.contains('freelancer_removed')) {
        return NotificationTarget(
          route: '/project/:id',
          pathParams: {'id': projectId.toString()},
        );
      }

      // Project created/status changed - navigate to project
      return NotificationTarget(
        route: '/project/:id',
        pathParams: {'id': projectId.toString()},
      );
    }

    // PAYMENT-RELATED NOTIFICATIONS
    if (notification.isPaymentRelated) {
      // Navigate to payments screen
      final rolePrefix = isClient ? '/client' : '/freelancer';
      return NotificationTarget(route: '$rolePrefix/payments');
    }

    // MESSAGE-RELATED NOTIFICATIONS
    if (notification.isMessageRelated && projectId != null) {
      // TODO: Navigate to chat when implemented
      // For now, navigate to project (messages are usually project-related)
      return NotificationTarget(
        route: '/project/:id',
        pathParams: {'id': projectId.toString()},
      );
    }

    // TASK-RELATED NOTIFICATIONS
    if (notification.isTaskRelated && projectId != null) {
      // TODO: Navigate to task details when implemented
      // For now, navigate to project
      return NotificationTarget(
        route: '/project/:id',
        pathParams: {'id': projectId.toString()},
      );
    }

    // REVIEW-RELATED
    if (type == NotificationType.reviewSubmitted) {
      final rolePrefix = isClient ? '/client' : '/freelancer';
      return NotificationTarget(route: '$rolePrefix/profile');
    }

    // SUBSCRIPTION-RELATED
    if (type.contains('subscription')) {
      return const NotificationTarget(route: '/plans');
    }

    // APPOINTMENT-RELATED
    if (type.contains('appointment') && projectId != null) {
      // TODO: Navigate to appointment details when implemented
      return null;
    }

    // SYSTEM ANNOUNCEMENT - no navigation
    if (type == NotificationType.systemAnnouncement) {
      return null;
    }

    // FALLBACK: If we have a projectId, try to navigate to project
    if (projectId != null) {
      return NotificationTarget(
        route: '/project/:id',
        pathParams: {'id': projectId.toString()},
      );
    }

    // No valid target
    return null;
  }
}
