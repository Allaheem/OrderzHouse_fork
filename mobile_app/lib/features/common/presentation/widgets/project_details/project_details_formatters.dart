import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:OrderzHouse/core/theme/app_colors.dart';

Color projectDetailsStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'in_progress':
    case 'active':
      return AppColors.primary;
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String projectDetailsFormatDeliveryDate(dynamic date) {
  if (date == null) return 'Just now';
  try {
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (_) {
        dateTime = DateFormat(
          "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        ).parse(date, true).toLocal();
      }
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  } catch (e) {
    debugPrint('Date formatting error: $e for date: $date');
    return 'Recently';
  }
}

String projectDetailsFormatFileSize(dynamic size) {
  try {
    final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  } catch (e) {
    return '';
  }
}

IconData projectDetailsHistoryIcon(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
    case 'completed':
      return Icons.check_circle_rounded;
    case 'changes_requested':
    case 'rejected':
      return Icons.edit_rounded;
    default:
      return Icons.upload_rounded;
  }
}

Color projectDetailsHistoryColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
    case 'completed':
      return Colors.green;
    case 'changes_requested':
    case 'rejected':
      return Colors.orange;
    default:
      return AppColors.accentOrange;
  }
}

String projectDetailsHistoryTitle(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
    case 'completed':
      return 'Delivery approved';
    case 'changes_requested':
    case 'rejected':
      return 'Changes requested';
    default:
      return 'Delivery submitted';
  }
}
