// ??? ????????
import 'dart:convert';

import 'package:flutter/services.dart';
import 'models/policy_document.dart';

/// Loads privacy policy document from assets based on locale.
class PolicyRepository {
  static const String _basePath = 'assets/policies';

  /// Loads privacy policy for the given [languageCode] (e.g. 'en', 'ar').
  /// Falls back to 'en' if the locale file is missing.
  Future<PolicyDocument> loadPrivacyPolicy(String languageCode) async {
    final normalized = languageCode.toLowerCase().startsWith('ar')
        ? 'ar'
        : 'en';
    final path = '$_basePath/privacy_$normalized.json';
    try {
      final jsonStr = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PolicyDocument.fromJson(decoded);
    } catch (_) {
      if (normalized != 'en') {
        final jsonStr = await rootBundle.loadString(
          '$_basePath/privacy_en.json',
        );
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return PolicyDocument.fromJson(decoded);
      }
      rethrow;
    }
  }
}
