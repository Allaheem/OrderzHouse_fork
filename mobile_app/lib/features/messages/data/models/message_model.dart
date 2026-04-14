// ??? ????????
import 'package:intl/intl.dart';

class Message {
  final int id;
  final int projectId;
  final int? taskId;
  final int senderId;
  final String content;
  final List<String>? fileUrls;
  final DateTime timeSent;

  // Sender info (from backend join)
  final MessageSender? sender;

  Message({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.senderId,
    required this.content,
    this.fileUrls,
    required this.timeSent,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle sender as object or nested JSON
    MessageSender? senderObj;
    if (json['sender'] != null) {
      if (json['sender'] is Map<String, dynamic>) {
        senderObj = MessageSender.fromJson(
          json['sender'] as Map<String, dynamic>,
        );
      } else if (json['sender'] is String) {
        try {
          senderObj = null;
        } catch (e) {
          senderObj = null;
        }
      }
    }

    // Handle file_urls
    List<String>? fileUrlsList;
    if (json['file_urls'] != null) {
      if (json['file_urls'] is List) {
        fileUrlsList = (json['file_urls'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['file_urls'] is String) {
        // If it's a JSON string, try to parse
        fileUrlsList = [json['file_urls'] as String];
      }
    }

    // Handle content field - backend may use 'content' or 'text'
    final contentValue =
        json['content'] ?? json['text'] ?? json['message'] ?? '';

    // Handle time_sent - backend uses time_sent column
    final timeSentValue =
        json['time_sent'] ??
        json['timeSent'] ??
        json['created_at'] ??
        json['createdAt'];

    final message = Message(
      id: json['id'] as int,
      projectId: json['project_id'] as int? ?? json['projectId'] as int? ?? 0,
      taskId: json['task_id'] as int? ?? json['taskId'] as int?,
      senderId: json['sender_id'] as int? ?? json['senderId'] as int? ?? 0,
      content: contentValue.toString(),
      fileUrls: fileUrlsList,
      timeSent: _dateTimeFromJson(timeSentValue),
      sender: senderObj,
    );

    return message;
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
    final difference = now.difference(timeSent);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy HH:mm').format(timeSent);
    } else if (difference.inDays > 0) {
      return DateFormat('EEE HH:mm').format(timeSent);
    } else if (difference.inHours > 0) {
      return DateFormat('HH:mm').format(timeSent);
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class MessageSender {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatar;

  MessageSender({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as int,
      firstName:
          json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName:
          json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      avatar: json['avatar'] as String? ?? json['profile_pic_url'] as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
