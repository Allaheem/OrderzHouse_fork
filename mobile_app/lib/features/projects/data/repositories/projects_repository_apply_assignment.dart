import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/utils/app_debug_log.dart';

/// Apply + assignment checks (freelancer ↔ project).
class ProjectsRepositoryApplyAssignment {
  ProjectsRepositoryApplyAssignment(this._dio);

  final Dio _dio;

  Future<ApiResponse<void>> applyForProject({
    required int projectId,
    String? message,
  }) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[POST] => PATH: /projects/$projectId/apply');
        appDebugLog(
          '📡 REQUEST[POST] => Body: ${message != null ? {'message': message} : {}}',
        );
      }

      final response = await _dio.post(
        '/projects/$projectId/apply',
        data: message != null ? {'message': message} : {},
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/$projectId/apply',
        );
        appDebugLog('✅ RESPONSE[${response.statusCode}] => Data: ${response.data}');
      }

      return ApiResponse(
        success: true,
        message:
            response.data['message'] as String? ??
            'Application submitted successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/$projectId/apply',
        );
        appDebugLog('❌ ERROR => Type: ${e.type}');
        appDebugLog('❌ ERROR => Final URL: ${e.requestOptions.uri}');
        appDebugLog('❌ ERROR => Message: ${e.message}');
        if (e.response != null) {
          appDebugLog('❌ ERROR => Status Code: ${e.response?.statusCode}');
          appDebugLog('❌ ERROR => Response Data: ${e.response?.data}');
        }
      }

      final errorMessage = e.response?.data?['message'] as String?;
      final statusCode = e.response?.statusCode;

      final isSubscriptionError =
          statusCode == 403 ||
          statusCode == 402 ||
          (errorMessage?.toLowerCase().contains('subscription') ?? false) ||
          (errorMessage?.toLowerCase().contains('subscribe') ?? false) ||
          (errorMessage?.toLowerCase().contains('plan') ?? false);

      return ApiResponse(
        success: false,
        message: errorMessage ?? 'Failed to apply to project',
        error: {
          'statusCode': statusCode,
          'isSubscriptionError': isSubscriptionError,
          ...?e.response?.data as Map<String, dynamic>?,
        },
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/$projectId/apply: $e');
      }

      return ApiResponse(
        success: false,
        message: 'Failed to apply to project: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>?>> getMyAssignment(int projectId) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[GET] => PATH: /assignments/$projectId/my-assignment');
      }

      final response = await _dio.get(
        '/assignments/$projectId/my-assignment',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /assignments/$projectId/my-assignment',
        );
      }

      final code = response.statusCode;
      if (code == 404) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'No assignment found',
        );
      }
      if (code != null && code >= 400) {
        final body = response.data;
        final msg = body is Map<String, dynamic>
            ? body['message'] as String?
            : null;
        return ApiResponse(
          success: false,
          data: null,
          message: msg ?? 'Failed to fetch assignment',
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'No assignment found',
        );
      }
      final assignment = data['assignment'] as Map<String, dynamic>?;

      return ApiResponse(
        success: true,
        data: assignment,
        message: 'Assignment fetched successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /assignments/$projectId/my-assignment',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to fetch assignment',
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ UNEXPECTED ERROR => /assignments/$projectId/my-assignment: $e',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to fetch assignment: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<bool>> checkIfAssigned(int projectId) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[GET] => PATH: /assignments/$projectId/check');
      }

      final response = await _dio.get('/assignments/$projectId/check');

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /assignments/$projectId/check',
        );
        appDebugLog('✅ RESPONSE[${response.statusCode}] => Data: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final isAssigned = data['is_assigned'] as bool? ?? false;

      return ApiResponse(
        success: true,
        data: isAssigned,
        message: 'Check completed',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /assignments/$projectId/check',
        );
        appDebugLog('❌ ERROR => Response Data: ${e.response?.data}');
      }

      return ApiResponse(
        success: true,
        data: false,
        message: e.response?.data?['message'] as String?,
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /assignments/$projectId/check: $e');
      }

      return const ApiResponse(
        success: true,
        data: false,
        message: 'Failed to check assignment',
      );
    }
  }
}
