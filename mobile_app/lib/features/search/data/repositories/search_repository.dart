// ??? ????????
import 'package:dio/dio.dart';
import '../../../../core/models/search_result.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/models/project.dart';
import '../../../../core/models/category.dart';

class SearchRepository {
  final Dio _dio = DioClient.instance;

  /// Search for projects and categories
  /// Endpoint: GET /search?q=<query>
  /// Response: { success: true, projects: [...], categories: [...] }
  Future<ApiResponse<SearchResult>> search(String query) async {
    try {
      final response = await _dio.get('/search', queryParameters: {'q': query});

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // Parse projects
        List<Project> projects = [];
        if (data['projects'] != null && data['projects'] is List) {
          final projectsList = data['projects'] as List<dynamic>;
          projects = projectsList
              .map((item) {
                try {
                  return Project.fromJson(item as Map<String, dynamic>);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Project>()
              .toList();
        }

        // Parse categories
        List<Category> categories = [];
        if (data['categories'] != null && data['categories'] is List) {
          final categoriesList = data['categories'] as List<dynamic>;
          categories = categoriesList
              .map((item) {
                try {
                  return Category.fromJson(item as Map<String, dynamic>);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Category>()
              .toList();
        }

        return ApiResponse(
          success: true,
          data: SearchResult(projects: projects, categories: categories),
          message: 'Search completed successfully',
        );
      }

      return ApiResponse(
        success: false,
        data: SearchResult.empty(),
        message: data['message'] as String? ?? 'Search failed',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        data: SearchResult.empty(),
        message: e.response?.data?['message'] as String? ?? 'Failed to search',
        error: e.response?.data as Map<String, dynamic>?,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        data: SearchResult.empty(),
        message: 'Failed to search',
      );
    }
  }
}
