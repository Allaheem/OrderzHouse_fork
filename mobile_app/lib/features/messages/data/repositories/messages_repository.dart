// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/message_model.dart';

class MessagesRepository {
  final Dio _dio = DioClient.instance;

  /// Get messages for a project
  /// Endpoint: GET /chat/project/:projectId/messages
  /// Response: { success: true, messages: [...] }
  Future<ApiResponse<List<Message>>> getProjectMessages(int projectId) async {
    try {
      final response = await _dio.get('/chat/project/$projectId/messages');

      final data = response.data as Map<String, dynamic>;

      // Backend returns { success: true, messages: [...] }
      List<dynamic>? messagesList;
      if (data['messages'] != null && data['messages'] is List) {
        messagesList = data['messages'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        messagesList = data['data'] as List<dynamic>;
      }

      if (messagesList == null || messagesList.isEmpty) {
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No messages found',
        );
      }

      final messages = <Message>[];
      for (var i = 0; i < messagesList.length; i++) {
        try {
          final json = messagesList[i] as Map<String, dynamic>;
          final message = Message.fromJson(json);
          messages.add(message);
        } catch (_) {
          // Skip malformed message payloads without leaking internals to logs/UI.
        }
      }
      return ApiResponse(
        success: true,
        data: messages,
        message: 'Messages fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            e.response?.data?['message'] as String? ??
            'Failed to fetch messages',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch messages',
      );
    }
  }

  /// Send a message to a project
  /// Endpoint: POST /chat/messages
  /// Body: { project_id: int, content: string, file_urls?: string[] }
  /// Response: { success: true, message: {...} }
  Future<ApiResponse<Message>> sendProjectMessage({
    required int projectId,
    required String content,
    List<String>? fileUrls,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/messages',
        data: {
          'project_id': projectId,
          'content': content,
          if (fileUrls != null && fileUrls.isNotEmpty) 'file_urls': fileUrls,
        },
      );

      final data = response.data as Map<String, dynamic>;

      Message? message;
      if (data['message'] != null) {
        message = Message.fromJson(data['message'] as Map<String, dynamic>);
      } else if (data['data'] != null) {
        message = Message.fromJson(data['data'] as Map<String, dynamic>);
      }

      if (message == null) {
        return const ApiResponse(
          success: false,
          data: null,
          message: 'Invalid response format',
        );
      }

      return ApiResponse(
        success: true,
        data: message,
        message: 'Message sent successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ?? 'Failed to send message',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to send message',
      );
    }
  }

  /// Get unread message count for current user in this project.
  /// Endpoint: GET /chat/project/:projectId/unread
  /// Response: { success: true, count: number, hasUnread?: boolean }
  Future<ApiResponse<int>> getUnreadCount(int projectId) async {
    try {
      final response = await _dio.get('/chat/project/$projectId/unread');
      final data = response.data as Map<String, dynamic>;
      final count = (data['count'] as num?)?.toInt() ?? 0;
      return ApiResponse(success: true, data: count, message: 'OK');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const ApiResponse(success: true, data: 0, message: 'OK');
      }
      return ApiResponse(
        success: false,
        data: 0,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to get unread count',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: 0,
        message: 'Failed to get unread count',
      );
    }
  }

  /// Mark project messages as read for current user.
  /// Endpoint: POST /chat/project/:projectId/read
  Future<ApiResponse<void>> markProjectMessagesAsRead(int projectId) async {
    try {
      await _dio.post('/chat/project/$projectId/read');
      return const ApiResponse(success: true, data: null, message: 'OK');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const ApiResponse(success: true, data: null, message: 'OK');
      }
      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ?? 'Failed to mark as read',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to mark as read',
      );
    }
  }
}
