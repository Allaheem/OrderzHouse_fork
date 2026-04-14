// ??? ????????
import 'package:dio/dio.dart';

import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../blocked_user_entry.dart';

class ModerationRepository {
  final Dio _dio = DioClient.instance;

  static const String _blocksPath = '/moderation/blocks';
  static const String _reportsPath = '/moderation/reports';

  Future<ApiResponse<List<BlockedUserEntry>>> fetchBlocks() async {
    try {
      final response = await _dio.get(_blocksPath);
      final data = response.data as Map<String, dynamic>;
      final raw = data['blocks'] as List<dynamic>? ?? [];
      final list = raw
          .map((e) => BlockedUserEntry.fromApiJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse(success: true, data: list, message: 'OK');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: const [],
        message:
            e.response?.data?['message'] as String? ?? 'Failed to load blocks',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: const [],
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> blockUser({
    required int projectId,
    required int blockedUserId,
  }) async {
    try {
      await _dio.post(
        _blocksPath,
        data: {'projectId': projectId, 'blockedUserId': blockedUserId},
      );
      return const ApiResponse(success: true, data: null, message: 'OK');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ?? 'Failed to block user',
      );
    } catch (e) {
      return ApiResponse(success: false, data: null, message: e.toString());
    }
  }

  Future<ApiResponse<void>> unblockUser(int blockedUserId) async {
    try {
      await _dio.delete('$_blocksPath/$blockedUserId');
      return const ApiResponse(success: true, data: null, message: 'OK');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ?? 'Failed to unblock',
      );
    } catch (e) {
      return ApiResponse(success: false, data: null, message: e.toString());
    }
  }

  Future<ApiResponse<void>> submitReport({
    required int projectId,
    required int reportedUserId,
    int? messageId,
    String? messageExcerpt,
    String? note,
  }) async {
    try {
      await _dio.post(
        _reportsPath,
        data: {
          'projectId': projectId,
          'reportedUserId': reportedUserId,
          if (messageId != null) 'messageId': messageId,
          if (messageExcerpt != null && messageExcerpt.isNotEmpty)
            'messageExcerpt': messageExcerpt,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return const ApiResponse(success: true, data: null, message: 'OK');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ?? 'Failed to submit report',
      );
    } catch (e) {
      return ApiResponse(success: false, data: null, message: e.toString());
    }
  }
}
