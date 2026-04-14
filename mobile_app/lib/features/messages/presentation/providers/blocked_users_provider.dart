// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/blocked_user_entry.dart';
import '../../data/repositories/moderation_repository.dart';
import 'moderation_repository_provider.dart';

class BlockedUsersState {
  final List<BlockedUserEntry> entries;
  final bool isReady;
  final String? lastError;

  const BlockedUsersState({
    this.entries = const [],
    this.isReady = false,
    this.lastError,
  });

  Set<int> get ids => entries.map((e) => e.userId).toSet();

  BlockedUsersState copyWith({
    List<BlockedUserEntry>? entries,
    bool? isReady,
    String? lastError,
    bool clearLastError = false,
  }) {
    return BlockedUsersState(
      entries: entries ?? this.entries,
      isReady: isReady ?? this.isReady,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

class BlockedUsersNotifier extends StateNotifier<BlockedUsersState> {
  BlockedUsersNotifier(this._ref) : super(const BlockedUsersState()) {
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      final a = prev?.user?.id;
      final b = next.user?.id;
      if (a != b) {
        load();
      }
    });
    load();
  }

  final Ref _ref;

  ModerationRepository get _repo => _ref.read(moderationRepositoryProvider);

  Future<void> load() async {
    final userId = _ref.read(authStateProvider).user?.id;
    if (userId == null) {
      state = const BlockedUsersState(entries: [], isReady: true);
      return;
    }
    state = BlockedUsersState(
      entries: state.entries,
      isReady: false,
      lastError: null,
    );
    final res = await _repo.fetchBlocks();
    if (res.success && res.data != null) {
      state = BlockedUsersState(entries: res.data!, isReady: true);
    } else {
      state = BlockedUsersState(
        entries: const [],
        isReady: true,
        lastError: res.message,
      );
    }
  }

  /// Server-side block (same project). [displayName] is used for immediate UI if load is skipped.
  Future<bool> block(
    int userId,
    String displayName,
    int projectId,
  ) async {
    if (userId <= 0 || projectId <= 0) return false;
    final res = await _repo.blockUser(
      projectId: projectId,
      blockedUserId: userId,
    );
    if (!res.success) {
      state = BlockedUsersState(
        entries: state.entries,
        isReady: true,
        lastError: res.message,
      );
      return false;
    }
    final name = displayName.trim().isEmpty ? 'User #$userId' : displayName.trim();
    final current = List<BlockedUserEntry>.from(state.entries);
    if (!current.any((e) => e.userId == userId)) {
      current.add(BlockedUserEntry(userId: userId, displayName: name));
    }
    state = BlockedUsersState(entries: current, isReady: true);
    await load();
    return true;
  }

  Future<bool> unblock(int userId) async {
    final res = await _repo.unblockUser(userId);
    if (!res.success) {
      state = BlockedUsersState(
        entries: state.entries,
        isReady: true,
        lastError: res.message,
      );
      return false;
    }
    await load();
    return true;
  }
}

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, BlockedUsersState>((ref) {
  return BlockedUsersNotifier(ref);
});
