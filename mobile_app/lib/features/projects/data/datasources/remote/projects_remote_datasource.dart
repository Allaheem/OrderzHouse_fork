// ??? ????????
import 'package:dio/dio.dart';
import '../../../../../core/models/api_response.dart';
import '../../../../../core/models/project.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/network/api_endpoints.dart';

/// Remote data source: Explore projects only. All Dio calls for explore live here.
class ProjectsRemoteDataSource {
  ProjectsRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetch explore projects. [userRoleId] from auth (2=client, 3=freelancer).
  Future<ApiResponse<List<Project>>> fetchExploreProjects({
    String? query,
    int? categoryId,
    int? subCategoryId,
    int? subSubCategoryId,
    int page = 1,
    int limit = 20,
    int? userRoleId,
    String sortBy = 'newest',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy.trim().isNotEmpty ? sortBy.trim() : 'newest',
      };
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }

      if (subSubCategoryId != null) {
        final path = ApiEndpoints.projectPublicSubSubcategoryId(
          subSubCategoryId,
        );
        return await _getAndParse(path, queryParams);
      }
      if (subCategoryId != null) {
        final path = ApiEndpoints.projectPublicSubcategoryId(subCategoryId);
        return await _getAndParse(path, queryParams);
      }
      if (categoryId != null) {
        return await _fetchByCategoryWithFallback(categoryId, queryParams);
      }
      return await _fetchAllCategoriesProjects(queryParams);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message: e.response?.data?['message'] as String? ?? _dioErrorMessage(e),
        error: e.response?.data as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch projects: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<Project>>> _getAndParse(
    String path,
    Map<String, dynamic> queryParams,
  ) async {
    final response = await _dio.get(path, queryParameters: queryParams);
    return _parseProjectsResponse(response);
  }

