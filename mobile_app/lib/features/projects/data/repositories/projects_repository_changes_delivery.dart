import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_debug_log.dart';
import '../models/change_request_model.dart';

/// Result of [GET /projects/:id/deliveries] (list + server-derived review flag).
class ProjectDeliveriesPayload {
  const ProjectDeliveriesPayload({
    required this.deliveries,
    required this.awaitingClientReview,
  });
  final List<Map<String, dynamic>> deliveries;
  final bool awaitingClientReview;
}

/// Change requests, deliver, client review flows.
class ProjectsRepositoryChangesDelivery {
  ProjectsRepositoryChangesDelivery(this._dio, this._api);

  final Dio _dio;
  final ApiClient _api;

  Future<ApiResponse<void>> requestProjectChanges({
    required int projectId,
    required String message,
  }) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[POST] => PATH: /projects/$projectId/request-changes');
        appDebugLog('📦 BODY: { "message": "$message" }');
      }

      final response = await _dio.post(
        '/projects/$projectId/request-changes',
        data: {'message': message},
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/$projectId/request-changes',
        );
      }

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'Change request sent successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to send change request',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/$projectId/request-changes',
        );
        appDebugLog('Response: ${e.response?.data}');
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to send change request',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/$projectId/request-changes');
      }

      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to send change request',
      );
    }
  }

  Future<ApiResponse<List<ChangeRequest>>> getProjectChangeRequests(
    int projectId,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[GET] => PATH: /projects/$projectId/change-requests');
      }

      final response = await _api.getChangeRequests(projectId);

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/$projectId/change-requests',
        );
        appDebugLog('📦 Response data: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;

      List<dynamic>? itemsList;
      if (data['requests'] != null && data['requests'] is List) {
        itemsList = data['requests'] as List<dynamic>;
      } else if (data['items'] != null && data['items'] is List) {
        itemsList = data['items'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        itemsList = data['data'] as List<dynamic>;
      } else if (response.data is List) {
        itemsList = response.data as List<dynamic>;
      }

      if (itemsList == null || itemsList.isEmpty) {
        if (AppConfig.isDevelopment) {
          appDebugLog('ℹ️ No change requests found (empty or null list)');
        }
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No change requests found',
        );
      }

      final changeRequests = itemsList
          .map((json) => ChangeRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      if (AppConfig.isDevelopment) {
        appDebugLog('✅ Parsed ${changeRequests.length} change requests');
      }

      return ApiResponse(
        success: true,
        data: changeRequests,
        message: 'Change requests fetched successfully',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/$projectId/change-requests',
        );
        appDebugLog('Response: ${e.response?.data}');
      }

      if (e.response?.statusCode == 404) {
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No change requests found',
        );
      }

      return ApiResponse(
        success: false,
        data: [],
        message:
            e.response?.data?['message'] as String? ??
            'Failed to fetch change requests',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/$projectId/change-requests');
      }

      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch change requests',
      );
    }
  }

  Future<void> markChangeRequestsRead(
    int projectId, {
    List<int>? ids,
    DateTime? lastSeenAt,
  }) async {
    try {
      await _api.markChangeRequestsRead(projectId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 501) {
        return;
      }
      if (AppConfig.isDevelopment) {
        appDebugLog('⚠️ markChangeRequestsRead: ${e.message}');
      }
    } catch (_) {}
  }

  Future<ApiResponse<void>> deliverProject(
    int projectId,
    List<String> filePaths,
  ) async {
    try {
      if (AppConfig.isDevelopment) {
        appDebugLog('📡 REQUEST[POST] => PATH: /projects/$projectId/deliver');
      }

      final formData = FormData();
      for (var i = 0; i < filePaths.length; i++) {
        final path = filePaths[i];
        final filename = path.replaceAll(r'\', '/').split('/').last;
        final nameWithExt = filename.isNotEmpty ? filename : 'file_$i';
        formData.files.add(
          MapEntry(
            'project_files',
            await MultipartFile.fromFile(path, filename: nameWithExt),
          ),
        );
      }

      final response = await _dio.post(
        '/projects/$projectId/deliver',
        data: formData,
      );

      if (AppConfig.isDevelopment) {
        appDebugLog(
          '✅ RESPONSE[${response.statusCode}] => PATH: /projects/$projectId/deliver',
        );
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'Project delivered successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to deliver project',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/$projectId/deliver',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to deliver project',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/$projectId/deliver');
      }

      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to deliver project',
      );
    }
  }

  Future<ApiResponse<ProjectDeliveriesPayload>> getProjectDeliveries(
    int projectId,
  ) async {
    try {
      final response = await _dio.get('/projects/$projectId/deliveries');

      final data = response.data as Map<String, dynamic>;
      final items = data['deliveries'] ?? data['data'] ?? [];
      final rawList = (items is List) ? items : [];
      final list = rawList.map((e) => e as Map<String, dynamic>).toList();
      final awaiting = data['awaiting_client_review'] == true;

      return ApiResponse(
        success: true,
        data: ProjectDeliveriesPayload(
          deliveries: list,
          awaitingClientReview: awaiting,
        ),
        message: 'Deliveries fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: const ProjectDeliveriesPayload(
          deliveries: <Map<String, dynamic>>[],
          awaitingClientReview: false,
        ),
        message:
            e.response?.data?['message'] as String? ??
            'Failed to fetch deliveries',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: const ProjectDeliveriesPayload(
          deliveries: <Map<String, dynamic>>[],
          awaitingClientReview: false,
        ),
        message: 'Failed to fetch deliveries',
      );
    }
  }

  Future<ApiResponse<void>> approveDelivery(int projectId) async {
    try {
      final response = await _dio.put(
        '/projects/$projectId/approve',
        data: {'action': 'approve'},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'Delivery approved successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to approve delivery',
      );
    } on DioException catch (e) {
      if (AppConfig.isDevelopment) {
        appDebugLog(
          '❌ ERROR[${e.response?.statusCode ?? 'null'}] => PATH: /projects/$projectId/approve',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to approve delivery',
      );
    } catch (_) {
      if (AppConfig.isDevelopment) {
        appDebugLog('❌ UNEXPECTED ERROR => /projects/$projectId/approve');
      }

      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to approve delivery',
      );
    }
  }

  Future<ApiResponse<void>> requestChanges(int projectId, String message) async {
    try {
      final response = await _dio.post(
        '/projects/$projectId/request-changes',
        data: {'message': message},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return const ApiResponse(
          success: true,
          data: null,
          message: 'Change request sent successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        message: data['message'] as String? ?? 'Failed to send change request',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message:
            e.response?.data?['message'] as String? ??
            'Failed to send change request',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Failed to send change request',
      );
    }
  }
}
