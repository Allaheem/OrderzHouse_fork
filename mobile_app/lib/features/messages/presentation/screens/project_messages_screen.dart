// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../data/models/message_model.dart';
import '../providers/messages_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProjectMessagesScreen extends ConsumerStatefulWidget {
  final int projectId;

  const ProjectMessagesScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectMessagesScreen> createState() =>
      _ProjectMessagesScreenState();
}

class _ProjectMessagesScreenState extends ConsumerState<ProjectMessagesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasInvalidated = false;
  bool _hasMarkedAsRead = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Invalidate provider when screen opens to ensure fresh data (only once)
    if (!_hasInvalidated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(projectMessagesProvider(widget.projectId));
        _hasInvalidated = true;
      });
    }
    // Mark project messages as read when screen opens so red dot disappears immediately
    if (!_hasMarkedAsRead) {
      _hasMarkedAsRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(projectUnreadControllerProvider).markAsRead(widget.projectId);
      });
    }

    final messagesAsync = ref.watch(projectMessagesProvider(widget.projectId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;

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
                        context.go('/client');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      'Messages',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Messages list
          Expanded(
            child: messagesAsync.when(
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
                    ref.invalidate(projectMessagesProvider(widget.projectId)),
              ),
              data: (messages) {
                print(
                  '📱 [ProjectMessagesScreen] Received ${messages.length} messages',
                );

                // Handle empty list safely
                if (messages.isEmpty) {
                  print(
                    'ℹ️ [ProjectMessagesScreen] Messages list is empty, showing empty state',
                  );
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    message: 'No messages have been sent for this project.',
                  );
                }

                print(
                  '✅ [ProjectMessagesScreen] Displaying ${messages.length} messages',
                );

                // Scroll to bottom when messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser =
                        currentUserId != null &&
                        message.senderId == currentUserId;
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    final senderName = message.sender?.fullName ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            // Avatar (only for other user)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: message.sender?.avatar != null
                  ? NetworkImage(message.sender!.avatar!)
                  : null,
              child: message.sender?.avatar == null
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.accentOrange
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                ),
                border: isCurrentUser
                    ? null
                    : Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser) ...[
                    Text(
                      senderName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isCurrentUser
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isCurrentUser
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.formattedTime,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar (only for current user)
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(
                Icons.person_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
