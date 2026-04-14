// ??? ????????
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const String kSupportEmail = 'info@battechno.com';

Uri supportMailtoUri({required String subject, required String body}) {
  return Uri(
    scheme: 'mailto',
    path: kSupportEmail,
    queryParameters: <String, String>{
      'subject': subject,
      if (body.isNotEmpty) 'body': body,
    },
  );
}

/// iOS/Android differ on which [LaunchMode] succeeds for `mailto:`; simulator often has no Mail.
Future<bool> tryLaunchSupportMailto(Uri uri) async {
  for (final mode in [
    LaunchMode.platformDefault,
    LaunchMode.externalApplication,
  ]) {
    try {
      if (await launchUrl(uri, mode: mode)) {
        return true;
      }
    } catch (_) {
      // Try next mode or clipboard fallback.
    }
  }
  return false;
}

Future<void> copySupportDraft(String subject, String body) async {
  final draft = 'To: $kSupportEmail\nSubject: $subject\n\n$body';
  await Clipboard.setData(ClipboardData(text: draft));
}
