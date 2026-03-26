// ??? ????????
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Notification types matching backend NOTIFICATION_TYPES
class NotificationType {
  static const String projectCreated = 'project_created';
  static const String projectStatusChanged = 'project_status_changed';

  static const String offerSubmitted = 'offer_submitted';
  static const String offerApproved = 'offer_approved';
  static const String offerRejected = 'offer_rejected';

  static const String freelancerAssigned = 'freelancer_assigned';
  static const String freelancerRemoved = 'freelancer_removed';

  static const String workSubmitted = 'work_submitted';
  static const String workApproved = 'work_approved';
  static const String workRevisionRequested = 'work_revision_requested';

  static const String escrowCreated = 'escrow_created';
  static const String escrowReleased = 'escrow_released';

  static const String paymentReleased = 'payment_released';
  static const String paymentApproved = 'payment_approved';
  static const String paymentRejected = 'payment_rejected';
  static const String paymentPending = 'payment_pending';

  static const String taskRequested = 'task_requested';
  static const String taskRequestAccepted = 'task_request_accepted';
  static const String taskRequestRejected = 'task_request_rejected';
  static const String taskCompleted = 'task_completed';
  static const String taskNeedsApproval = 'task_needs_approval';

  static const String userRegistered = 'user_registered';
  static const String userVerified = 'user_verified';
  static const String userVerificationRejected = 'user_verification_rejected';

  static const String reviewSubmitted = 'review_submitted';
  static const String messageReceived = 'message_received';

  static const String appointmentScheduled = 'appointment_scheduled';
  static const String appointmentCancelled = 'appointment_cancelled';
  static const String appointmentRequested = 'appointment_requested';
  static const String appointmentRescheduled = 'appointment_rescheduled';
  static const String appointmentCompleted = 'appointment_completed';

  static const String courseEnrolled = 'course_enrolled';
  static const String subscriptionStatusChanged = 'subscription_status_changed';

  static const String systemAnnouncement = 'system_announcement';
  static const String chatsAdmin = 'chats_admin';
}

/// Entity types from backend
class EntityType {
  static const String project = 'project';
  static const String offer = 'offer';
  static const String message = 'message';
  static const String task = 'task';
  static const String taskRequest = 'task_request';
  static const String review = 'review';
  static const String escrow = 'escrow';
  static const String system = 'system';
}

class AppNotification {
  final int id;
  final String title;
  final String? body;
  final String? type;
  final int? referenceId;
  final String? entityType;
  final bool isRead;
  final DateTime createdAt;

  // Additional IDs for navigation (extracted from metadata or referenceId)
  final int? projectId;
  final int? assignmentId;
  final int? offerId;
  final int? paymentId;
  final int? messageId;
  final int? taskId;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.type,
    this.referenceId,
    this.entityType,
    required this.isRead,
    required this.createdAt,
    this.projectId,
    this.assignmentId,
    this.offerId,
    this.paymentId,
    this.messageId,
    this.taskId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Extract IDs from various possible fields
    final refId =
        json['reference_id'] as int? ??
        json['referenceId'] as int? ??
        json['related_entity_id'] as int?;

    // Try to extract specific IDs from metadata or separate fields
    final metadata = json['metadata'] as Map<String, dynamic>?;
    final projectId =
        json['project_id'] as int? ??
        json['projectId'] as int? ??
        metadata?['project_id'] as int? ??
        metadata?['projectId'] as int?;

    final assignmentId =
        json['assignment_id'] as int? ??
        json['assignmentId'] as int? ??
        metadata?['assignment_id'] as int? ??
        metadata?['assignmentId'] as int?;

    final offerId =
        json['offer_id'] as int? ??
        json['offerId'] as int? ??
        metadata?['offer_id'] as int? ??
        metadata?['offerId'] as int?;

    final paymentId =
        json['payment_id'] as int? ??
        json['paymentId'] as int? ??
        metadata?['payment_id'] as int? ??
        metadata?['paymentId'] as int?;

