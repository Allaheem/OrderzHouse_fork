// ??? ????????
import 'project.dart';
import 'category.dart';

class SearchResult {
  final List<Project> projects;
  final List<Category> categories;

  SearchResult({required this.projects, required this.categories});

  factory SearchResult.empty() {
    return SearchResult(projects: [], categories: []);
  }

  bool get isEmpty => projects.isEmpty && categories.isEmpty;
}
