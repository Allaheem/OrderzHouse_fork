// ??? ????????
import 'secure_storage_service.dart';

/// Single place for token storage. All tokens go through here (flutter_secure_storage).
/// Do NOT store tokens in SharedPreferences — use [AppPrefs] only for non-sensitive settings.
class SecureStore {
  SecureStore._();

  // ——— Access token ———
  static Future<void> saveAccessToken(String token) async {
    await SecureStorageService.saveToken(token);
  }

  static Future<String?> readAccessToken() async {
    return SecureStorageService.getToken();
  }

  static Future<void> deleteAccessToken() async {
    await SecureStorageService.deleteToken();
  }

  // ——— Refresh token ———
  static Future<void> saveRefreshToken(String token) async {
    await SecureStorageService.saveRefreshToken(token);
  }

  static Future<String?> readRefreshToken() async {
    return SecureStorageService.getRefreshToken();
  }

  static Future<void> deleteRefreshToken() async {
    await SecureStorageService.deleteRefreshToken();
  }

  /// Clear all secure data (tokens). Call on logout.
  static Future<void> clearAll() async {
    await SecureStorageService.clearAll();
  }
}
