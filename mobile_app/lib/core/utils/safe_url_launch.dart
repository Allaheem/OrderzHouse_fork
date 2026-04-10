import 'package:url_launcher/url_launcher.dart';

/// Blocks javascript: and other dangerous schemes for user-facing opens.
bool isSafeExternalHttpUrl(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'https') return true;
  if (scheme == 'http') return false;
  return false;
}

/// Opens [uri] in external browser only if scheme is https (or mailto/tel for [allowContactSchemes]).
Future<bool> launchTrustedHttpUrl(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
  bool allowContactSchemes = false,
}) async {
  final scheme = uri.scheme.toLowerCase();
  if (allowContactSchemes &&
      (scheme == 'mailto' || scheme == 'tel' || scheme == 'sms')) {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: mode);
  }
  if (!isSafeExternalHttpUrl(uri)) return false;
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: mode);
}
