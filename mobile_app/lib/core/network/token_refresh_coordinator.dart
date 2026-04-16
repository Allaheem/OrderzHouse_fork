// ??? ????????
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../storage/secure_store.dart';
import 'dio_interceptors.dart';

/// Single in-flight refresh so parallel 401s do not stampede `/users/refresh`
/// (rotation / storage races) and all waiters share the same result.
class TokenRefreshCoordinator {
  TokenRefreshCoordinator._();

  static Future<bool>? _inFlight;

  /// Returns `true` if new access (and optional refresh) tokens were stored.
  static Future<bool> refresh(Dio dio) {
    if (_inFlight != null) return _inFlight!;
    _inFlight = _performRefresh(dio).whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  static Future<bool> _performRefresh(Dio dio) async {
    final refresh = await SecureStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/users/refresh',
        data: {'refreshToken': refresh},
        options: Options(
          extra: {AuthInterceptor.extraSkipAuth: true},
        ),
      );
      final newToken = res.data?['token'] as String?;
      if (newToken == null || newToken.isEmpty) return false;
      await SecureStore.saveAccessToken(newToken);
      final newRt = res.data?['refreshToken'] as String?;
      if (newRt != null && newRt.isNotEmpty) {
        await SecureStore.saveRefreshToken(newRt);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Client-side JWT `exp` hint only — server still validates the refresh token.
  static bool accessTokenExpiresWithin(String? jwt, Duration margin) {
    if (jwt == null || jwt.trim().isEmpty) return true;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final map = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      final exp = map['exp'];
      if (exp is! num) return true;
      final expMs = (exp.toDouble() * 1000).round();
      final deadline =
          DateTime.now().millisecondsSinceEpoch + margin.inMilliseconds;
      return expMs <= deadline;
    } catch (_) {
      return true;
    }
  }

  static Future<void> refreshIfExpiringSoon(
    Dio dio, {
    Duration margin = const Duration(minutes: 5),
  }) async {
    final access = await SecureStore.readAccessToken();
    if (!accessTokenExpiresWithin(access, margin)) return;
    final refresh = await SecureStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return;
    await TokenRefreshCoordinator.refresh(dio);
  }
}
