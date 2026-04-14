// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/support_contact.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/message_model.dart';
import '../providers/blocked_users_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/moderation_repository_provider.dart';
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

  String _clip(String text, int max) {
    final t = text.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  void _showSafetySheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.projectChatSafetyTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.projectChatSafetyBody,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/terms-conditions');
                  },
                  child: Text(l10n.projectChatOpenTerms),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/support');
                  },
                  child: Text(l10n.projectChatOpenSupport),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reportMessage(Message message) async {
    final l10n = AppLocalizations.of(context)!;
    final noteController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reportMessageTitle),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.reportMessageHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
    final noteText = noteController.text;
    noteController.dispose();
    if (submitted != true || !mounted) return;

    final repo = ref.read(moderationRepositoryProvider);
    final apiRes = await repo.submitReport(
      projectId: widget.projectId,
      reportedUserId: message.senderId,
      messageId: message.id,
      messageExcerpt: _clip(message.content, 2000),
      note: _clip(noteText, 500),
    );
    if (apiRes.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportSubmittedToTeam)),
        );
      }
      return;
    }

    final subject =
        '[OrderzHouse] UGC report — project ${widget.projectId}, msg ${message.id}';
    final body = '''
Project ID: ${widget.projectId}
Message ID: ${message.id}
Reported user ID: ${message.senderId}
Reported user name: ${message.sender?.fullName ?? ''}

Message:
${_clip(message.content, 1200)}

Reporter note:
${_clip(noteText, 500)}

(API error: ${apiRes.message})
''';

    final uri = supportMailtoUri(subject: subject, body: body);
    if (await tryLaunchSupportMailto(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportMessageSent)),
        );
      }
    } else {
      await copySupportDraft(subject, body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.supportEmailDraftCopied)),
        );
      }
    }
  }

  Future<void> _blockUser(Message message) async {
    final l10n = AppLocalizations.of(context)!;
    if (message.senderId <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.blockUserConfirmTitle),
        content: Text(l10n.blockUserConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = message.sender?.fullName ?? '';
    final blocked = await ref.read(blockedUsersProvider.notifier).block(
          message.senderId,
          name,
          widget.projectId,
        );
    if (!mounted) return;
    if (blocked) {
      ref.invalidate(projectMessagesProvider(widget.projectId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlockedSnackbar)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.blockSubmitFailed)),
      );
    }
  }

  void _onOtherUserMessageLongPress(Message message) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.reportMessage),
              onTap: () {
                Navigator.pop(ctx);
                _reportMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.blockUser),
              onTap: () {
                Navigator.pop(ctx);
                _blockUser(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_hasInvalidated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(projectMessagesProvider(widget.projectId));
        _hasInvalidated = true;
      });
    }
    if (!_hasMarkedAsRead) {
      _hasMarkedAsRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(projectUnreadControllerProvider).markAsRead(widget.projectId);
      });
    }

    final messagesAsync = ref.watch(projectMessagesProvider(widget.projectId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;
    final blockedIds = ref.watch(blockedUsersProvider).ids;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
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
                      Expanded(
                        child: Text(
                          l10n.messages,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded),
                        color: AppColors.textSecondary,
                        onPressed: () => _showSafetySheet(context),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      l10n.projectChatHowToHint,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                if (messages.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l10n.projectChatEmptyTitle,
                    message: l10n.projectChatEmptyMessage,
                  );
                }

                final visible = messages.where((m) {
                  if (currentUserId == null) return true;
                  if (m.senderId == currentUserId) return true;
                  return !blockedIds.contains(m.senderId);
                }).toList();

                if (visible.isEmpty) {
                  return EmptyState(
                    icon: Icons.block,
                    title: l10n.projectChatBlockedTitle,
                    message: l10n.projectChatHiddenByBlocks,
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final message = visible[index];
                    final isCurrentUser =
                        currentUserId != null &&
                        message.senderId == currentUserId;
                    return _buildMessageBubble(
                      message,
                      isCurrentUser,
                      onLongPressOther: !isCurrentUser
                          ? () => _onOtherUserMessageLongPress(message)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isCurrentUser, {
    VoidCallback? onLongPressOther,
  }) {
    final senderName = message.sender?.fullName ?? 'Unknown';

    final bubble = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: message.sender?.avatar != null
                  ? NetworkImage(message.sender!.avatar!)
                  : null,
              child: message.sender?.avatar == null
                  ? Text(
                      senderName.isNotEmpty
                          ? senderName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
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

    if (onLongPressOther != null) {
      return GestureDetector(
        onLongPress: onLongPressOther,
        child: bubble,
      );
    }
    return bubble;
  }
}
