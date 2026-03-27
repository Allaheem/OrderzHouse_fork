// ??? ????????
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_store.dart';
import '../config/app_config.dart';

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
  bool get _shouldLog => kDebugMode || AppConfig.isDevelopment;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldLog) {
      // Never log full tokens or sensitive data
      final safeHeaders = Map<String, dynamic>.from(options.headers);
      String? tokenPrefix;
      if (safeHeaders.containsKey('Authorization')) {
        final authHeader = safeHeaders['Authorization'] as String?;
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          final token = authHeader.substring(7);
          tokenPrefix = token.length > 10 ? token.substring(0, 10) : token;
          safeHeaders['Authorization'] = 'Bearer $tokenPrefix...';
        } else {
          safeHeaders['Authorization'] = 'Bearer ***';
        }
      }
      // ignore: avoid_print
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      // ignore: avoid_print
      print('REQUEST[${options.method}] => Final URL: ${options.uri}');
      // ignore: avoid_print
      print('REQUEST[${options.method}] => Headers: $safeHeaders');
      if (tokenPrefix != null) {
        // ignore: avoid_print
        print('REQUEST[${options.method}] => Token prefix: $tokenPrefix');
      }
      if (options.data != null) {
        // ignore: avoid_print
        print('REQUEST[${options.method}] => Data: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldLog) {
      // ignore: avoid_print
      print(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      // ignore: avoid_print
      print(
        'RESPONSE[${response.statusCode}] => URI: ${response.requestOptions.uri}',
      );
      if (response.data != null) {
        // ignore: avoid_print
        print('RESPONSE[${response.statusCode}] => Data: ${response.data}');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldLog) {
      // ignore: avoid_print
      print(
        'ERROR[${err.response?.statusCode ?? 'null'}] => PATH: ${err.requestOptions.path}',
      );
      // ignore: avoid_print
      print('ERROR => Type: ${err.type}');
      // ignore: avoid_print
      print('ERROR => URI: ${err.requestOptions.uri}');
      // ignore: avoid_print
      print('ERROR => Message: ${err.message}');
      if (err.error != null) {
        // ignore: avoid_print
        print('ERROR => Error: ${err.error}');
      }
      if (err.response != null) {
        // ignore: avoid_print
        print('ERROR => Status Code: ${err.response?.statusCode}');
        // ignore: avoid_print
        print('ERROR => Response Data: ${err.response?.data}');
      }
      // ignore: avoid_print
      print('ERROR => Stack Trace: ${err.stackTrace}');
    }
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401: clear stored auth so user is sent to login
    if (err.response?.statusCode == 401) {
      SecureStore.clearAll();
    }
    // 401/403: backend message is in response.data.message and is used by callers
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        final dio = Dio();
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
