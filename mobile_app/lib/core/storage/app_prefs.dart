// ??? ????????
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, non-sensitive app settings only.
/// Do NOT store tokens or secrets here — use [SecureStorageService] / secure_store.
class AppPrefs {
  AppPrefs._();

  static const String _localeKey = 'app_locale';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _onboardingSeenKey = 'onboarding_seen';
  static const String _lastRouteKey = 'last_route';
  static const String _notifMasterKey = 'notif_master';
  static const String _notifProjectsKey = 'notif_projects';
  static const String _notifMessagesKey = 'notif_messages';
  static const String _notifPaymentsKey = 'notif_payments';
  static const String _notifOffersKey = 'notif_offers';

  static SharedPreferences? _prefs;
  static bool _initDone = false;

  static Future<void> init() async {
    if (_initDone) return;
    _prefs = await SharedPreferences.getInstance();
    _initDone = true;
  }

  static Future<SharedPreferences> get _instance async {
    if (_prefs != null) return _prefs!;
    await init();
    return _prefs!;
  }

  // ——— Language (en / ar) ———
  static Future<String?> getLanguageCode() async {
    final prefs = await _instance;
    return prefs.getString(_localeKey);
  }

  static Future<void> setLanguageCode(String code) async {
    final prefs = await _instance;
    await prefs.setString(_localeKey, code);
  }

  // ——— Theme mode ———
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await _instance;
    final index = prefs.getInt(_themeModeKey);
    if (index == null) return ThemeMode.system;
    if (index >= 0 && index <= 2) return ThemeMode.values[index];
    return ThemeMode.system;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _instance;
    await prefs.setInt(_themeModeKey, mode.index);
  }

  // ——— Onboarding seen ———
  static Future<bool> getOnboardingSeen() async {
    final prefs = await _instance;
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setOnboardingSeen(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_onboardingSeenKey, value);
  }

  // ——— Last visited route (for post-restore navigation) ———
  static Future<String?> getLastRoute() async {
    final prefs = await _instance;
    return prefs.getString(_lastRouteKey);
  }

  static Future<void> setLastRoute(String path) async {
    final prefs = await _instance;
    await prefs.setString(_lastRouteKey, path);
  }

  static Future<void> clearLastRoute() async {
    final prefs = await _instance;
    await prefs.remove(_lastRouteKey);
  }

  // ——— Notification preferences ———
  static Future<bool> getNotificationsMaster() async {
    final prefs = await _instance;
    return prefs.getBool(_notifMasterKey) ?? true;
  }

  static Future<void> setNotificationsMaster(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_notifMasterKey, value);
  }

  static Future<bool> getNotificationsProjects() async {
    final prefs = await _instance;
    return prefs.getBool(_notifProjectsKey) ?? true;
  }

  static Future<void> setNotificationsProjects(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_notifProjectsKey, value);
  }

  static Future<bool> getNotificationsMessages() async {
    final prefs = await _instance;
    return prefs.getBool(_notifMessagesKey) ?? true;
  }

  static Future<void> setNotificationsMessages(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_notifMessagesKey, value);
  }

  static Future<bool> getNotificationsPayments() async {
    final prefs = await _instance;
    return prefs.getBool(_notifPaymentsKey) ?? true;
  }

  static Future<void> setNotificationsPayments(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_notifPaymentsKey, value);
  }

  static Future<bool> getNotificationsOffers() async {
    final prefs = await _instance;
    return prefs.getBool(_notifOffersKey) ?? false;
  }

  static Future<void> setNotificationsOffers(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_notifOffersKey, value);
  }

  // ——— Generic lightweight helpers (non-sensitive values only) ———
  static Future<String?> getString(String key) async {
    final prefs = await _instance;
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await _instance;
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await _instance;
    await prefs.remove(key);
  }
}
