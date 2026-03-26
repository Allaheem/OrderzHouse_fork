// ??? ????????
import '../../../../core/models/api_response.dart';
import '../../../../core/models/project.dart';

/// Domain contract for projects. Data layer implements this.
/// Presentation and use cases depend only on this interface.
abstract class IProjectsRepository {
  /// Fetch explore/browse projects (category, search, sort).
  Future<ApiResponse<List<Project>>> fetchExploreProjects({
    String? query,
    int? categoryId,
    int? subCategoryId,
    int? subSubCategoryId,
    int page = 1,
    int limit = 20,
    int? userRoleId,
    String sortBy = 'newest',
  });
}
