// ??? ????????
import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Extension on BuildContext for easy access to AppLocalizations
extension L10nX on BuildContext {
  /// Get AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
