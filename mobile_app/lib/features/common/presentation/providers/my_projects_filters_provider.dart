// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/project.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import 'explore_filters_provider.dart';

/// Search query for My Projects screen. Debounced in UI.
/// autoDispose: resets when leaving My Projects / on logout.
final myProjectsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Filter state for My Projects (same as Explore: sort, projectType, budget, duration).
/// autoDispose: resets when leaving My Projects.
final myProjectsFiltersProvider =
    StateNotifierProvider.autoDispose<
      ExploreFiltersNotifier,
      ExploreFilterState
    >((ref) => ExploreFiltersNotifier());

/// Selected status for My Projects chips (null = All).
/// Values: null (all), 'active', 'pending', 'completed', or exact status string.
final myProjectsStatusProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Whether project matches status filter (for both client and freelancer).
bool _matchesStatus(Project project, String? selectedStatus) {
  if (selectedStatus == null) return true;

  final projectStatus = project.status.toLowerCase();
  final selected = selectedStatus.toLowerCase();

  switch (selected) {
    case 'active':
      return [
        'in_progress',
        'active',
        'running',
        'started',
        'not_started',
        'pending_admin_approval',
      ].contains(projectStatus);
    case 'pending':
      return projectStatus == 'pending' ||
          projectStatus == 'pending_review' ||
          projectStatus == 'pending_approval';
    case 'completed':
      return projectStatus == 'completed' ||
          projectStatus == 'done' ||
          projectStatus == 'finished';
    default:
      return project.status == selectedStatus;
  }
}

/// Filtered My Projects: applies search, status, and filter sheet (sort, type, budget, duration).
/// Data from myProjectsProvider; all filtering is client-side.
/// Clears when auth changes (userId/role) via authEpochProvider.
final filteredMyProjectsProvider =
    Provider.autoDispose<AsyncValue<List<Project>>>((ref) {
      ref.watch(authEpochProvider);
      final projectsAsync = ref.watch(myProjectsProvider);
      final searchQuery = ref.watch(myProjectsSearchQueryProvider).trim();
      final statusFilter = ref.watch(myProjectsStatusProvider);
      final filters = ref.watch(myProjectsFiltersProvider);

      return projectsAsync.when(
        data: (list) {
          var filtered = list.where((p) {
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              final matchTitle = p.title.toLowerCase().contains(q);
              final matchDesc = p.description.toLowerCase().contains(q);
              if (!matchTitle && !matchDesc) return false;
            }
            if (!_matchesStatus(p, statusFilter)) return false;
            return true;
          }).toList();
          filtered = applyExploreFilters(filtered, filters);
          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, st) => AsyncValue.error(err, st),
      );
    });
