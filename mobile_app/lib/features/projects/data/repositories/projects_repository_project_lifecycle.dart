import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/utils/app_debug_log.dart';

/// Create project, upload files, success payload, offline payment.
class ProjectsRepositoryProjectLifecycle {
  ProjectsRepositoryProjectLifecycle(this._dio);

  final Dio _dio;

  Future<ApiResponse<Map<String, dynamic>>> createProject({
    required int categoryId,
    int? subCategoryId,
    required int subSubCategoryId,
    required String title,
    required String description,
    required String projectType,
    double? budget,
    double? hourlyRate,
    double? budgetMin,
    double? budgetMax,
    required String durationType,
    int? durationDays,
    int? durationHours,
    List<String>? preferredSkills,
    String? coverPicPath,
  }) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[POST] => PATH: /projects');
      }

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('category_id', categoryId.toString()),
        if (subCategoryId != null)
          MapEntry('sub_category_id', subCategoryId.toString()),
        MapEntry('sub_sub_category_id', subSubCategoryId.toString()),
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('project_type', projectType),
        if (budget != null) MapEntry('budget', budget.toString()),
        if (hourlyRate != null) MapEntry('hourly_rate', hourlyRate.toString()),
        if (budgetMin != null) MapEntry('budget_min', budgetMin.toString()),
        if (budgetMax != null) MapEntry('budget_max', budgetMax.toString()),
        MapEntry('duration_type', durationType),
        if (durationDays != null)
          MapEntry('duration_days', durationDays.toString()),
        if (durationHours != null)
          MapEntry('duration_hours', durationHours.toString()),
      ]);

      if (preferredSkills != null && preferredSkills.isNotEmpty) {
        for (final skill in preferredSkills) {
          formData.fields.add(MapEntry('preferred_skills[]', skill));
        }
      }

      if (coverPicPath != null) {
        formData.files.add(
          MapEntry(
            'cover_pic',
            await MultipartFile.fromFile(coverPicPath, filename: 'cover.jpg'),
          ),
        );
      }

      final response = await _dio.post('/projects', data: formData);

      if (AppConfig.isDevelopment) {
        appDebugLog('✅ RESPONSE[${response.statusCode}] => PATH: /projects');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return ApiResponse(
          success: true,
          data: data['project'] as Map<String, dynamic>? ?? data,
          message: 'Project created successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: {},
        message: data['message'] as String? ?? 'Failed to create project',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects',
        );
        appDebugLog('❌ ERROR => Message: ${e.message}');
      }

      return ApiResponse(
        success: false,
        data: {},
        message:
            e.response?.data?['message'] as String? ??
            'Failed to create project',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects: $e');
      }

      return ApiResponse(
        success: false,
        data: {},
        message: 'Failed to create project',
      );
    }
  }

  Future<ApiResponse<void>> uploadProjectFiles(
    int projectId,
    List<String> filePaths,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[POST] => PATH: /projects/$projectId/files');
      }

      final formData = FormData();
      for (var i = 0; i < filePaths.length; i++) {
        formData.files.add(
          MapEntry(
            'attachments',
            await MultipartFile.fromFile(filePaths[i], filename: 'file_$i'),
          ),
        );
      }

      final response = await _dio.post(
        '/projects/$projectId/files',
        data: formData,
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/$projectId/files',
        );
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'Files uploaded successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to upload files',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/$projectId/files',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ?? 'Failed to upload files',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/$projectId/files: $e');
      }

      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to upload files',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getProjectSuccess(int projectId) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[GET] => PATH: /projects/success/$projectId');
      }

      final response = await _dio.get(
        '/projects/success/$projectId',
        options: Options(receiveTimeout: const Duration(seconds: 25)),
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/success/$projectId',
        );
      }

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['project'] != null) {
        return ApiResponse(
          success: true,
          data: data['project'] as Map<String, dynamic>,
          message: null,
        );
      }

      return ApiResponse(
        success: false,
        data: {},
        message: data['message'] as String? ?? 'Failed to load project',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/success/$projectId',
        );
      }
      final body = e.response?.data;
      final msg = body is Map ? (body['message'] as String?) : null;
      return ApiResponse(
        success: false,
        data: {},
        message: msg ?? 'Failed to load project',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/success/$projectId: $e');
      }
      return ApiResponse(
        success: false,
        data: {},
        message: 'Failed to load project',
      );
    }
  }

  Future<ApiResponse<void>> setProjectOfflinePayment(
    int projectId,
    String method,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '📡 REQUEST[POST] => PATH: /projects/$projectId/offline-payment',
        );
      }
      final response = await _dio.post(
        '/projects/$projectId/offline-payment',
        data: {'method': method},
      );
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/$projectId/offline-payment',
        );
      }
      final data = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] != false) {
        return ApiResponse(
          success: true,
          data: null,
          message: data['message'] as String?,
        );
      }
      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to set offline payment',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode}] => PATH: /projects/$projectId/offline-payment',
        );
      }
      final body = e.response?.data;
      final msg = body is Map ? (body['message'] as String?) : null;
      return ApiResponse(
        success: false,
        data: null,
        message: msg ?? 'Failed to set offline payment',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ UNEXPECTED ERROR => /projects/$projectId/offline-payment: $e',
        );
      }
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to set offline payment',
      );
    }
  }
}
