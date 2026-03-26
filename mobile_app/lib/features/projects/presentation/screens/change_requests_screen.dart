// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../data/models/change_request_model.dart';
import '../../data/change_requests_last_seen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/change_requests_provider.dart';
import '../providers/projects_provider.dart';

class ChangeRequestsScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectTitle;

  const ChangeRequestsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  ConsumerState<ChangeRequestsScreen> createState() =>
      _ChangeRequestsScreenState();
}

class _ChangeRequestsScreenState extends ConsumerState<ChangeRequestsScreen> {
  bool _hasInvalidated = false;
  bool _hasMarkedAsRead = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasInvalidated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(changeRequestsProvider(widget.projectId));
        _hasInvalidated = true;
      });
    }

    // Mark as read when screen opens: set lastSeenAt (optimistic), then invalidate so badge + "New" update
    if (!_hasMarkedAsRead) {
      _hasMarkedAsRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userId = ref.read(authStateProvider).user?.id;
        if (userId != null) {
          final now = DateTime.now();
          await ChangeRequestsLastSeen.setLastSeen(
            userId,
            widget.projectId,
            now,
          );
          ref
              .read(projectsRepositoryProvider)
              .markChangeRequestsRead(widget.projectId, lastSeenAt: now);
          ref.invalidate(changeRequestsLastSeenProvider(widget.projectId));
          ref.invalidate(changeRequestsUnreadCountProvider(widget.projectId));
          ref.invalidate(changeRequestsProvider(widget.projectId));
        }
      });
    }

    final changeRequestsAsync = ref.watch(
      changeRequestsProvider(widget.projectId),
    );
    final lastSeenAsync = ref.watch(
      changeRequestsLastSeenProvider(widget.projectId),
    );
    final lastSeenAt = lastSeenAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.accentOrange,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/freelancer');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Requests',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.projectTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.projectTitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Change requests list
          Expanded(
            child: changeRequestsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentOrange,
                  ),
                ),
              ),
              error: (error, stackTrace) => ErrorState(
                message: error.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(changeRequestsProvider(widget.projectId)),
              ),
              data: (changeRequests) {
                if (changeRequests.isEmpty) {
                  return const EmptyState(
                    icon: Icons.edit_note_rounded,
                    title: 'No change requests yet',
                    message:
                        'No change requests have been sent for this project.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: changeRequests.length,
                  itemBuilder: (context, index) {
                    final request = changeRequests[index];
                    final isUnread =
                        lastSeenAt == null ||
                        request.createdAt.isAfter(lastSeenAt);
                    return _buildChangeRequestCard(request, isUnread: isUnread);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRequestCard(
    ChangeRequest request, {
    required bool isUnread,
  }) {
    final showNewChip = request.isResolved != true && isUnread;
    final showResolvedChip = request.isResolved == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge: "New" only when unread; "Resolved" when resolved
                    if (showNewChip || showResolvedChip) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: showResolvedChip
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          showResolvedChip ? 'Resolved' : 'New',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: showResolvedChip
                                ? AppColors.success
                                : AppColors.accentOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Message text
                    Text(
                      request.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timestamp
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                request.formattedTime,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
