// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Settings state providers
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final twoFactorEnabledProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final hx = AppContentLayout.bodyHorizontalPadding(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom + AppSpacing.xl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hx, AppSpacing.md, hx, bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          // Back button in circle
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowColorLight,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              color: AppColors.textPrimary,
                              onPressed: () {
                                // Safe back navigation
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  // Fallback: navigate to profile/home based on role
                                  final userRoleId = user?.roleId ?? 0;
                                  if (userRoleId == 2) {
                                    context.go('/client/profile');
                                  } else if (userRoleId == 3) {
                                    context.go('/freelancer/profile');
                                  } else {
                                    context.go('/client/profile');
                                  }
                                }
                              },
                            ),
                          ),
                          const Spacer(),
                          // Title
                          Text(
                            l10n.settings,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40), // Balance the back button
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Settings Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColorLight,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Language Setting
                          _buildSettingTile(
                            context: context,
                            icon: Icons.language_rounded,
                            title: l10n.language,
                            subtitle: currentLocale.languageCode == 'ar'
                                ? 'العربية'
                                : 'English',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/settings/language');
                            },
                          ),

                          // Divider
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderLight,
                            indent: 72,
                          ),

                          // Notifications Setting
                          _buildSettingTile(
                            context: context,
                            icon: Icons.notifications_outlined,
                            title: l10n.notifications,
                            subtitle: l10n.notificationsSubtitle,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/settings/notifications');
                            },
                          ),

                          // Divider
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderLight,
                            indent: 72,
                          ),

                          // Security Center — مخفي حسب الطلب
                          // _buildSettingTile(
                          //   context: context,
                          //   icon: Icons.security_outlined,
                          //   title: l10n.security,
                          //   subtitle: l10n.securitySubtitle,
                          //   trailing: const Icon(
                          //     Icons.chevron_right_rounded,
                          //     color: AppColors.iconGray,
                          //     size: 24,
                          //   ),
                          //   onTap: () {
                          //     context.push('/settings/security');
                          //   },
                          // ),
                          // const Divider(
                          //   height: 1,
                          //   thickness: 1,
                          //   color: AppColors.borderLight,
                          //   indent: 72,
                          // ),

                          // Change Password Setting
                          _buildSettingTile(
                            context: context,
                            icon: Icons.lock_outline_rounded,
                            title: l10n.changePassword,
                            subtitle: l10n.changePasswordSubtitle,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/change-password');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Legal & Help Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColorLight,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            context: context,
                            icon: Icons.privacy_tip_outlined,
                            title: l10n.privacyPolicy,
                            subtitle: null,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/privacy-policy');
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderLight,
                            indent: 72,
                          ),
                          _buildSettingTile(
                            context: context,
                            icon: Icons.description_outlined,
                            title: l10n.termsAndConditions,
                            subtitle: null,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/terms-conditions');
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderLight,
                            indent: 72,
                          ),
                          _buildSettingTile(
                            context: context,
                            icon: Icons.help_outline_rounded,
                            title: l10n.helpFaq,
                            subtitle: null,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/help-faq');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Account & Security Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColorLight,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            context: context,
                            icon: Icons.folder_outlined,
                            title: l10n.myContent,
                            subtitle: l10n.myContentSubtitle,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/settings/my-content');
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade200,
                            indent: 72,
                          ),
                          _buildSettingTile(
                            context: context,
                            icon: Icons.help_outline_rounded,
                            title: l10n.support,
                            subtitle: l10n.supportSubtitle,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/support');
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade200,
                            indent: 72,
                          ),
                          _buildSettingTile(
                            context: context,
                            icon: Icons.delete_outline_rounded,
                            title: l10n.deleteAccount,
                            subtitle: l10n.deleteAccountSubtitle,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.iconGray,
                              size: 24,
                            ),
                            onTap: () {
                              context.push('/settings/delete-account');
                            },
                            isDeleteAccount: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    bool isDeleteAccount = false,
  }) {
    final isDelete = isDeleteAccount || title.toLowerCase().contains('delete');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon in soft circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDelete
                    ? AppColors.error.withOpacity(0.12)
                    : AppColors.gradientStart.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Icon(
                icon,
                color: isDelete ? AppColors.error : AppColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing widget (Switch or Chevron)
            trailing,
          ],
        ),
      ),
    );
  }
}
