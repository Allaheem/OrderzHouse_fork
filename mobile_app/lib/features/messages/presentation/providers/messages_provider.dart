// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/messages_repository.dart';
import '../../data/models/message_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Messages repository provider
final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository();
});

/// Provider to fetch messages for a project
/// Watches userId to auto-invalidate on account switch/logout
final projectMessagesProvider = FutureProvider.autoDispose.family<List<Message>, int>((
  ref,
  projectId,
) async {
  // Watch userId to auto-invalidate when user changes
  final userId = ref.watch(authStateProvider.select((state) => state.userId));

  // Guard against logged out state
  if (userId == null) {
    return [];
  }

  final repository = ref.read(messagesRepositoryProvider);
  final response = await repository.getProjectMessages(projectId);

  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.message ?? 'Failed to fetch messages');
  }
});

/// Unread count for project chat (current user). Used for red dot on messages icon.
/// While loading: 0 (no dot, no flicker). 404/empty => 0.
final projectUnreadProvider = FutureProvider.autoDispose.family<int, int>((
  ref,
  projectId,
) async {
  final userId = ref.watch(authStateProvider.select((state) => state.userId));
  if (userId == null) return 0;
  final repository = ref.read(messagesRepositoryProvider);
  final response = await repository.getUnreadCount(projectId);
  if (response.success && response.data != null) return response.data!;
  return 0;
});

/// Mark project messages as read and refresh unread count.
final projectUnreadControllerProvider = Provider<ProjectUnreadController>((
  ref,
) {
  return ProjectUnreadController(ref: ref);
});

class ProjectUnreadController {
  ProjectUnreadController({required this.ref});
  final Ref ref;

  Future<void> markAsRead(int projectId) async {
    final repository = ref.read(messagesRepositoryProvider);
    await repository.markProjectMessagesAsRead(projectId);
    ref.invalidate(projectUnreadProvider(projectId));
  }
}
