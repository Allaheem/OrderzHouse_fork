// ??? ????????
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// **Security:** `.env` is listed as a Flutter asset and is shipped inside the app binary.
  /// Put only non-secret overrides here (e.g. `APP_API_URL`). Never store API keys or shared secrets.
  static const String _releaseDefaultApiUrl =
      'https://orderzhouse-backend.onrender.com';

  static String? _readEnvValue(String key) {
    if (dotenv.isInitialized) {
      final value = dotenv.env[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final defineValue = String.fromEnvironment(key);
    if (defineValue.trim().isNotEmpty) {
      return defineValue.trim();
    }

    return null;
  }

  static String get baseUrl {
    final configuredUrl =
        _readEnvValue('APP_API_URL') ?? _readEnvValue('BASE_URL');
    if (configuredUrl != null) {
      return configuredUrl;
    }

    // Default: always online (Render). For local backend, set APP_API_URL in `.env`
    // (e.g. http://127.0.0.1:5050) — do not rely on ENV=development alone.
    return _releaseDefaultApiUrl;
  }

  static String get environment {
    final configuredEnv = _readEnvValue('ENV');
    if (configuredEnv != null) {
      return configuredEnv;
    }
    return 'production';
  }

  static bool get isProduction => environment == 'production';

  static bool get isDevelopment => environment == 'development';

  /// Company subscription survey URL (offline payment / Subscribe from Company).
  /// Set COMPANY_SUBSCRIBE_URL in .env, e.g. https://appointments.battechno.com/survey
  static String get companySubscribeUrl {
    if (dotenv.isInitialized) {
      final url = dotenv.env['COMPANY_SUBSCRIBE_URL'];
      if (url != null && url.isNotEmpty) return url;
    }
    return 'https://appointments.battechno.com/survey';
  }
}
