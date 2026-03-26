// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/category.dart';
import '../../../../core/cache/cache_service.dart';
import '../../data/repositories/categories_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository();
});

// In-memory cache for categories (instant access)
final _categoriesCacheProvider = StateProvider.autoDispose<List<Category>?>(
  (ref) => null,
);

final exploreCategoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final repository = ref.read(categoriesRepositoryProvider);
  ref.watch(authEpochProvider);
  const cacheKey = 'explore_categories';

  // 1. Check in-memory cache first (instant)
  final cached = ref.read(_categoriesCacheProvider);
  if (cached != null && cached.isNotEmpty) {
    // Return cached immediately, continue fetching fresh
  }

  // 2. Try persistent cache
  final persistentCache = await CacheService.getList<Category>(
    cacheKey,
    (json) => Category.fromJson(json),
  );

  if (persistentCache != null && persistentCache.isNotEmpty) {
    // Update in-memory cache
    ref.read(_categoriesCacheProvider.notifier).state = persistentCache;
    // Return cached immediately, continue fetching fresh
  }

  // 3. Fetch fresh data
  try {
    final response = await repository.fetchExploreCategories();

    if (response.success && response.data != null) {
      // Save to both caches
      ref.read(_categoriesCacheProvider.notifier).state = response.data!;
      await CacheService.setList(
        cacheKey,
        response.data!,
        (category) => category.toJson(),
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

    throw Exception(response.message ?? 'Failed to fetch categories');
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

/// Selected category ID for explore projects
/// null means "All" (no category filter)
final selectedExploreCategoryIdProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);

/// Shared state for selected category when navigating from Dashboard/Home
/// This provider persists across navigation and is used to set the initial filter
final exploreSelectedCategoryIdProvider = StateProvider<int?>((ref) => null);

/// Sort option for explore projects
/// Values: 'newest', 'price_low_to_high', 'price_high_to_low', 'deadline_soonest'
/// Default: 'newest'
/// IMPORTANT: Must be String (non-nullable) to match all usages
final exploreSortByProvider = StateProvider.autoDispose<String>((ref) {
  return 'newest';
});
