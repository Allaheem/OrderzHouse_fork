// ??? ????????
import '../../../../core/models/api_response.dart';
import '../../../../core/models/project.dart';
import '../repositories/projects_repository.dart';

/// Use case: fetch explore/browse projects. Presentation calls this only.
class GetExploreProjects {
  GetExploreProjects(this._repository);

  final IProjectsRepository _repository;

  Future<ApiResponse<List<Project>>> call({
    String? query,
    int? categoryId,
    int? subCategoryId,
    int? subSubCategoryId,
    int page = 1,
    int limit = 20,
    int? userRoleId,
    String sortBy = 'newest',
  }) {
    return _repository.fetchExploreProjects(
      query: query,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      subSubCategoryId: subSubCategoryId,
      page: page,
      limit: limit,
      userRoleId: userRoleId,
      sortBy: sortBy,
    );
  }
}
