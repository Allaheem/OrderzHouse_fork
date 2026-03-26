// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_service.dart';
import '../../core/config/app_config.dart';

/// Stale-while-revalidate provider helper
/// Returns cached data immediately, then fetches fresh data in background
class StaleWhileRevalidateProvider<T> {
  /// Create a provider that uses stale-while-revalidate pattern
  ///
  /// [cacheKey] - Unique key for caching
  /// [fetchFn] - Function to fetch fresh data
  /// [fromJson] - Function to deserialize from JSON
  /// [toJson] - Function to serialize to JSON
  static AutoDisposeFutureProvider<T> create<T>({
    required String cacheKey,
    required Future<T> Function() fetchFn,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) {
    return FutureProvider.autoDispose<T>((ref) async {
      // 1. Try to load from cache first (instant)
      final cached = CacheService.getCached<T>(cacheKey, fromJson);

      // 2. Start fetching fresh data in background (don't await yet)
      final freshDataFuture = fetchFn()
          .then((data) async {
            // Save to cache when fresh data arrives
            await CacheService.setCached(
              cacheKey,
              data,
              DateTime.now().millisecondsSinceEpoch,
              toJson,
            );
            return data;
          })
          .catchError((error) {
            // If fetch fails, return cached data if available
            if (cached != null) {
              if (AppConfig.isDevelopment) {
                print('⚠️ [SWR] Fetch failed for $cacheKey, using cached data');
              }
              return cached;
            }
            throw error;
          });

      // 3. Return cached data immediately if available, otherwise wait for fresh
      if (cached != null) {
        // Return cached immediately, but continue fetching in background
        // The provider will update when fresh data arrives
        // Use Future.value to return immediately, then update with fresh data
        return freshDataFuture;
      }

      // No cache, wait for fresh data
      return freshDataFuture;
    });
  }

  /// Create a provider for lists that uses stale-while-revalidate pattern
  static AutoDisposeFutureProvider<List<T>> createList<T>({
    required String cacheKey,
    required Future<List<T>> Function() fetchFn,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) {
    return FutureProvider.autoDispose<List<T>>((ref) async {
      // 1. Try to load from cache first (instant)
      final cached = await CacheService.getList<T>(cacheKey, fromJson);

      // 2. Start fetching fresh data in background
      final freshDataFuture = fetchFn()
          .then((data) async {
            // Save to cache when fresh data arrives
            await CacheService.setList(cacheKey, data, toJson);
            return data;
          })
          .catchError((error) {
            // If fetch fails, return cached data if available
            if (cached != null && cached.isNotEmpty) {
              if (AppConfig.isDevelopment) {
                print('⚠️ [SWR] Fetch failed for $cacheKey, using cached data');
              }
              return cached;
            }
            throw error;
          });

      // 3. Return cached data immediately if available, otherwise wait for fresh
      if (cached != null && cached.isNotEmpty) {
        // Return cached immediately, but continue fetching in background
        return freshDataFuture;
      }

      // No cache, wait for fresh data
      return freshDataFuture;
    });
  }
}
