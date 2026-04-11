import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Stable helpers for saving delivery attachments and opening them on device.
/// iOS: `url_launcher` + `file://` is unreliable; use [openSavedDownload] instead.
class LocalDownloadOpen {
  LocalDownloadOpen._();

  /// Safe single-segment filename for local storage (no path separators).
  static String safeFileName(String raw) {
    final base = p.basename(raw.trim());
    if (base.isEmpty) return 'download';
    return base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Opens a saved file with the OS viewer, or falls back to the share sheet
  /// (lets user save to Files / pick an app) when no handler is registered.
  static Future<String?> openSavedDownload(String absolutePath) async {
    final file = File(absolutePath);
    if (!file.existsSync()) {
      return 'File not found on device.';
    }
    if (file.lengthSync() == 0) {
      return 'Downloaded file is empty.';
    }

    final result = await OpenFile.open(absolutePath);
    if (result.type == ResultType.done) {
      return null;
    }

    // Common on iOS Simulator: no default app for this extension.
    try {
      await Share.shareXFiles(
        [XFile(absolutePath)],
        subject: p.basename(absolutePath),
      );
      return null;
    } catch (e) {
      return result.message.isNotEmpty
          ? result.message
          : 'Could not open file (${result.type}).';
    }
  }
}
