// ??? ????????
import 'package:dio/dio.dart';
import '../storage/secure_store.dart';
import '../storage/app_prefs.dart';
import '../session/auth_api_binding.dart';
import '../session/auth_session_events.dart';
import 'token_refresh_coordinator.dart';
class AuthInterceptor extends Interceptor {
  /// Set on [Options.extra] for public routes (login, forgot password, etc.)
  /// so we never attach a stale session token to unauthenticated endpoints.
  static const String extraSkipAuth = 'skipAuth';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[extraSkipAuth] == true) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = await SecureStore.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Must be registered **before** [ErrorInterceptor]: Dio runs `onError` callbacks in
/// interceptor list order, so we refresh and retry before the session is cleared on 401.
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor(this._dio);

  final Dio _dio;

  static const String _extraRefreshAttempted = '_authRefreshRetried';

  static String? _authorizationHeader(RequestOptions ro) {
    final headers = ro.headers;
    final auth = headers['Authorization'] ?? headers['authorization'];
    if (auth == null) return null;
    if (auth is List) {
      return auth.isEmpty ? null : auth.first.toString();
    }
    return auth.toString();
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final ro = err.requestOptions;

    if (ro.extra[_extraRefreshAttempted] == true) {
      handler.next(err);
      return;
    }
    if (ro.extra[AuthInterceptor.extraSkipAuth] == true) {
      handler.next(err);
      return;
    }

    final path = ro.uri.path;
    if (path.contains('/users/refresh') ||
        path.endsWith('/users/login') ||
        path.contains('/users/verify-otp')) {
      handler.next(err);
      return;
    }

    final auth = _authorizationHeader(ro);
    if (auth == null || auth.isEmpty || !auth.startsWith('Bearer ')) {
      handler.next(err);
      return;
    }

    final code = err.response?.statusCode;
    if (code != 401 && code != 403) {
      handler.next(err);
      return;
    }

    String msg = '';
    final data = err.response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      msg = m == null ? '' : m.toString().toLowerCase();
    }

    final bool looksLikeTokenProblem = code == 401 ||
        (code == 403 &&
            (msg.contains('token') ||
                msg.contains('expired') ||
                msg.contains('invalid')));

    if (!looksLikeTokenProblem) {
      handler.next(err);
      return;
    }

    final refreshed = await TokenRefreshCoordinator.refresh(_dio);
    if (!refreshed) {
      handler.next(err);
      return;
    }

    final newToken = await SecureStore.readAccessToken();
    if (newToken == null || newToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      ro.headers['Authorization'] = 'Bearer $newToken';
      ro.extra[_extraRefreshAttempted] = true;
      final response = await _dio.fetch(ro);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  static const String _cachedAuthUserKey = 'cached_auth_user';

  static bool _shouldInvalidateSession(DioException err) {
    // Public/third-party requests (e.g. Cloudinary fallback) may 401 without JWT;
    // that must not clear our API session or the user gets sent to login.
    if (err.requestOptions.extra[AuthInterceptor.extraSkipAuth] == true) {
      return false;
    }
    final code = err.response?.statusCode;
    if (code == 401) return true;
    if (code != 403) return false;
    final data = err.response?.data;
    if (data is! Map) return false;
    if (data['code'] == 'TERMS_NOT_ACCEPTED') return false;
    final msg = (data['message'] ?? '').toString().toLowerCase();
    if (msg.contains('account has been deleted')) return true;
    return msg.contains('invalid') &&
        (msg.contains('token') || msg.contains('expired'));
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldInvalidateSession(err)) {
      await SecureStore.clearAll();
      await AuthApiBinding.clear();
      await AppPrefs.remove(_cachedAuthUserKey);
      authSessionInvalidated.add(null);
    }
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  static const _maxRetries = 1;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;
    if (_shouldRetry(err) && attempt < _maxRetries) {
      err.requestOptions.extra['_retryCount'] = attempt + 1;
      await Future.delayed(const Duration(seconds: 1));
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: err.requestOptions.connectTimeout,
            receiveTimeout: err.requestOptions.receiveTimeout,
            sendTimeout: err.requestOptions.sendTimeout,
            validateStatus: err.requestOptions.validateStatus,
          ),
        );
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        handler.next(err);
        return;
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
