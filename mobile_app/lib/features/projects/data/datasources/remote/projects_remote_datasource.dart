// ??? ????????
import 'package:dio/dio.dart';
import '../../../../../core/models/api_response.dart';
import '../../../../../core/models/project.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../repositories/projects_repository_helpers.dart';

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
        message:
            e.response?.data?['message'] as String? ??
            projectsRepositoryDioErrorMessage(e),
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
        message:
            e.response?.data?['message'] as String? ??
            projectsRepositoryDioErrorMessage(e),
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
    return projectsRepositoryParseProjectsListResponse(response);
  }
}
