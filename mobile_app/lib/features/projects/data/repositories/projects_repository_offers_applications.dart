import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/utils/app_debug_log.dart';
import 'projects_repository_helpers.dart';

/// Offers, applications, and authenticated file download.
class ProjectsRepositoryOffersApplications {
  ProjectsRepositoryOffersApplications(this._dio);

  final Dio _dio;

  Future<ApiResponse<List<Map<String, dynamic>>>> getProjectOffers(
    int projectId,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[GET] => PATH: /offers/project/$projectId/offers');
      }

      final response = await _dio.get('/offers/project/$projectId/offers');

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /offers/project/$projectId/offers',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['offers'] ?? data['data'] ?? [];
      final list = (items is List) ? items : [];

      return ApiResponse(
        success: true,
        data: list.map((e) => e as Map<String, dynamic>).toList(),
        message: 'Offers fetched successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /offers/project/$projectId/offers',
        );
      }

      return ApiResponse(
        success: false,
        data: [],
        message:
            e.response?.data?['message'] as String? ?? 'Failed to fetch offers',
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /offers/project/$projectId/offers: $e');
      }

      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch offers: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>?>> approveRejectOffer(
    int offerId,
    String action,
  ) async {
    final body = {'offerId': offerId, 'action': action};
    final paths = ['/offers/approve-reject', '/offers/offers/approve-reject'];
    for (final path in paths) {
      try {
        if (AppConfig.isDevelopment) {
          appDebugLog('📡 REQUEST[POST] => PATH: $path');
        }

        final response = await _dio.post(path, data: body);

        if (AppConfig.isDevelopment) {
          appDebugLog('✅ RESPONSE[${response.statusCode}] => PATH: $path');
        }

        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          final payload = <String, dynamic>{};
          if (data['pendingAdminApproval'] == true) {
            payload['pendingAdminApproval'] = true;
          }
          final pid = data['projectId'];
          if (pid != null) {
            payload['projectId'] = pid is int
                ? pid
                : int.tryParse(pid.toString());
          }
          return ApiResponse(
            success: true,
            data: payload.isEmpty ? null : payload,
            message:
                data['message'] as String? ??
                'Offer action completed successfully',
          );
        }

        return ApiResponse(
          success: false,
          data: null,
          message: data['message'] as String? ?? 'Failed to process offer',
        );
      } on DioException catch (e) {
        final is404 = e.response?.statusCode == 404;
        if (AppConfig.isDevelopment) {
          appDebugLog('❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: $path');
        }
        if (is404 && path == paths.first) continue;
        return ApiResponse(
          success: false,
          data: null,
          message:
              e.response?.data?['message'] as String? ??
              'Failed to process offer',
        );
      }
    }

    return const ApiResponse(
      success: false,
      data: null,
      message: 'Failed to process offer',
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getProjectApplications(
    int projectId,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '📡 REQUEST[GET] => PATH: /projects/project/$projectId/applications',
        );
      }

      final response = await _dio.get(
        '/projects/project/$projectId/applications',
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/project/$projectId/applications',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['applications'] ?? data['data'] ?? [];
      final list = (items is List) ? items : [];

      return ApiResponse(
        success: true,
        data: list.map((e) => e as Map<String, dynamic>).toList(),
        message: 'Applications fetched successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/project/$projectId/applications',
        );
      }

      return ApiResponse(
        success: false,
        data: [],
        message:
            e.response?.data?['message'] as String? ??
            'Failed to fetch applications',
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ UNEXPECTED ERROR => /projects/project/$projectId/applications: $e',
        );
      }

      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch applications: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> acceptRejectApplication(
    int assignmentId,
    int projectId,
    String action,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[POST] => PATH: /projects/applications/decision');
      }

      final response = await _dio.post(
        '/projects/applications/decision',
        data: {
          'assignmentId': assignmentId,
          'projectId': projectId,
          'action': action,
        },
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/applications/decision',
        );
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'Application action completed successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to process application',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/applications/decision',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to process application',
      );
    } catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/applications/decision: $e');
      }

      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to process application: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> downloadFile({
    required String url,
    required String savePath,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        options: Options(
          headers: const <String, String>{'Accept': '*/*'},
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
        onReceiveProgress: onReceiveProgress,
      );
      return const ApiResponse(success: true);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            projectsRepositoryExtractErrorMessage(e.response?.data) ??
            'Failed to download file',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to download file: ${e.toString()}',
      );
    }
  }
}
