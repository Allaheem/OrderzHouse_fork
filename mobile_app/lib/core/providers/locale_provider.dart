// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_prefs.dart';

/// Supported locales
class AppLocales {
  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  static const List<Locale> supported = [english, arabic];

  /// Check if locale is RTL
  static bool isRtl(Locale locale) => locale.languageCode == 'ar';
}

/// Locale state notifier for managing app language (uses AppPrefs — non-sensitive only)
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(AppLocales.english) {
    _loadSavedLocale();
  }

  /// Load saved locale from AppPrefs
  Future<void> _loadSavedLocale() async {
    try {
      final savedLocale = await AppPrefs.getLanguageCode();
      if (savedLocale != null) {
        state = Locale(savedLocale);
      }
    } catch (_) {
    }
  }

  /// Change app locale and persist
  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    state = locale;

    try {
      await AppPrefs.setLanguageCode(locale.languageCode);
    } catch (_) {
    }
  }

  /// Toggle between English and Arabic
  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? AppLocales.arabic
        : AppLocales.english;
    await setLocale(newLocale);
  }

  /// Check if current locale is Arabic (RTL)
  bool get isArabic => state.languageCode == 'ar';

  /// Check if current locale is RTL
  bool get isRtl => AppLocales.isRtl(state);
}

/// Provider for locale state
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Provider for checking if current locale is RTL
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocales.isRtl(locale);
});
