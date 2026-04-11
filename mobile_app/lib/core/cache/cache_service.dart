// ??? ????????
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache service using Hive for non-sensitive data (projects, categories, etc.).
/// Do NOT store auth tokens here — use flutter_secure_storage.
class CacheService {
  static const String boxName = 'app_cache';
  static const String _timestampSuffix = '_ts';
  static const Duration defaultTtl = Duration(minutes: 10);

  static Box<String>? _box;

  /// False if [init] failed or was skipped (app still runs; cache reads/writes no-op).
  static bool get isEnabled => _box != null;

  /// Call from main() after Hive.initFlutter(). Opens [boxName].
  static Future<void> init() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox<String>(boxName);
    } catch (_) {
      _box = null;
    }
  }

  /// Get cached value. Returns null if missing or decode fails.
  static T? getCached<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final b = _box;
    if (b == null) return null;
    try {
      final raw = b.get(key);
      if (raw == null) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      final data = map['v'];
      if (data == null) return null;
      return fromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Store value with [timestamp] (e.g. DateTime.now().millisecondsSinceEpoch).
  static Future<void> setCached<T>(
    String key,
    T value,
    int timestamp,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final b = _box;
    if (b == null) return;
    try {
      final map = {'v': toJson(value), 'ts': timestamp};
      await b.put(key, json.encode(map));
      await b.put('$key$_timestampSuffix', timestamp.toString());
    } catch (e) {
      // ignore
    }
  }

  /// True if cache for [key] is older than [ttl]. Returns true if key missing.
  static bool isExpired(String key, [Duration ttl = defaultTtl]) {
    final b = _box;
    if (b == null) return true;
    try {
      final raw = b.get('$key$_timestampSuffix');
      if (raw == null) return true;
      final ts = int.tryParse(raw);
      if (ts == null) return true;
      return DateTime.now().millisecondsSinceEpoch - ts > ttl.inMilliseconds;
    } catch (_) {
      return true;
    }
  }

  /// Get cached list (sync). Returns null if missing or decode fails.
  static List<T>? getListSync<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final b = _box;
    if (b == null) return null;
    try {
      final raw = b.get(key);
      if (raw == null) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      final list = map['v'];
      if (list == null || list is! List) return null;
      return (list).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Get cached list (async). Compatible with existing await CacheService.getList(...).
  static Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    return getListSync(key, fromJson);
  }

  /// Set cached list with current timestamp.
  static Future<void> setList<T>(
    String key,
    List<T> data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final b = _box;
    if (b == null) return;
    try {
      final list = data.map((e) => toJson(e)).toList();
      final map = {'v': list, 'ts': ts};
      await b.put(key, json.encode(map));
      await b.put('$key$_timestampSuffix', ts.toString());
    } catch (e) {
      // ignore
    }
  }

  /// Clear one key (and its timestamp).
  static Future<void> clear(String key) async {
    final b = _box;
    if (b == null) return;
    try {
      await b.delete(key);
      await b.delete('$key$_timestampSuffix');
    } catch (_) {}
  }

  /// Clear all entries in cache box.
  static Future<void> clearAll() async {
    final b = _box;
    if (b == null) return;
    try {
      await b.clear();
    } catch (_) {}
  }
}
