// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_service.dart';
import '../../core/config/app_config.dart';

/// State for cached data with loading/error states
class CachedDataState<T> {
  final T? data;
  final bool isLoading;
  final bool isRefreshing;
  final Object? error;
  final StackTrace? stackTrace;

  const CachedDataState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.stackTrace,
  });

  CachedDataState<T> copyWith({
    T? data,
    bool? isLoading,
    bool? isRefreshing,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return CachedDataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

/// StateNotifier for cached data with stale-while-revalidate pattern
class CachedDataNotifier<T> extends StateNotifier<CachedDataState<T>> {
  final String cacheKey;
  final Future<T> Function() fetchFn;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  CachedDataNotifier({
    required this.cacheKey,
    required this.fetchFn,
    required this.fromJson,
    required this.toJson,
  }) : super(CachedDataState<T>(isLoading: true)) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Try to load from cache first (instant)
      final cached = CacheService.getCached<T>(cacheKey, fromJson);

      if (cached != null) {
        // Show cached data immediately
        state = CachedDataState<T>(
          data: cached,
          isLoading: false,
          isRefreshing: true, // Start refreshing in background
        );
      } else {
        // No cache, show loading
        state = state.copyWith(isLoading: true);
      }

      // 2. Fetch fresh data in background
      try {
        final freshData = await fetchFn();

        // Save to cache
        await CacheService.setCached(
          cacheKey,
          freshData,
          DateTime.now().millisecondsSinceEpoch,
          toJson,
        );

        // Update with fresh data
        state = CachedDataState<T>(
          data: freshData,
          isLoading: false,
          isRefreshing: false,
        );
      } catch (error, stackTrace) {
        // If fetch fails, keep cached data if available
        if (cached != null) {
          if (AppConfig.isDevelopment) {
            print(
              '⚠️ [CachedData] Fetch failed for $cacheKey, keeping cached data',
            );
          }
          state = CachedDataState<T>(
            data: cached,
            isLoading: false,
            isRefreshing: false,
            error: error,
            stackTrace: stackTrace,
          );
        } else {
          // No cache, show error
          state = CachedDataState<T>(
            isLoading: false,
            isRefreshing: false,
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (error, stackTrace) {
      state = CachedDataState<T>(
        isLoading: false,
        isRefreshing: false,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Refresh data manually
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    try {
      final freshData = await fetchFn();
      await CacheService.setCached(
        cacheKey,
        freshData,
        DateTime.now().millisecondsSinceEpoch,
        toJson,
      );
      state = CachedDataState<T>(
        data: freshData,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (error, stackTrace) {
      // Keep existing data on refresh error
      state = state.copyWith(
        isRefreshing: false,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// StateNotifier for cached list data
class CachedListDataNotifier<T>
    extends StateNotifier<CachedDataState<List<T>>> {
  final String cacheKey;
  final Future<List<T>> Function() fetchFn;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  CachedListDataNotifier({
    required this.cacheKey,
    required this.fetchFn,
    required this.fromJson,
    required this.toJson,
  }) : super(CachedDataState<List<T>>(isLoading: true)) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Try to load from cache first (instant)
      final cached = await CacheService.getList<T>(cacheKey, fromJson);

      if (cached != null && cached.isNotEmpty) {
        // Show cached data immediately
        state = CachedDataState<List<T>>(
          data: cached,
          isLoading: false,
          isRefreshing: true, // Start refreshing in background
        );
      } else {
        // No cache, show loading
        state = state.copyWith(isLoading: true);
      }

      // 2. Fetch fresh data in background
      try {
        final freshData = await fetchFn();

        // Save to cache
        await CacheService.setList(cacheKey, freshData, toJson);

        // Update with fresh data
        state = CachedDataState<List<T>>(
          data: freshData,
          isLoading: false,
          isRefreshing: false,
        );
      } catch (error, stackTrace) {
        // If fetch fails, keep cached data if available
        if (cached != null && cached.isNotEmpty) {
          if (AppConfig.isDevelopment) {
            print(
              '⚠️ [CachedListData] Fetch failed for $cacheKey, keeping cached data',
            );
          }
          state = CachedDataState<List<T>>(
            data: cached,
            isLoading: false,
            isRefreshing: false,
            error: error,
            stackTrace: stackTrace,
          );
        } else {
          // No cache, show error
          state = CachedDataState<List<T>>(
            isLoading: false,
            isRefreshing: false,
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (error, stackTrace) {
      state = CachedDataState<List<T>>(
        isLoading: false,
        isRefreshing: false,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Refresh data manually
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    try {
      final freshData = await fetchFn();
      await CacheService.setList(cacheKey, freshData, toJson);
      state = CachedDataState<List<T>>(
        data: freshData,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (error, stackTrace) {
      // Keep existing data on refresh error
      state = state.copyWith(
        isRefreshing: false,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
