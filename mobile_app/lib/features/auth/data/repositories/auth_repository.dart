// ??? ????????
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_interceptors.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../../core/config/app_config.dart';
import '../models/signup_payload.dart';

typedef GoogleSignInFactory =
    GoogleSignIn Function({List<String> scopes, String? serverClientId});

abstract class AuthTokenStore {
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<String?> readAccessToken();
  Future<void> clearAll();
}

class SecureAuthTokenStore implements AuthTokenStore {
  @override
  Future<void> saveAccessToken(String token) =>
      SecureStore.saveAccessToken(token);

  @override
  Future<void> saveRefreshToken(String token) =>
      SecureStore.saveRefreshToken(token);

  @override
  Future<String?> readAccessToken() => SecureStore.readAccessToken();

  @override
  Future<void> clearAll() => SecureStore.clearAll();
}

/*
  GOOGLE SIGN-IN CONFIGURATION CHECKLIST:
  ———————————————————————————————————————
  Android:
    - SHA-1 (debug + release) must be added to Google Cloud Console OAuth credentials.
    - Package name must match applicationId in build.gradle.
    - GOOGLE_WEB_CLIENT_ID in .env = Web application client ID from Console.
  iOS:
    - Bundle ID must match Google Cloud Console iOS OAuth client.
    - Info.plist: CFBundleURLTypes with REVERSED_CLIENT_ID (e.g. com.googleusercontent.apps.xxx).
    - GOOGLE_WEB_CLIENT_ID in .env = Web application client ID (used as serverClientId).
  Backend:
    - POST /auth/google accepts { idToken }.
    - GOOGLE_WEB_CLIENT_ID or GOOGLE_CLIENT_ID in backend .env.
*/

class AuthRepository {
  AuthRepository({
    Dio? dio,
    AuthTokenStore? tokenStore,
    GoogleSignInFactory? googleSignInFactory,
  }) : _dio = dio ?? DioClient.instance,
       _tokenStore = tokenStore ?? SecureAuthTokenStore(),
       _googleSignInFactory =
           googleSignInFactory ?? _defaultGoogleSignInFactory;

  final Dio _dio;
  final AuthTokenStore _tokenStore;
  final GoogleSignInFactory _googleSignInFactory;

  static GoogleSignIn _defaultGoogleSignInFactory({
    List<String> scopes = const <String>[],
    String? serverClientId,
  }) {
    return GoogleSignIn(scopes: scopes, serverClientId: serverClientId);
  }

