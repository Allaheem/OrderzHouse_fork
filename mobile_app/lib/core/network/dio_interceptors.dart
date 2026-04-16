// ??? ????????
import 'package:dio/dio.dart';
import '../storage/secure_store.dart';
import '../storage/app_prefs.dart';
import '../session/auth_api_binding.dart';
import '../session/auth_session_events.dart';
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