    final messageId =
        json['message_id'] as int? ??
        json['messageId'] as int? ??
        metadata?['message_id'] as int? ??
        metadata?['messageId'] as int?;

    final taskId =
        json['task_id'] as int? ??
        json['taskId'] as int? ??
        metadata?['task_id'] as int? ??
        metadata?['taskId'] as int?;

    // If entityType is 'project' and we have referenceId but no projectId, use referenceId
    final entityType =
        json['entity_type'] as String? ?? json['entityType'] as String?;
    final resolvedProjectId =
        projectId ?? (entityType == 'project' ? refId : null);

    return AppNotification(
      id: json['id'] as int,
      title:
          json['title'] as String? ??
          json['notification_title'] as String? ??
          'Notification',
      body:
          json['body'] as String? ??
          json['message'] as String? ??
          json['notification_body'] as String?,
      type: json['type'] as String? ?? json['notification_type'] as String?,
      referenceId: refId,
      entityType: entityType,
      isRead:
          json['is_read'] as bool? ??
          json['read_status'] as bool? ??
          json['isRead'] as bool? ??
          false,
      createdAt: _dateTimeFromJson(json['created_at'] ?? json['createdAt']),
      projectId: resolvedProjectId,
      assignmentId: assignmentId,
      offerId: offerId,
      paymentId: paymentId,
      messageId: messageId,
      taskId: taskId,
    );
  }

  /// Get the primary project ID for navigation (projectId or referenceId if entityType is project)
  int? get primaryProjectId {
    if (projectId != null) return projectId;
    if (entityType == EntityType.project && referenceId != null)
      return referenceId;
    return null;
  }

  /// Check if this notification should open project details
  bool get isProjectRelated {
    if (entityType == EntityType.project || entityType == EntityType.escrow)
      return true;
    final t = type?.toLowerCase() ?? '';
    return t.contains('project') ||
        t.contains('work') ||
        t.contains('freelancer_assigned') ||
        t.contains('freelancer_removed');
  }

  /// Check if this notification should open applicants/offers
  bool get isOfferRelated {
    if (entityType == EntityType.offer) return true;
    final t = type?.toLowerCase() ?? '';
    return t.contains('offer');
  }

  /// Check if this is a delivery/work notification
  bool get isDeliveryRelated {
    final t = type?.toLowerCase() ?? '';
    return t == NotificationType.workSubmitted ||
        t == NotificationType.workApproved ||
        t == NotificationType.workRevisionRequested;
  }

  /// Check if this is a payment notification
  bool get isPaymentRelated {
    if (entityType == EntityType.escrow) return true;
    final t = type?.toLowerCase() ?? '';
    return t.contains('payment') || t.contains('escrow');
  }

  /// Check if this is a message notification
  bool get isMessageRelated {
    if (entityType == EntityType.message) return true;
    final t = type?.toLowerCase() ?? '';
    return t.contains('message');
  }

  /// Check if this is a task notification
  bool get isTaskRelated {
    if (entityType == EntityType.task || entityType == EntityType.taskRequest)
      return true;
    final t = type?.toLowerCase() ?? '';
    return t.contains('task');
  }

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.now();
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(createdAt);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  IconData get iconData {
    if (type == null) return Icons.notifications_outlined;

    switch (type!.toLowerCase()) {
      case 'project_created':
      case 'project_status_changed':
        return Icons.work_outline_rounded;
      case 'offer_submitted':
      case 'offer_approved':
      case 'offer_rejected':
        return Icons.local_offer_outlined;
      case 'payment_released':
      case 'payment_approved':
      case 'payment_rejected':
      case 'payment_pending':
        return Icons.payment_outlined;
      case 'work_submitted':
      case 'work_approved':
        return Icons.task_outlined;
      case 'work_revision_requested':
        return Icons.edit_note_rounded;
      case 'message_received':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }
}
