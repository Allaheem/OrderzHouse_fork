// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../messages/presentation/providers/blocked_users_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    WidgetRef ref,
    int userId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unblockUserConfirmTitle),
        content: Text(l10n.unblockUserConfirmBody),
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
    if (ok != true || !context.mounted) return;
    final done = await ref.read(blockedUsersProvider.notifier).unblock(userId);
    if (!context.mounted) return;
    if (done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userUnblockedSnackbar)),
      );
    } else {
      final err = ref.read(blockedUsersProvider).lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? l10n.somethingWentWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                AppHeader(
                  title: l10n.blockedPeople,
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: !blocked.isReady
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentOrange,
                            ),
                          ),
                        )
                      : blocked.entries.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  l10n.noBlockedUsers,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          itemCount: blocked.entries.length + 1,
                          itemBuilder: (context, index) {
                            if (index == blocked.entries.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.lg),
                                child: Text(
                                  l10n.blockedPeopleFooter,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }
                            final e = blocked.entries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.borderLight),
                              ),
                              child: ListTile(
                                title: Text(
                                  e.displayName,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${e.userId}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                trailing: TextButton(
                                  onPressed: () =>
                                      _confirmUnblock(context, ref, e.userId),
                                  child: Text(l10n.unblockUser),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
