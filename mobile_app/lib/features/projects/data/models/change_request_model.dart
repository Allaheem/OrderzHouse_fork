// ??? ????????
import 'package:intl/intl.dart';

class ChangeRequest {
  final int id;
  final int projectId;
  final String message;
  final DateTime createdAt;
  final bool? isResolved;

  ChangeRequest({
    required this.id,
    required this.projectId,
    required this.message,
    required this.createdAt,
    this.isResolved,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> json) {
    return ChangeRequest(
      id: json['id'] as int,
      projectId: json['project_id'] as int? ?? json['projectId'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      createdAt: _dateTimeFromJson(json['created_at'] ?? json['createdAt']),
      isResolved: json['is_resolved'] as bool? ?? json['isResolved'] as bool?,
    );
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

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
    } else if (difference.inDays > 0) {
      return DateFormat('EEE HH:mm').format(createdAt);
    } else if (difference.inHours > 0) {
      return DateFormat('HH:mm').format(createdAt);
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
