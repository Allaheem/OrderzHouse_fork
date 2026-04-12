import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/signup_payload.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/routing/route_tracker.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../../../core/session/auth_api_binding.dart';
import '../../../../core/session/auth_session_events.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// In-memory pending signup payload (set after OTP requested, cleared after verify-and-register or logout).
final pendingSignupPayloadProvider = StateProvider<SignupPayload?>(
  (ref) => null,
);

/// Incremented on login/logout so user-scoped providers can refresh without being invalidated from AuthNotifier.
/// Prevents CircularDependencyError: do NOT call ref.invalidate() on providers that depend on auth from inside AuthNotifier.
final authEpochProvider = StateProvider<int>((ref) => 0);

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
  final sub = authSessionInvalidated.stream.listen((_) async {
    await notifier.onRemoteSessionInvalidated();
  });
  ref.onDispose(sub.cancel);
  return notifier;
});

typedef CacheClearer = Future<void> Function();
typedef LastRouteClearer = Future<void> Function();
typedef AccessTokenReader = Future<String?> Function();
typedef CachedUserReader = Future<User?> Function();
typedef CachedUserWriter = Future<void> Function(User user);
typedef CachedUserClearer = Future<void> Function();

const String _cachedAuthUserKey = 'cached_auth_user';

Future<User?> _readCachedUserFromPrefs() async {
  final raw = await AppPrefs.getString(_cachedAuthUserKey);
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return User.fromJson(decoded);
    }
  } catch (_) {}
  return null;
}

Future<void> _writeCachedUserToPrefs(User user) async {
  await AppPrefs.setString(_cachedAuthUserKey, jsonEncode(user.toJson()));
}

Future<void> _clearCachedUserFromPrefs() async {
  await AppPrefs.remove(_cachedAuthUserKey);
}

class AuthState {
  final User? user;
  final bool isLoading;

  /// True while restoring session on app startup; router should show splash and not redirect to login.
  final bool isChecking;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isChecking = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  String? get userRole => user?.role;
  int? get userId => user?.id;
}

class AuthNotifier extends StateNotifier<AuthState> {
  /// Render cold starts can exceed 5s; avoid leaving [isChecking] stuck forever.
  static const Duration _sessionBootstrapTimeout = Duration(seconds: 25);

  AuthNotifier(
    this._repository,
    this._ref, {
    CacheClearer? clearCache,
    LastRouteClearer? clearLastRoute,
    AccessTokenReader? readAccessToken,
    CachedUserReader? readCachedUser,
    CachedUserWriter? writeCachedUser,
    CachedUserClearer? clearCachedUser,
  }) : _clearCache = clearCache ?? CacheService.clearAll,
       _clearLastRoute = clearLastRoute ?? RouteTracker.clearLastRoute,
       _readAccessToken = readAccessToken ?? SecureStore.readAccessToken,
       _readCachedUser = readCachedUser ?? _readCachedUserFromPrefs,
       _writeCachedUser = writeCachedUser ?? _writeCachedUserToPrefs,
       _clearCachedUser = clearCachedUser ?? _clearCachedUserFromPrefs,
       super(const AuthState(isChecking: true)) {
    restoreSession();
  }

  final AuthRepository _repository;
  final Ref _ref;
  final CacheClearer _clearCache;
  final LastRouteClearer _clearLastRoute;
  final AccessTokenReader _readAccessToken;
  final CachedUserReader _readCachedUser;
  final CachedUserWriter _writeCachedUser;
  final CachedUserClearer _clearCachedUser;

