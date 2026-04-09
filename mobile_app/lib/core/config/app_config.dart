// ??? ????????
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

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

    // Default to production backend unless ENV explicitly says development.
    // This avoids "empty data" confusion when .env is missing in test builds.
    final env = _readEnvValue('ENV');
    if ((env ?? '').toLowerCase() == 'development') {
      return 'http://10.0.2.2:5050';
    }
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

  /// Google OAuth Web Client ID (for server-side verification).
  /// Set GOOGLE_WEB_CLIENT_ID in .env.
  static String? get googleWebClientId {
    if (dotenv.isInitialized) {
      return dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    }
    return null;
  }

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
