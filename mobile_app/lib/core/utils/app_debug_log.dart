import 'package:flutter/foundation.dart';

/// Debug-only logging. Never logs in release/profile store builds.
void appDebugLog(Object? message) {
  if (kDebugMode) {}
}
