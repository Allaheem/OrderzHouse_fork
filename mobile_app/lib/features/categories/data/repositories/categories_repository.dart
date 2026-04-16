// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';

class CategoriesRepository {
  CategoriesRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// Fetch explore categories (public categories for projects)
  /// Endpoint: GET /category (same as web frontend)
  /// Response: { success: true, data: [...] }
  Future<ApiResponse<List<Category>>> fetchExploreCategories() async {
    try {
      final response = await _dio.get('/category');

      return _parseCategoriesResponse(response);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message: _extractErrorMessage(e.response?.data) ?? _getErrorMessage(e),
        error: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch categories',
      );
    }
  }

  /// Parse categories from response (handles both response formats)
  ApiResponse<List<Category>> _parseCategoriesResponse(Response response) {
    final raw = response.data;
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    // Handle response format: { success: true, data: [...] } (from /category)
    List<dynamic>? categoriesList;

    if (data['data'] != null && data['data'] is List) {
      categoriesList = data['data'] as List<dynamic>;
    } else if (data['categories'] != null && data['categories'] is List) {
      categoriesList = data['categories'] as List<dynamic>;
    } else if (response.data is List) {
      categoriesList = response.data as List<dynamic>;
    }

    if (categoriesList == null || categoriesList.isEmpty) {
      return const ApiResponse(
        success: true,
        data: [],
        message: 'No categories available',
      );
    }

    final categories = <Category>[];
    for (var i = 0; i < categoriesList.length; i++) {
      try {
        final json = categoriesList[i] as Map<String, dynamic>;
        final category = Category.fromJson(json);
        categories.add(category);
      } catch (_) {
        // Skip invalid categories but continue processing others
      }
    }

    return ApiResponse(
      success: true,
      data: categories,
      message: 'Categories fetched successfully',
    );
  }

  /// Fetch sub-categories by category ID
  /// Endpoint: GET /category/:categoryId/sub-categories
  Future<ApiResponse<List<Map<String, dynamic>>>> fetchSubCategories(
    int categoryId,
  ) async {
    try {
      final response = await _dio.get('/category/$categoryId/sub-categories');
      final data = response.data as Map<String, dynamic>;

      List<dynamic>? subCategoriesList;
      if (data['subCategories'] != null && data['subCategories'] is List) {
        subCategoriesList = data['subCategories'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        subCategoriesList = data['data'] as List<dynamic>;
      }

      final subCategories = (subCategoriesList ?? [])
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return ApiResponse(
        success: true,
        data: subCategories,
        message: 'Sub-categories fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to fetch sub-categories',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch sub-categories',
      );
    }
  }

  /// Fetch sub-sub-categories by sub-category ID
  /// Endpoint: GET /category/sub-category/:subCategoryId/sub-sub-categories
  Future<ApiResponse<List<Map<String, dynamic>>>> fetchSubSubCategories(
    int subCategoryId,
  ) async {
    try {
      final response = await _dio.get(
        '/category/sub-category/$subCategoryId/sub-sub-categories',
      );
      final data = response.data as Map<String, dynamic>;

      List<dynamic>? subSubCategoriesList;
      if (data['subSubCategories'] != null &&
          data['subSubCategories'] is List) {
        subSubCategoriesList = data['subSubCategories'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        subSubCategoriesList = data['data'] as List<dynamic>;
      }

      final subSubCategories = (subSubCategoriesList ?? [])
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return ApiResponse(
        success: true,
        data: subSubCategories,
        message: 'Sub-sub-categories fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to fetch sub-sub-categories',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch sub-sub-categories',
      );
    }
  }

  /// Fetch sub-sub-categories by category ID (all sub-sub-categories under a category)
  /// Endpoint: GET /category/:categoryId/sub-sub-categories
  Future<ApiResponse<List<Map<String, dynamic>>>>
  fetchSubSubCategoriesByCategoryId(int categoryId) async {
    try {
      final response = await _dio.get(
        '/category/$categoryId/sub-sub-categories',
      );
      final data = response.data as Map<String, dynamic>;

      List<dynamic>? subSubCategoriesList;
      if (data['subSubCategories'] != null &&
          data['subSubCategories'] is List) {
        subSubCategoriesList = data['subSubCategories'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        subSubCategoriesList = data['data'] as List<dynamic>;
      }

      final subSubCategories = (subSubCategoriesList ?? [])
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return ApiResponse(
        success: true,
        data: subSubCategories,
        message: 'Sub-sub-categories fetched successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: [],
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to fetch sub-sub-categories',
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch sub-sub-categories',
      );
    }
  }

  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Check your connection.';
      default:
        return 'Failed to fetch categories.';
    }
  }

  String? _extractErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
