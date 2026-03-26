// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/change_request_model.dart';
import '../../data/change_requests_last_seen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'projects_provider.dart';

/// Provider to fetch change requests for a project
/// Watches userId to auto-invalidate on account switch/logout
final changeRequestsProvider = FutureProvider.autoDispose
    .family<List<ChangeRequest>, int>((ref, projectId) async {
      final userId = ref.watch(
        authStateProvider.select((state) => state.userId),
      );
      if (userId == null) return [];

      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getProjectChangeRequests(projectId);
      if (response.success && response.data != null) return response.data!;
      return [];
    });

/// Last-seen timestamp for change requests (local). Used to compute unread + "New" chip.
final changeRequestsLastSeenProvider = FutureProvider.autoDispose
    .family<DateTime?, int>((ref, projectId) async {
      final userId = ref.watch(
        authStateProvider.select((state) => state.userId),
      );
      if (userId == null) return null;
      return ChangeRequestsLastSeen.getLastSeen(userId, projectId);
    });

/// Unread count: items where createdAt.isAfter(lastSeenAt). Default 0 while loading (no flicker).
final changeRequestsUnreadCountProvider = FutureProvider.autoDispose
    .family<int, int>((ref, projectId) async {
      final userId = ref.watch(
        authStateProvider.select((state) => state.userId),
      );
      if (userId == null) return 0;

      final list = await ref.watch(changeRequestsProvider(projectId).future);
      final lastSeenAt = await ref.watch(
        changeRequestsLastSeenProvider(projectId).future,
      );
      if (list.isEmpty) return 0;
      return list
          .where((r) => lastSeenAt == null || r.createdAt.isAfter(lastSeenAt))
          .length;
    });
