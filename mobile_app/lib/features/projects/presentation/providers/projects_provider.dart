// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/project.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/remote/projects_remote_datasource.dart';
import '../../data/repositories/projects_repository.dart';
import '../../domain/usecases/get_explore_projects.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';

final projectsRemoteDataSourceProvider = Provider<ProjectsRemoteDataSource>((
  ref,
) {
  return ProjectsRemoteDataSource(ref.watch(dioProvider));
});

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(
    currentUserRoleReader: () => ref.read(authStateProvider).user?.roleId,
    exploreRemote: ref.watch(projectsRemoteDataSourceProvider),
  );
});

/// Use case for explore projects. Presentation (Explore notifier) uses this only.
final getExploreProjectsProvider = Provider<GetExploreProjects>((ref) {
  return GetExploreProjects(ref.watch(projectsRepositoryProvider));
});

/// Provider for fetching a single project by ID
/// Tries to find it in myProjects first, then shows error if not found
final projectByIdProvider = FutureProvider.autoDispose.family<Project?, int>((
  ref,
  projectId,
) async {
  final repository = ref.read(projectsRepositoryProvider);

  // Try to find in my projects
  final myProjectsResponse = await repository.getMyProjectsRaw(limit: 1000);
  if (myProjectsResponse.success && myProjectsResponse.data != null) {
    final projectData = myProjectsResponse.data!.firstWhere(
      (p) => (p['id'] as int?) == projectId,
      orElse: () => {},
    );

    if (projectData.isNotEmpty) {
      try {
        return Project.fromJson(projectData);
      } catch (e) {
        if (AppConfig.isDevelopment) {
          print('❌ Failed to parse project $projectId: $e');
        }
        return null;
      }
    }
  }

  // Not found in my projects - return null (will show error)
  return null;
});

// In-memory cache for my projects (instant access)
final _myProjectsCacheProvider = StateProvider<List<Project>?>((ref) => null);

