// ??? ????????
import '../storage/app_prefs.dart';

/// Tracks last visited route for restore after app reopen.
/// Persists to shared_preferences; keeps an in-memory cache for sync read in redirect.
class RouteTracker {
  RouteTracker._();

  static const _authPaths = [
    '/login',
    '/register',
    '/otp',
    '/splash',
    '/verify-email',
    '/verify-otp',
    '/forgot-password',
    '/reset-otp',
    '/reset-password',
    '/onboarding',
    '/accept-terms',
  ];

  static String? _lastRouteCache;

  /// Call from main() after AppPrefs.init() so redirect can read last route synchronously.
  static Future<void> init() async {
    _lastRouteCache = await AppPrefs.getLastRoute();
  }

  /// Synchronous get for use in go_router redirect.
  static String? getLastRoute() => _lastRouteCache;

  /// Persist route if not an auth page. Call on each non-redirect navigation.
  static Future<void> saveLastRoute(String path) async {
    final normalized = path.startsWith('/') ? path : '/$path';
    if (_authPaths.any(
      (p) => normalized == p || normalized.startsWith('$p/'),
    )) {
      return;
    }
    _lastRouteCache = normalized;
    await AppPrefs.setLastRoute(normalized);
  }

  /// Clear last route (e.g. on logout). Optional; can keep for post-login redirect.
  static Future<void> clearLastRoute() async {
    _lastRouteCache = null;
    await AppPrefs.clearLastRoute();
  }

  static bool isAuthRoute(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return _authPaths.any(
      (p) => normalized == p || normalized.startsWith('$p/'),
    );
  }
}
