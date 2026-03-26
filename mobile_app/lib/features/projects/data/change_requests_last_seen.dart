// ??? ????????
import 'package:shared_preferences/shared_preferences.dart';

/// Local read tracking for change requests (per user + project).
/// Key: "cr_last_seen_{userId}_{projectId}", value: milliseconds since epoch (int).
class ChangeRequestsLastSeen {
  static String _key(int userId, int projectId) =>
      'cr_last_seen_${userId}_$projectId';

  static Future<DateTime?> getLastSeen(int userId, int projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_key(userId, projectId));
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastSeen(
    int userId,
    int projectId,
    DateTime at,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(userId, projectId), at.millisecondsSinceEpoch);
    } catch (_) {}
  }
}