  Future<ApiResponse<List<Project>>> _fetchByCategoryWithFallback(
    int categoryId,
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final path = ApiEndpoints.projectCategoryId(categoryId);
      final response = await _dio.get(path, queryParameters: queryParams);
      return _parseProjectsResponse(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403 ||
          e.response?.statusCode == 404) {
        try {
          final path = ApiEndpoints.projectPublicCategoryId(categoryId);
          final response = await _dio.get(path, queryParameters: queryParams);
          return _parseProjectsResponse(response);
        } on DioException catch (e2) {
          return ApiResponse(
            success: false,
            data: [],
            message:
                e2.response?.data?['message'] as String? ??
                'Failed to fetch projects',
            error: e2.response?.data as Map<String, dynamic>?,
          );
        }
      }
      return ApiResponse(
        success: false,
        data: [],
        message: e.response?.data?['message'] as String? ?? _dioErrorMessage(e),
        error: e.response?.data as Map<String, dynamic>?,
      );
    }
  }

  Future<ApiResponse<List<Project>>> _fetchAllCategoriesProjects(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);
      final data = response.data as Map<String, dynamic>;
      final categories =
          data['data'] as List<dynamic>? ??
          data['categories'] as List<dynamic>? ??
          [];
      final categoryIds = <int>[];
      for (final c in categories) {
        try {
          final id = (c as Map<String, dynamic>)['id'] as int?;
          if (id != null) categoryIds.add(id);
        } catch (_) {}
      }
      if (categoryIds.isEmpty) {
        return const ApiResponse(
          success: true,
          data: [],
          message: 'No categories available',
        );
      }
      return await _fetchProjectsFromCategoryIds(categoryIds, queryParams);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            'Failed to fetch categories. Please try selecting a specific category.',
        error: e.response?.data as Map<String, dynamic>?,
      );
    } catch (e) {
      return const ApiResponse(
        success: false,
        data: [],
        message:
            'Failed to fetch projects. Please try selecting a specific category.',
      );
    }
  }

  Future<ApiResponse<List<Project>>> _fetchProjectsFromCategoryIds(
    List<int> categoryIds,
    Map<String, dynamic> queryParams,
  ) async {
    final allProjects = <Project>[];
    for (final categoryId in categoryIds) {
      try {
        final response = await _dio.get(
          ApiEndpoints.projectCategoryId(categoryId),
          queryParameters: queryParams,
        );
        final parsed = _parseProjectsResponse(response);
        if (parsed.success && parsed.data != null) {
          allProjects.addAll(parsed.data!);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 ||
            e.response?.statusCode == 403 ||
            e.response?.statusCode == 404) {
          try {
            final response = await _dio.get(
              ApiEndpoints.projectPublicCategoryId(categoryId),
              queryParameters: queryParams,
            );
            final parsed = _parseProjectsResponse(response);
            if (parsed.success && parsed.data != null) {
              allProjects.addAll(parsed.data!);
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
    final sortBy = queryParams['sortBy'] as String?;
    if (sortBy != null && sortBy.isNotEmpty) {
      switch (sortBy.toLowerCase()) {
        case 'newest':
          allProjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'price_low_to_high':
          allProjects.sort((a, b) {
            final aP = _sortPrice(a, low: true);
            final bP = _sortPrice(b, low: true);
            return aP.compareTo(bP);
          });
          break;
        case 'price_high_to_low':
          allProjects.sort((a, b) {
            final aP = _sortPrice(a, low: false);
            final bP = _sortPrice(b, low: false);
            return bP.compareTo(aP);
          });
          break;
      }
    }
    return ApiResponse(
      success: true,
      data: allProjects,
      message: 'Projects fetched successfully',
    );
  }

  double _sortPrice(Project p, {required bool low}) {
    if (p.projectType == 'fixed') return p.budget ?? (low ? 999999 : 0);
    if (p.projectType == 'hourly') return p.hourlyRate ?? (low ? 999999 : 0);
    return low ? (p.budgetMin ?? 999999) : (p.budgetMax ?? 0);
  }

  ApiResponse<List<Project>> _parseProjectsResponse(Response response) {
    final data = response.data as Map<String, dynamic>;
    List<dynamic>? list = data['projects'] as List<dynamic>?;
    list ??= data['data'] is List ? data['data'] as List<dynamic> : null;
    list ??= response.data is List ? response.data as List<dynamic> : null;
    if (list == null || list.isEmpty) {
      return const ApiResponse(
        success: true,
        data: [],
        message: 'No projects found',
      );
    }
    final projects = <Project>[];
    for (var i = 0; i < list.length; i++) {
      try {
        final raw = list[i] as Map<String, dynamic>;
        projects.add(Project.fromJson(_normalizeProjectJson(raw)));
      } catch (e) {
        if (AppConfig.isDevelopment) {
          print('⚠️ Failed to parse project at index $i: $e');
        }
      }
    }
    return ApiResponse(
      success: true,
      data: projects,
      message: 'Projects fetched successfully',
    );
  }

  Map<String, dynamic> _normalizeProjectJson(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);

    int? asInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final fallbackId =
        asInt(normalized['exposure_id']) ??
        asInt(normalized['tender_vault_project_id']) ??
        asInt(normalized['project_id']) ??
        asInt(normalized['id']);
    if (fallbackId != null) {
      normalized['id'] = fallbackId;
    }

    normalized['user_id'] = asInt(normalized['user_id']) ?? 0;
    normalized['project_type'] =
        (normalized['project_type'] as String?)?.trim().isNotEmpty == true
        ? normalized['project_type']
        : 'bidding';
    normalized['status'] =
        (normalized['status'] as String?)?.trim().isNotEmpty == true
        ? normalized['status']
        : 'open';
    normalized['created_at'] =
        (normalized['created_at'] as String?)?.trim().isNotEmpty == true
        ? normalized['created_at']
        : DateTime.now().toIso8601String();

    if ((normalized['cover_pic'] == null ||
            (normalized['cover_pic'] as String).trim().isEmpty) &&
        normalized['attachments'] is List &&
        (normalized['attachments'] as List).isNotEmpty) {
      final first = (normalized['attachments'] as List).first;
      if (first is Map<String, dynamic>) {
        final url = first['url'];
        if (url is String && url.trim().isNotEmpty) {
          normalized['cover_pic'] = url.trim();
        }
      }
    }

    if (normalized['duration_days'] == null &&
        normalized['duration'] != null &&
        normalized['duration_unit'] != null) {
      final duration = asInt(normalized['duration']);
      final unit = (normalized['duration_unit'] as String?)?.toLowerCase();
      if (duration != null) {
        if (unit == 'week' || unit == 'weeks') {
          normalized['duration_days'] = duration * 7;
        } else if (unit == 'day' || unit == 'days') {
          normalized['duration_days'] = duration;
        } else if (unit == 'hour' || unit == 'hours') {
          normalized['duration_hours'] = duration;
        }
      }
    }

    return normalized;
  }

  static String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Check your internet connection.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 403) {
          return 'Access denied. Please verify your account and subscribe.';
        }
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Check your connection.';
      default:
        return 'Failed to fetch projects.';
    }
  }
}