  String? _extractErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final value = data['message'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _extractDetailedBackendError(
    Map<String, dynamic>? data, {
    required String fallback,
  }) {
    final message = data?['message'];
    final error = data?['error'];
    final detailed = data?['details'];

    final base = (message is String && message.trim().isNotEmpty)
        ? message.trim()
        : fallback;

    if (error is String && error.trim().isNotEmpty) {
      return '$base (${error.trim()})';
    }
    if (detailed is String && detailed.trim().isNotEmpty) {
      return '$base (${detailed.trim()})';
    }

    return base;
  }

  String _mapDuplicateConstraintMessage(
    String currentMessage,
    Map<String, dynamic>? data,
  ) {
    final error = data?['error']?.toString() ?? '';
    final lowerError = error.toLowerCase();
    if (error.contains('users_phone_number_key') ||
        (lowerError.contains('duplicate') && lowerError.contains('phone'))) {
      return 'This phone number is already registered. Try logging in or use a different number.';
    }
    if (error.contains('users_email_key') ||
        (lowerError.contains('duplicate') && lowerError.contains('email'))) {
      return 'This email is already registered. Try logging in or use a different email.';
    }
    if (error.contains('users_username_key') ||
        (lowerError.contains('duplicate') && lowerError.contains('username'))) {
      return 'This username is already taken. Please choose another.';
    }
    return currentMessage;
  }

  /// Sign in with Google: get idToken, send to backend, store JWT.
  Future<ApiResponse<User>> signInWithGoogle() async {
    try {
      final serverClientId = AppConfig.googleWebClientId;
      if (kDebugMode && (serverClientId == null || serverClientId.isEmpty)) {
        developer.log(
          'GOOGLE_SIGNIN: GOOGLE_WEB_CLIENT_ID is not set in .env',
          name: 'Auth',
        );
      }

      final googleSignIn = _googleSignInFactory(
        scopes: ['email', 'profile'],
        serverClientId: serverClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          developer.log('GOOGLE_SIGNIN: User cancelled', name: 'Auth');
        }
        return const ApiResponse(
          success: false,
          message: 'Sign in was cancelled',
        );
      }

      if (kDebugMode) {
        developer.log('GOOGLE_SIGNIN: email=${googleUser.email}', name: 'Auth');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (kDebugMode) {
        developer.log(
          'GOOGLE_SIGNIN: idToken=${idToken != null ? "${idToken.substring(0, idToken.length < 15 ? idToken.length : 15)}..." : "null"}',
          name: 'Auth',
        );
        developer.log(
          'GOOGLE_SIGNIN: accessToken=${accessToken != null ? "${accessToken.substring(0, accessToken.length < 15 ? accessToken.length : 15)}..." : "null"}',
          name: 'Auth',
        );
      }

      if (idToken == null || idToken.isEmpty) {
        if (kDebugMode) {
          developer.log(
            'GOOGLE_SIGNIN: idToken is null - OAuth config issue (serverClientId?)',
            name: 'Auth',
          );
        }
        return const ApiResponse(
          success: false,
          message:
              'Missing idToken (OAuth config issue). Check GOOGLE_WEB_CLIENT_ID and SHA-1.',
        );
      }

      final response = await _dio.post(
        '/auth/google',
        data: {
          'idToken': idToken,
          if (accessToken != null) 'accessToken': accessToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        final token = data['token'] as String;
        await _tokenStore.saveAccessToken(token);
        final refreshToken = data['refreshToken'] as String?;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _tokenStore.saveRefreshToken(refreshToken);
        }

        final rawUser = data['userInfo'] ?? data['user'];
        if (rawUser == null || rawUser is! Map<String, dynamic>) {
          return const ApiResponse(
            success: false,
            message: 'Invalid response from server',
          );
        }
        final userData = Map<String, dynamic>.from(rawUser);
        if (data['must_accept_terms'] != null) {
          userData['must_accept_terms'] = data['must_accept_terms'];
        }
        if (data['terms_version_required'] != null) {
          userData['terms_version_required'] = data['terms_version_required'];
        }
        final user = User.fromJson(userData);
        return ApiResponse(
          success: true,
          message: data['message'] as String?,
          data: user,
        );
      }

      return ApiResponse(
        success: false,
        message: data['message'] as String? ?? 'Google sign in failed',
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        developer.log(
          'GOOGLE_SIGNIN PlatformException: ${e.runtimeType} code=${e.code} message=${e.message}',
          name: 'Auth',
        );
        developer.log(
          'GOOGLE_SIGNIN stack: ${e.stacktrace ?? e.toString()}',
          name: 'Auth',
        );
      }
      final msg = '${e.code}: ${e.message ?? "Platform error"}';
      return ApiResponse(success: false, message: msg);
    } on DioException catch (e) {
      final backendMsg = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      final msg = backendMsg ?? e.message ?? 'Google sign in failed';
      if (kDebugMode) {
        developer.log(
          'GOOGLE_SIGNIN DioException: ${e.runtimeType} status=${e.response?.statusCode} message=$msg',
          name: 'Auth',
        );
        developer.log(
          'GOOGLE_SIGNIN response: ${e.response?.data}',
          name: 'Auth',
        );
      }
      return ApiResponse(success: false, message: msg);
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'GOOGLE_SIGNIN Exception: ${e.runtimeType} $e',
          name: 'Auth',
        );
        developer.log('GOOGLE_SIGNIN stack: $stack', name: 'Auth');
      }
      final isCancel =
          e.toString().toLowerCase().contains('cancel') ||
          e.toString().toLowerCase().contains('sign_in_canceled');
      return ApiResponse(
        success: false,
        message: isCancel
            ? 'Sign in was cancelled'
            : 'Google sign in failed: ${e.runtimeType}',
      );
    }
  }

  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/users/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['token'] != null) {
        final token = data['token'] as String;
        await _tokenStore.saveAccessToken(token);
        final refreshToken = data['refreshToken'] as String?;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _tokenStore.saveRefreshToken(refreshToken);
        }

        final userData = data['userInfo'] as Map<String, dynamic>;
        // Include terms acceptance fields
        if (data['must_accept_terms'] != null) {
          userData['must_accept_terms'] = data['must_accept_terms'];
        }
        if (data['terms_version_required'] != null) {
          userData['terms_version_required'] = data['terms_version_required'];
        }
        final user = User.fromJson(userData);
        return ApiResponse(
          success: true,
          message: data['message'] as String?,
          data: user,
        );
      }

      // No token - treat as login failure (not OTP)
      // OTP is only for registration, not login
      return ApiResponse(
        success: false,
        message:
            data['message'] as String? ??
            'Login failed. Please check your credentials.',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] as String? ?? 'Login failed',
      );
    }
  }

  Future<ApiResponse<User>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/users/verify-otp',
        data: {'email': email, 'otp': otp},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      await _tokenStore.saveAccessToken(token);
      final refreshToken = data['refreshToken'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _tokenStore.saveRefreshToken(refreshToken);
      }

      final userData = data['userInfo'] as Map<String, dynamic>;
      // Include terms acceptance fields
      if (data['must_accept_terms'] != null) {
        userData['must_accept_terms'] = data['must_accept_terms'];
      }
      if (data['terms_version_required'] != null) {
        userData['terms_version_required'] = data['terms_version_required'];
      }
      final user = User.fromJson(userData);
      return ApiResponse(
        success: true,
        message: data['message'] as String?,
        data: user,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ?? 'OTP verification failed',
      );
    }
  }

  /// Step A: Request OTP for signup. Does NOT create user. Backend stores OTP and sends email.
  Future<ApiResponse<void>> requestSignupOtp(String email) async {
    final uri = '${_dio.options.baseUrl}/users/request-signup-otp';
    if (kDebugMode) {
      developer.log('OTP REQUEST => POST $uri', name: 'Auth');
    }
    try {
      final response = await _dio.post(
        '/users/request-signup-otp',
        data: {'email': email.trim().toLowerCase()},
      );
      final status = response.statusCode ?? 0;
      final message = response.data is Map
          ? (response.data as Map)['message'] as String?
          : null;
      if (kDebugMode) {
        developer.log(
          'OTP REQUEST => status=$status message=$message',
          name: 'Auth',
        );
      }
      return ApiResponse(
        success: status >= 200 && status < 300,
        message: message ?? 'Verification code sent',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data as Map<String, dynamic>?;
      final message =
          data?['message'] as String? ?? 'Failed to send verification code';
      if (kDebugMode) {
        developer.log(
          'OTP REQUEST FAILED => status=$status message=$message',
          name: 'Auth',
        );
        developer.log('OTP REQUEST response data: $data', name: 'Auth');
      }
      return ApiResponse(success: false, message: message);
    }
  }

  /// Step B: Verify OTP and create user in one call. Saves token and returns user on success.
  Future<ApiResponse<User>> verifyAndRegister({
    required SignupPayload payload,
    required String otp,
  }) async {
    final uri = '${_dio.options.baseUrl}/users/verify-and-register';
    if (kDebugMode) {
      developer.log('VERIFY_AND_REGISTER => POST $uri', name: 'Auth');
    }
    try {
      final data = payload.toJson();
      data['otp'] = otp;
      final response = await _dio.post(
        '/users/verify-and-register',
        data: data,
      );
      final status = response.statusCode ?? 0;
      if (kDebugMode) {
        developer.log('VERIFY_AND_REGISTER => status=$status', name: 'Auth');
      }
      final respData = response.data as Map<String, dynamic>;
      final token = respData['token'] as String?;
      if (token == null || token.isEmpty) {
        return const ApiResponse(
          success: false,
          message: 'Invalid response from server',
        );
      }
      await _tokenStore.saveAccessToken(token);
      final refreshToken = respData['refreshToken'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _tokenStore.saveRefreshToken(refreshToken);
      }
      final userInfo = respData['userInfo'] as Map<String, dynamic>?;
      if (userInfo == null) {
        return const ApiResponse(
          success: false,
          message: 'Invalid response from server',
        );
      }
      final userData = Map<String, dynamic>.from(userInfo);
      if (respData['must_accept_terms'] != null) {
        userData['must_accept_terms'] = respData['must_accept_terms'];
      }
      if (respData['terms_version_required'] != null) {
        userData['terms_version_required'] = respData['terms_version_required'];
      }
      final user = User.fromJson(userData);
      return ApiResponse(
        success: true,
        message: respData['message'] as String?,
        data: user,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data as Map<String, dynamic>?;
      final rawMessage = _extractDetailedBackendError(
        data,
        fallback: 'Verification or registration failed',
      );
      final message = _mapDuplicateConstraintMessage(rawMessage, data);
      if (kDebugMode) {
        developer.log(
          'VERIFY_AND_REGISTER FAILED => status=$status message=$message',
          name: 'Auth',
        );
        developer.log('VERIFY_AND_REGISTER response: $data', name: 'Auth');
      }
      return ApiResponse(success: false, message: message);
    }
  }

  Future<ApiResponse<void>> register({
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
    try {
      final data = {
        'role_id': roleId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'country': country,
        'username': username,
      };

      if (categoryIds != null && categoryIds.isNotEmpty) {
        data['category_ids'] = categoryIds;
      }

      if (referralCode != null && referralCode.trim().isNotEmpty) {
        data['referral_code'] = referralCode.trim().toUpperCase();
      }

      final response = await _dio.post('/users/register', data: data);

      return ApiResponse(
        success: response.statusCode == 201,
        message: response.data['message'] as String?,
      );
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;
      String message = _extractDetailedBackendError(
        data,
        fallback: 'Registration failed',
      );
      message = _mapDuplicateConstraintMessage(message, data);
      return ApiResponse(success: false, message: message);
    }
  }

  Future<ApiResponse<void>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/users/verify-email',
        data: {'email': email, 'otp': otp},
      );

      return ApiResponse(
        success: response.statusCode == 200,
        message: response.data['message'] as String?,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Email verification failed',
      );
    }
  }

  Future<ApiResponse<User>> getUserData() async {
    try {
      final response = await _dio.get('/users/getUserdata');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return const ApiResponse(
          success: false,
          message: 'Invalid user response',
        );
      }
      final userRaw = raw['user'];
      if (userRaw is! Map<String, dynamic>) {
        return const ApiResponse(
          success: false,
          message: 'Missing user in response',
        );
      }
      final userData = Map<String, dynamic>.from(userRaw);
      if (raw['must_accept_terms'] != null) {
        userData['must_accept_terms'] = raw['must_accept_terms'];
      }
      if (raw['terms_version_required'] != null) {
        userData['terms_version_required'] = raw['terms_version_required'];
      }
      final user = User.fromJson(userData);
      return ApiResponse(success: true, data: user);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to fetch user data',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to parse user data: $e',
      );
    }
  }

  /// Fetch full editable profile payload from backend.
  /// Keeps raw keys used by edit profile flow (phone_number, country, profile_pic_url).
  Future<ApiResponse<Map<String, dynamic>>> getEditableProfile() async {
    try {
      final response = await _dio.get('/users/getUserdata');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return const ApiResponse(
          success: false,
          message: 'Invalid profile response',
        );
      }
      final user = raw['user'];
      if (user is! Map<String, dynamic>) {
        return const ApiResponse(
          success: false,
          message: 'Profile payload is missing',
        );
      }
      return ApiResponse(success: true, data: user);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            _extractErrorMessage(e.response?.data) ?? 'Failed to load profile',
      );
    }
  }

  /// Update editable profile fields and optional avatar.
  /// Uses secure token storage internally to keep auth concerns out of UI.
  Future<ApiResponse<Map<String, dynamic>>> updateEditableProfile({
    required Map<String, String> fields,
    File? avatarFile,
    String? existingProfilePicUrl,
  }) async {
    try {
      final token = await _tokenStore.readAccessToken();
      if (token == null) {
        return const ApiResponse(
          success: false,
          message: 'Authentication required. Please login.',
        );
      }

      final formData = FormData();
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });

      if (avatarFile != null) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              avatarFile.path,
              filename: 'profile_pic.jpg',
            ),
          ),
        );
      } else if (existingProfilePicUrl != null &&
          existingProfilePicUrl.isNotEmpty) {
        formData.fields.add(MapEntry('profile_pic_url', existingProfilePicUrl));
      }

      final response = await _dio.put(
        '/users/edit',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return const ApiResponse(success: false, message: 'Invalid response');
      }
      final ok = response.statusCode == 200 && raw['success'] == true;
      if (!ok) {
        return ApiResponse(
          success: false,
          message:
              (raw['message'] is String &&
                  (raw['message'] as String).isNotEmpty)
              ? raw['message'] as String
              : 'Failed to update profile',
        );
      }

      final userMap = raw['user'];
      return ApiResponse(
        success: true,
        data: userMap is Map<String, dynamic> ? userMap : <String, dynamic>{},
        message: raw['message'] as String?,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            _extractErrorMessage(e.response?.data) ??
            'Failed to update profile',
      );
    }
  }

  Future<ApiResponse<void>> acceptTerms() async {
    try {
      final response = await _dio.post('/auth/accept-terms');
      return ApiResponse(
        success: response.statusCode == 200,
        message: response.data['message'] as String?,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ?? 'Failed to accept terms',
      );
    }
  }

  Future<ApiResponse<void>> deleteAccount({String? reason}) async {
    try {
      developer.log(
        'DELETE_ACCOUNT request: PUT /users/deactivate reason=$reason',
        name: 'Auth',
      );
      final response = await _dio.put(
        '/users/deactivate',
        data: reason != null ? {'reason': reason} : {},
      );

      developer.log(
        'DELETE_ACCOUNT response[${response.statusCode}]: ${response.data}',
        name: 'Auth',
      );

      return ApiResponse(
        success: response.statusCode == 200 && response.data['success'] == true,
        message:
            response.data['message'] as String? ??
            'Account deleted successfully',
      );
    } on DioException catch (e) {
      developer.log(
        'DELETE_ACCOUNT error[${e.response?.statusCode}]: ${e.response?.data}',
        name: 'Auth',
      );
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to delete account',
      );
    }
  }

  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _tokenStore.readAccessToken();
      if (token == null) {
        return const ApiResponse(
          success: false,
          message: 'Authentication required. Please login.',
        );
      }

      final response = await _dio.patch(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return ApiResponse(
        success: response.statusCode == 200,
        message:
            response.data['message'] as String? ??
            'Password changed successfully',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Failed to change password';

      if (statusCode == 400 || statusCode == 401) {
        message =
            e.response?.data['message'] as String? ??
            'Current password is incorrect';
      } else if (statusCode == 500) {
        message =
            e.response?.data['message'] as String? ??
            'Server error. Please try again.';
      }

      return ApiResponse(success: false, message: message);
    }
  }

  // ==================== Two-Factor Authentication ====================
  /// POST /auth/2fa/generate — returns QR data URL only (secret never sent over the wire).
  Future<ApiResponse<Map<String, dynamic>>> generateTwoFactor() async {
    try {
      final response = await _dio.post('/auth/2fa/generate');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return const ApiResponse(success: false, message: 'Invalid response');
      }
      if (raw['success'] != true) {
        return ApiResponse(
          success: false,
          message: raw['message'] as String? ?? 'Failed to generate 2FA',
        );
      }
      return ApiResponse(
        success: true,
        data: {
          'qrCodeUrl': raw['qrCodeUrl'] as String?,
        },
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            _extractErrorMessage(e.response?.data) ?? 'Failed to start 2FA setup',
      );
    }
  }

  /// POST /auth/2fa/verify — body: `{ "token": "<6-digit>" }`
  Future<ApiResponse<void>> verifyTwoFactor({required String token}) async {
    try {
      final response = await _dio.post(
        '/auth/2fa/verify',
        data: {'token': token.trim()},
      );
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        return ApiResponse(
          success: true,
          message: raw['message'] as String? ?? '2FA enabled',
        );
      }
      final msg = raw is Map<String, dynamic>
          ? raw['message'] as String?
          : null;
      return ApiResponse(success: false, message: msg ?? 'Verification failed');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _extractErrorMessage(e.response?.data) ?? 'Invalid code',
      );
    }
  }

  /// POST /auth/2fa/disable
  Future<ApiResponse<void>> disableTwoFactor() async {
    try {
      final response = await _dio.post('/auth/2fa/disable');
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        return ApiResponse(
          success: true,
          message: raw['message'] as String? ?? '2FA disabled',
        );
      }
      final msg = raw is Map<String, dynamic>
          ? raw['message'] as String?
          : null;
      return ApiResponse(success: false, message: msg ?? 'Failed to disable');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            _extractErrorMessage(e.response?.data) ?? 'Failed to disable 2FA',
      );
    }
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _tokenStore.clearAll();
  }

  // ==================== Forgot Password Flow ====================

  /// Request OTP for password reset
  Future<ApiResponse<void>> requestPasswordResetOtp({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
        options: Options(
          extra: {AuthInterceptor.extraSkipAuth: true},
        ),
      );

      return ApiResponse(
        success: response.statusCode == 200 || response.statusCode == 201,
        message:
            response.data['message'] as String? ?? 'OTP sent to your email',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Verify OTP for password reset
  Future<ApiResponse<String?>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-reset-otp',
        data: {'email': email, 'otp': otp},
        options: Options(
          extra: {AuthInterceptor.extraSkipAuth: true},
        ),
      );

      // Backend may return a reset token
      final resetToken = response.data['resetToken'] as String?;

      return ApiResponse(
        success: response.statusCode == 200,
        message:
            response.data['message'] as String? ?? 'OTP verified successfully',
        data: resetToken,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Invalid OTP. Please try again.',
      );
    }
  }

  /// Reset password with email, OTP, and new password
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
        options: Options(
          extra: {AuthInterceptor.extraSkipAuth: true},
        ),
      );

      return ApiResponse(
        success: response.statusCode == 200,
        message:
            response.data['message'] as String? ??
            'Password reset successfully',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message:
            e.response?.data['message'] as String? ??
            'Failed to reset password. Please try again.',
      );
    }
  }

  /// Resend OTP for password reset
  Future<ApiResponse<void>> resendPasswordResetOtp({
    required String email,
  }) async {
    // This can reuse the requestPasswordResetOtp method
    return requestPasswordResetOtp(email: email);
  }
}
