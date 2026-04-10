// ignore_for_file: avoid_classes_with_only_static_members — small app-level helpers
import '../config/app_config.dart';
import '../storage/app_prefs.dart';

/// Remembers which API origin issued the stored JWT so we do not reuse a
/// production token against localhost (or vice versa) after switching [AppConfig.baseUrl].
class AuthApiBinding {
  static const String _prefsKey = 'auth_api_origin_normalized';

  /// Host + port + scheme, with `127.0.0.1` normalized to `localhost`.
  static String normalizeOrigin(String url) {
    final u = Uri.parse(url.trim());
    if (!u.hasScheme || u.host.isEmpty) return url.trim();
    var host = u.host.toLowerCase();
    if (host == '127.0.0.1') host = 'localhost';
    final port = u.hasPort ? u.port : (u.scheme == 'https' ? 443 : 80);
    return '${u.scheme}://$host:$port';
  }

  static Future<void> recordCurrentApiForSession() async {
    await AppPrefs.setString(_prefsKey, normalizeOrigin(AppConfig.baseUrl));
  }

  static Future<void> clear() async {
    await AppPrefs.remove(_prefsKey);
  }

  /// `true` if there is no binding yet (legacy) or it matches the current API.
  static Future<bool> matchesCurrentApi() async {
    final stored = await AppPrefs.getString(_prefsKey);
    if (stored == null || stored.isEmpty) return true;
    return stored == normalizeOrigin(AppConfig.baseUrl);
  }
}