  /// Restore session from secure storage on app startup.
  /// Sets isChecking false and either authenticated (with user) or unauthenticated.
  Future<void> restoreSession() async {
    try {
      final token = await _readAccessToken();
      if (token == null) {
        state = const AuthState();
        return;
      }
      if (!await AuthApiBinding.matchesCurrentApi()) {
        await SecureStore.clearAll();
        await AuthApiBinding.clear();
        await _clearCachedUser();
        state = const AuthState();
        return;
      }
      final response = await _repository.getUserData().timeout(
        _sessionBootstrapTimeout,
        onTimeout: () => const ApiResponse<User>(
          success: false,
          message: 'Session restore timeout',
        ),
      );
      if (response.success && response.data != null) {
        state = AuthState(user: response.data);
        await _writeCachedUser(response.data!);
        await AuthApiBinding.recordCurrentApiForSession();
        return;
      }
      final cachedUser = await _readCachedUser();
      if (cachedUser != null) {
        state = AuthState(user: cachedUser);
        return;
      }
      state = const AuthState();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('restoreSession error: $e');
        debugPrint('$st');
      }
      try {
        final cachedUser = await _readCachedUser();
        state = cachedUser != null
            ? AuthState(user: cachedUser)
            : const AuthState();
      } catch (_) {
        state = const AuthState();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(isLoading: true);
    final response = await _repository.login(email: email, password: password);
    if (response.success && response.data != null) {
      state = AuthState(user: response.data);
      await _writeCachedUser(response.data!);
      _ref.read(authEpochProvider.notifier).state++;
      return true;
    }
    state = AuthState(error: response.message);
    return false;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = const AuthState(isLoading: true);
    final response = await _repository.verifyOtp(email: email, otp: otp);
    if (response.success && response.data != null) {
      state = AuthState(user: response.data);
      await _writeCachedUser(response.data!);
      _ref.read(authEpochProvider.notifier).state++;
      return true;
    }
    state = AuthState(error: response.message);
    return false;
  }

  /// Step A: Request signup OTP only. Does NOT create user. Caller should store payload and navigate to verify-email.
  Future<bool> startSignup(SignupPayload payload) async {
    state = const AuthState(isLoading: true);
    final response = await _repository.requestSignupOtp(payload.email);
    state = AuthState(error: response.message);
    return response.success;
  }

  /// Step B: Verify OTP and create user. Uses pending payload from pendingSignupPayloadProvider. Saves token and sets user on success.
  Future<bool> verifyOtpAndCompleteSignup(String code) async {
    final payload = _ref.read(pendingSignupPayloadProvider);
    if (payload == null) {
      state = const AuthState(
        error: 'Session expired. Please start signup again.',
      );
      return false;
    }
    state = const AuthState(isLoading: true);
    final response = await _repository.verifyAndRegister(
      payload: payload,
      otp: code,
    );
    if (response.success && response.data != null) {
      _ref.read(pendingSignupPayloadProvider.notifier).state = null;
      state = AuthState(user: response.data);
      await _writeCachedUser(response.data!);
      _ref.read(authEpochProvider.notifier).state++;
      return true;
    }
    state = AuthState(error: response.message);
    return false;
  }

  /// Resend OTP for signup (e.g. from verify-email screen). Only needs email.
  Future<bool> resendSignupOtp(String email) async {
    final response = await _repository.requestSignupOtp(email);
    if (!response.success) {
      state = AuthState(error: response.message);
    }
    return response.success;
  }

  Future<bool> register({
    required int roleId,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String country,
    required String username,
    List<int>? categoryIds,
    String? referralCode,
  }) async {
    state = const AuthState(isLoading: true);
    final response = await _repository.register(
      roleId: roleId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      country: country,
      username: username,
      categoryIds: categoryIds,
      referralCode: referralCode,
    );
    state = AuthState(error: response.message);
    return response.success;
  }

  Future<bool> verifyEmail(String email, String otp) async {
    state = const AuthState(isLoading: true);
    final response = await _repository.verifyEmail(email: email, otp: otp);
    state = AuthState(error: response.message);
    return response.success;
  }

  Future<void> logout() async {
    await _repository.logout();
    await AuthApiBinding.clear();
    await _clearCache();
    await _clearLastRoute();
    await _clearCachedUser();
    _ref.read(pendingSignupPayloadProvider.notifier).state = null;
    _ref.read(authEpochProvider.notifier).state++;
    state = const AuthState();
  }

  /// After [ErrorInterceptor] clears tokens (invalid/expired JWT), sync Riverpod + routing.
  Future<void> onRemoteSessionInvalidated() async {
    if (!state.isAuthenticated && await _readAccessToken() == null) {
      return;
    }
    await logout();
  }

  Future<void> refreshUser() async {
    final response = await _repository.getUserData();
    if (response.success && response.data != null) {
      state = AuthState(user: response.data);
      await _writeCachedUser(response.data!);
    }
  }

  Future<bool> acceptTerms() async {
    final response = await _repository.acceptTerms();
    if (response.success) {
      // Refresh user data to get updated terms status
      await refreshUser();
      return true;
    }
    state = AuthState(error: response.message);
    return false;
  }

  Future<bool> deleteAccount({String? reason}) async {
    state = const AuthState(isLoading: true);
    final response = await _repository.deleteAccount(reason: reason);
    if (response.success) {
      // Clear tokens and logout
      await logout();
      return true;
    }
    state = AuthState(error: response.message);
    return false;
  }
}