// Changed from autoDispose to prevent refetch on rebuilds
// Now watches userId to automatically refetch when user changes
// Uses stale-while-revalidate: returns cached data immediately, then fetches fresh
final myProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.read(projectsRepositoryProvider);
  ref.watch(authEpochProvider);
  final userId = ref.watch(authStateProvider.select((state) => state.userId));

  void updateInMemoryCache(List<Project> projects) {
    Future.microtask(() {
      ref.read(_myProjectsCacheProvider.notifier).state = projects;
    });
  }

  if (userId == null) {
    return [];
  }

  // 1. Check in-memory cache first (instant)
  final cached = ref.read(_myProjectsCacheProvider);
  if (cached != null) {
    // Return cached immediately, but continue fetching fresh data
    // The provider will update when fresh data arrives
  }

  // 2. Try to load from persistent cache
  final cacheKey = 'my_projects_$userId';
  final persistentCache = await CacheService.getList<Project>(
    cacheKey,
    (json) => Project.fromJson(json),
  );

  if (persistentCache != null && persistentCache.isNotEmpty) {
    // Update in-memory cache
    updateInMemoryCache(persistentCache);
    // Return cached immediately, continue fetching fresh
  }

  // 3. Fetch fresh data (this will update the provider when done)
  try {
    final response = await repository.getMyProjects();

    if (response.success && response.data != null) {
      // Save to both caches
      updateInMemoryCache(response.data!);
      await CacheService.setList(
        cacheKey,
        response.data!,
        (project) => project.toJson(),
      );
      return response.data!;
    }

    // If fetch fails, return cached data if available
    if (persistentCache != null && persistentCache.isNotEmpty) {
      return persistentCache;
    }
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    throw Exception(response.message ?? 'Failed to fetch projects');
  } catch (e) {
    // Return cached data on error if available
    if (persistentCache != null && persistentCache.isNotEmpty) {
      return persistentCache;
    }
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

// In-memory cache for explore projects (used by notifier)
final _exploreProjectsCacheProvider =
    StateProvider.autoDispose<Map<String, List<Project>>>((ref) => {});

/// Non-blocking refresh error message (e.g. network failed but cache shown). UI shows snackbar and clears.
final exploreRefreshErrorProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Cache-first explore state. Emits cached data immediately (if any), then fetches and updates. TTL 10 min.
class ExploreProjectsNotifier
    extends AutoDisposeNotifier<AsyncValue<List<Project>>> {
  @override
  AsyncValue<List<Project>> build() {
    ref.listen(selectedExploreCategoryIdProvider, (_, _) => _load());
    ref.listen(exploreSortByProvider, (_, _) => _load());
    ref.listen(searchQueryProvider, (_, _) => _load());
    ref.listen(authStateProvider.select((s) => s.userId), (_, _) => _load());
    Future.microtask(() => _load());
    return const AsyncValue.loading();
  }

  /// Call from UI (e.g. RefreshIndicator) to reload. Resets refresh error and runs cache-then-network.
  Future<void> load() => _load();

  Future<void> _load() async {
    final userId = ref.read(authStateProvider.select((state) => state.userId));
    final authState = ref.read(authStateProvider);
    final userRoleId = authState.user?.roleId;

    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    final selectedCategoryId = ref.read(selectedExploreCategoryIdProvider);
    final String sortBy = ref.read(exploreSortByProvider);
    final searchQuery = ref.read(searchQueryProvider);
    final query = searchQuery.trim().isNotEmpty ? searchQuery.trim() : null;
    final cacheKey =
        'explore_${userId}_${selectedCategoryId ?? 'all'}_${sortBy}_${query ?? 'noquery'}';

    state = const AsyncValue.loading();
    ref.read(exploreRefreshErrorProvider.notifier).state = null;

    // 1. Sync read from Hive (instant)
    List<Project>? cached = ref.read(_exploreProjectsCacheProvider)[cacheKey];
    if (cached == null || cached.isEmpty) {
      cached = CacheService.getListSync(
        cacheKey,
        (json) => Project.fromJson(json),
      );
      if (cached != null && cached.isNotEmpty) {
        ref
            .read(_exploreProjectsCacheProvider.notifier)
            .update((s) => {...s, cacheKey: cached!});
      }
    }
    if (cached != null && cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }

    // 2. Fetch fresh via use case (no Dio in presentation)
    try {
      final getExplore = ref.read(getExploreProjectsProvider);
      final response = await getExplore.call(
        query: query,
        categoryId: selectedCategoryId,
        subCategoryId: null,
        subSubCategoryId: null,
        page: 1,
        limit: 20,
        userRoleId: userRoleId,
        sortBy: sortBy,
      );

      if (response.success && response.data != null) {
        ref
            .read(_exploreProjectsCacheProvider.notifier)
            .update((s) => {...s, cacheKey: response.data!});
        await CacheService.setList(cacheKey, response.data!, (p) => p.toJson());
        state = AsyncValue.data(response.data!);
        return;
      }

      if (cached != null && cached.isNotEmpty) {
        ref.read(exploreRefreshErrorProvider.notifier).state =
            response.message ?? 'Could not refresh';
        return;
      }
      state = AsyncValue.error(
        Exception(response.message ?? 'Failed to load'),
        StackTrace.current,
      );
    } catch (e, st) {
      if (cached != null && cached.isNotEmpty) {
        ref.read(exploreRefreshErrorProvider.notifier).state = e.toString();
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }
}

final exploreProjectsStateProvider =
    NotifierProvider.autoDispose<
      ExploreProjectsNotifier,
      AsyncValue<List<Project>>
    >(ExploreProjectsNotifier.new);

/// Last successful explore projects list (for overlay loading). Updated when state has data.
final exploreProjectsLastDataProvider = Provider.autoDispose<List<Project>?>((
  ref,
) {
  return ref.watch(exploreProjectsStateProvider).valueOrNull;
});

/// Explore projects as Future (for compatibility). Completes with current or next data.
final exploreProjectsProvider = FutureProvider.autoDispose<List<Project>>((
  ref,
) async {
  final notifier = ref.read(exploreProjectsStateProvider.notifier);
  final current = ref.read(exploreProjectsStateProvider);
  if (current.hasValue) return current.value!;
  if (current.hasError) throw current.error!;
  await notifier.load();
  final next = ref.read(exploreProjectsStateProvider);
  return next.valueOrNull ?? [];
});

class ExploreProjectsParams {
  final String? query;
  final int? categoryId;
  final int? subCategoryId;
  final int? subSubCategoryId;
  final int page;
  final int limit;

  ExploreProjectsParams({
    this.query,
    this.categoryId,
    this.subCategoryId,
    this.subSubCategoryId,
    this.page = 1,
    this.limit = 20,
  });

  ExploreProjectsParams copyWith({
    String? query,
    int? categoryId,
    int? subCategoryId,
    int? subSubCategoryId,
    int? page,
    int? limit,
  }) {
    return ExploreProjectsParams(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subSubCategoryId: subSubCategoryId ?? this.subSubCategoryId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExploreProjectsParams &&
        other.query == query &&
        other.categoryId == categoryId &&
        other.subCategoryId == subCategoryId &&
        other.subSubCategoryId == subSubCategoryId &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      categoryId,
      subCategoryId,
      subSubCategoryId,
      page,
      limit,
    );
  }
}

/// Provider for latest projects (dashboard) - uses explore endpoint with no category filter
final latestProjectsProvider = FutureProvider.autoDispose<List<Project>>((
  ref,
) async {
  final repository = ref.read(projectsRepositoryProvider);
  ref.watch(authEpochProvider);
  final userId = ref.watch(authStateProvider.select((state) => state.userId));
  final authState = ref.read(authStateProvider);
  final userRoleId = authState.user?.roleId;

  if (userId == null) {
    return [];
  }

  // Fetch all projects (no category filter) with limit 2, sorted by created_at DESC
  final response = await repository.fetchExploreProjects(
    query: null,
    categoryId: null, // No category = fetch all
    subCategoryId: null,
    subSubCategoryId: null,
    page: 1,
    limit: 2, // Only need 2 for dashboard
    userRoleId: userRoleId,
  );

  if (response.success && response.data != null) {
    // Take first 2 (already sorted by created_at DESC from backend)
    return response.data!.take(2).toList();
  }

  throw Exception(response.message ?? 'Failed to fetch latest projects');
});

/// Profile stats computed from user's projects
/// Automatically refreshes when user changes (account switching)
class ProfileStats {
  final int total;
  final int active;
  final int completed;

  const ProfileStats({
    required this.total,
    required this.active,
    required this.completed,
  });

  factory ProfileStats.empty() =>
      const ProfileStats(total: 0, active: 0, completed: 0);
}

/// Workspace tab enum
enum WorkspaceTab { actionRequired, active }

/// Provider for selected workspace tab
/// Default = ACTIVE so first render shows active projects.
/// autoDispose: when Home is left (no listeners), state resets so next open starts as Active.
final workspaceTabProvider = StateProvider.autoDispose<WorkspaceTab>(
  (ref) => WorkspaceTab.active,
);

/// Fetches client projects with status=in_progress for the "In progress" workspace tab.
/// Uses my projects endpoint with status filter. Cached (no autoDispose) for instant switch-back.
final workspaceInProgressProjectsProvider = FutureProvider<List<Project>>((
  ref,
) async {
  final repository = ref.read(projectsRepositoryProvider);
  ref.watch(authEpochProvider);
  final userId = ref.watch(authStateProvider.select((s) => s.userId));
  if (userId == null) return [];

  final response = await repository.getMyProjects(
    statusKey: 'in_progress',
    page: 1,
    limit: 5,
  );
  if (response.success && response.data != null) {
    final list = response.data!;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
  throw Exception(response.message ?? 'Failed to fetch in-progress projects');
});

/// Provider for workspace items (max 5) - data source depends on tab and role
/// - ACTIVE: filter from myProjects (active, in_progress, in-progress, not_started)
/// - IN_PROGRESS (actionRequired): Client = API status=in_progress; Freelancer = filter from myProjects
final workspaceItemsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final selectedTab = ref.watch(workspaceTabProvider);
  final authState = ref.read(authStateProvider);
  final isFreelancer = authState.user?.roleId == 3;

  // Client + In progress tab: fetch from API with status=in_progress
  if (selectedTab == WorkspaceTab.actionRequired && !isFreelancer) {
    return ref
        .watch(workspaceInProgressProjectsProvider)
        .when(
          data: (projects) => AsyncValue.data(projects),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        );
  }

  // Active tab OR Freelancer + In progress: filter from myProjects
  final projectsAsync = ref.watch(myProjectsProvider);
  return projectsAsync.when(
    data: (projects) {
      List<Project> filtered;
      if (selectedTab == WorkspaceTab.actionRequired) {
        // Freelancer In progress: pending delivery, revision requested, etc.
        filtered = projects.where((p) {
          final status = p.status.toLowerCase();
          return status == 'pending_review' ||
              status == 'revision_requested' ||
              status == 'pending_delivery' ||
              status == 'changes_requested';
        }).toList();
      } else {
        // Active tab
        filtered = projects.where((p) {
          final status = p.status.toLowerCase();
          return status == 'active' ||
              status == 'in_progress' ||
              status == 'in-progress' ||
              status == 'not_started';
        }).toList();
      }
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return AsyncValue.data(filtered.take(5).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for profile stats - derived from myProjectsProvider
/// Watches userId so it auto-refreshes on account switch
final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  final projectsAsync = ref.watch(myProjectsProvider);

  return projectsAsync.when(
    data: (projects) {
      // Count by status
      int activeCount = 0;
      int completedCount = 0;

      for (final project in projects) {
        final status = project.status.toLowerCase();

        // Active statuses
        if (status == 'active' ||
            status == 'in_progress' ||
            status == 'in-progress' ||
            status == 'pending' ||
            status == 'not_started' ||
            status == 'pending_review') {
          activeCount++;
        }
        // Completed status
        else if (status == 'completed' ||
            status == 'done' ||
            status == 'finished') {
          completedCount++;
        }
      }

      return AsyncValue.data(
        ProfileStats(
          total: projects.length,
          active: activeCount,
          completed: completedCount,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
