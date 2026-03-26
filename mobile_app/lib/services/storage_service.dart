// ??? ????????
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../utils/constants.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Storage (Secure)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // User Data Storage
  static Future<void> saveUser(User user) async {
    if (_prefs != null) {
      await _prefs!.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    }
  }

  static Future<User?> getUser() async {
    if (_prefs != null) {
      final userJson = _prefs!.getString(AppConstants.userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    }
    return null;
  }

  static Future<void> deleteUser() async {
    if (_prefs != null) {
      await _prefs!.remove(AppConstants.userKey);
    }
  }

  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}

extension UserJson on User {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role_id': roleId,
      'first_name': firstName,
      'last_name': lastName,
      'profile_pic_url': profilePicUrl,
      'is_deleted': isDeleted,
      'is_two_factor_enabled': isTwoFactorEnabled,
      'email_verified': emailVerified,
    };
  }
}
