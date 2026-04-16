// ??? ????????
import 'package:flutter/foundation.dart';
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

  /// Public website origin for “open admin in browser” shortcuts (no trailing slash).
  /// Example: https://orderzhouse.com — override with `ADMIN_WEB_URL` in `.env`.
  static String get adminWebOrigin {
    final raw = _readEnvValue('ADMIN_WEB_URL');
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://orderzhouse.com';
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

  /// PayPal plan checkout (backend `/paypal/plan/*`).
  /// Prefer server [`GET /paypal/checkout-available`]; this flag forces the button on without a round-trip.
  /// Accepts `true`, `1`, or `yes` in `.env` / `--dart-define`.
  static bool get enablePayPalPlanCheckout {
    final v = _readEnvValue('ENABLE_PAYPAL');
    if (v == null || v.isEmpty) return false;
    switch (v.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      default:
        return false;
    }
  }

  /// When `true`, hides “Pay with PayPal” on the subscription sheet (Apple IAP + company flow only).
  /// Set `SUBSCRIPTION_HIDE_PAYPAL=true` in `mobile_app/.env` while testing Apple; remove when you return to PayPal.
  static bool get hidePayPalPlanCheckout {
    final v = _readEnvValue('SUBSCRIPTION_HIDE_PAYPAL');
    if (v == null || v.isEmpty) return false;
    switch (v.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      default:
        return false;
    }
  }

  /// Non-release builds only: show the PayPal button when the API points at a **local/LAN** dev server,
  /// so you do not need `ENABLE_PAYPAL=true` or `GET /paypal/checkout-available` during local testing.
  /// Release/App Store builds ignore this (still require explicit flag or server).
  static bool get showPayPalButtonForLocalDev {
    if (kReleaseMode) return false;
    final u = baseUrl.toLowerCase();
    if (u.contains('127.0.0.1') ||
        u.contains('localhost') ||
        u.contains('10.0.2.2')) {
      return true;
    }
    if (RegExp(r'^https?://192\.168\.\d{1,3}\.\d{1,3}').hasMatch(u)) {
      return true;
    }
    if (RegExp(r'^https?://10\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(u)) {
      return true;
    }
    return false;
  }
}
