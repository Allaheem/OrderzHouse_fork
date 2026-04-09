// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'favorite_project_ids_v1';

/// Locally saved favorite project IDs (same device; no backend API yet).
final favoriteProjectIdsProvider =
    StateNotifierProvider<FavoriteProjectIdsNotifier, Set<int>>((ref) {
      return FavoriteProjectIdsNotifier();
    });

class FavoriteProjectIdsNotifier extends StateNotifier<Set<int>> {
  FavoriteProjectIdsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final ids = <int>{};
    for (final s in raw) {
      final id = int.tryParse(s);
      if (id != null) ids.add(id);
    }
    state = ids;
  }

  Future<void> toggle(int projectId) async {
    final next = Set<int>.from(state);
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      next.map((e) => e.toString()).toList(),
    );
  }
}
