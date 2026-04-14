// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/gradient_button.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:OrderzHouse/core/models/user.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isFreelancer = user?.roleId == 3;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            // Without this, [Column] stays only as wide as its children and looks
            // "phone-narrow" centered on iPad despite a large [maxWidth].
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Standard AppBar/Header (like My Projects)
                  _ProfileTopBar(l10n: l10n),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: AppSpacing.md,
                        left: AppContentLayout.bodyHorizontalPadding(context),
                        right: AppContentLayout.bodyHorizontalPadding(context),
                        bottom:
                            MediaQuery.paddingOf(context).bottom +
                            AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1–2) Header + stats (grouped card on tablet, like home density)
                          _ProfileIdentityBlock(user: user, l10n: l10n),
                          const SizedBox(height: AppSpacing.xl),

                          // 3) Settings List Card (original items)
                          _SettingsListCard(
                            onEditProfile: () => context.go('/edit-profile'),
                            onSettings: () => context.go('/settings'),
                            onSubscription: () => context.go('/subscription'),
                            showSubscription: isFreelancer,
                            l10n: l10n,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 3.5) Help & Legal List Card
                          _HelpLegalListCard(
                            onHelp: () => context.push('/help-faq'),
                            onPrivacy: () => context.push('/privacy-policy'),
                            onTerms: () => context.push('/terms-conditions'),
                            l10n: l10n,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 4) Logout Card (separate card, red accent)
                          _LogoutCard(
                            l10n: l10n,
                            onLogout: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n.logoutConfirmTitle),
                                  content: Text(l10n.logoutConfirmMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(l10n.logout),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                await ref
                                    .read(authStateProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 5) Bottom CTA Card — freelancers only
                          if (isFreelancer)
                            _UpgradeCard(
                              onViewPlans: () => context.go('/subscription'),
                              l10n: l10n,
                            ),

                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Standard Top Bar (matching My Projects style)
class _ProfileTopBar extends StatelessWidget {
  final AppLocalizations l10n;

  const _ProfileTopBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final hx = AppContentLayout.bodyHorizontalPadding(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hx, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back arrow in white circle button
          if (context.canPop())
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColorLight,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.accentOrange,
                  size: 20,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                padding: EdgeInsets.zero,
              ),
            )
          else
            const SizedBox(width: 40), // Spacer if no back button
          // Center: Title
          Text(
            l10n.profile,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Right: Spacer (no avatar button since we're on Profile page)
          const SizedBox(width: 40), // Balance the left button
        ],
      ),
    );
  }
}

/// Avatar + stats: on iPad/tablet, one surface card matches home “filled” sections.
class _ProfileIdentityBlock extends ConsumerWidget {
  final User? user;
  final AppLocalizations l10n;

  const _ProfileIdentityBlock({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: AppSpacing.lg),
        _StatsRow(l10n: l10n),
      ],
    );
    if (!AppContentLayout.useFullWidthBody(context)) {
      return inner;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: inner,
    );
  }
}

// 1) Top Profile Header
class _ProfileHeader extends StatelessWidget {
  final User? user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Circular Avatar
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentOrange.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: ClipOval(
            child:
                user?.profilePicUrl != null && user!.profilePicUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: user!.profilePicUrl!.startsWith('http')
                        ? user!.profilePicUrl!
                        : '${AppConfig.baseUrl}${user!.profilePicUrl}',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(width: 16),
        // Right: Name, Username, Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name (bold)
              Text(
                user?.displayName ?? 'User Name',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Username/handle (smaller, gray)
              Text(
                '@${user?.username ?? 'username'}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                user?.email ?? 'info@battechno.com',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 40,
      ),
    );
  }
}

// 2) Stats Row - Dynamic stats from user's projects
class _StatsRow extends ConsumerWidget {
  final AppLocalizations l10n;

  const _StatsRow({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);

    return statsAsync.when(
      data: (stats) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(number: stats.total.toString(), label: l10n.projects),
          _StatItem(number: stats.completed.toString(), label: l10n.completed),
          _StatItem(number: stats.active.toString(), label: l10n.active),
        ],
      ),
      loading: () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(number: '—', label: l10n.projects),
          _StatItem(number: '—', label: l10n.completed),
          _StatItem(number: '—', label: l10n.active),
        ],
      ),
      error: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(number: '—', label: l10n.projects),
          _StatItem(number: '—', label: l10n.completed),
          _StatItem(number: '—', label: l10n.active),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// 3) Settings List Card (original items: Edit Profile, Settings, Subscription)
class _SettingsListCard extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback onSubscription;
  final bool showSubscription;
  final AppLocalizations l10n;

  const _SettingsListCard({
    required this.onEditProfile,
    required this.onSettings,
    required this.onSubscription,
    required this.l10n,
    this.showSubscription = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsListItem(
            icon: Icons.edit_rounded,
            label: l10n.editProfile,
            onTap: onEditProfile,
          ),
          const _SettingsDivider(),
          _SettingsListItem(
            icon: Icons.settings_rounded,
            label: l10n.settings,
            onTap: onSettings,
          ),
          if (showSubscription) ...[
            const _SettingsDivider(),
            _SettingsListItem(
              icon: Icons.subscriptions_rounded,
              label: l10n.subscription,
              onTap: onSubscription,
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsListItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Left: Accent orange icon
            Icon(icon, color: AppColors.accentOrange, size: 22),
            const SizedBox(width: 16),
            // Middle: Label
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ),
            // Right: Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconGray,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 54, // Icon (22) + spacing (16) + padding (16) = 54
      color: AppColors.borderLight,
    );
  }
}

// Help & Legal List Card
class _HelpLegalListCard extends StatelessWidget {
  final VoidCallback onHelp;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final AppLocalizations l10n;

  const _HelpLegalListCard({
    required this.onHelp,
    required this.onPrivacy,
    required this.onTerms,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsListItem(
            icon: Icons.help_outline_rounded,
            label: l10n.helpFaq,
            onTap: onHelp,
          ),
          const _SettingsDivider(),
          _SettingsListItem(
            icon: Icons.privacy_tip_outlined,
            label: l10n.privacyPolicy,
            onTap: onPrivacy,
          ),
          const _SettingsDivider(),
          _SettingsListItem(
            icon: Icons.description_outlined,
            label: l10n.termsAndConditions,
            onTap: onTerms,
          ),
        ],
      ),
    );
  }
}

// 4) Logout Card (separate card, red accent)
class _LogoutCard extends StatelessWidget {
  final VoidCallback onLogout;
  final AppLocalizations l10n;

  const _LogoutCard({required this.onLogout, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onLogout,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Left: Red icon
              const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
              const SizedBox(width: 16),
              // Middle: Label (red)
              Expanded(
                child: Text(
                  l10n.logout,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
              // Right: Chevron (red)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5) Upgrade/Plans CTA Card (Full Width)
class _UpgradeCard extends StatelessWidget {
  final VoidCallback onViewPlans;
  final AppLocalizations l10n;

  const _UpgradeCard({required this.onViewPlans, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // ✅ Explicit full width
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // ✅ Align content to start
        children: [
          // Text
          Text(
            l10n.wantMoreFeatures,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600, // ✅ Slightly bolder
            ),
          ),
          const SizedBox(height: 16),
          PrimaryGradientButton(
            onPressed: onViewPlans,
            label: l10n.viewPlans,
            height: 56,
            borderRadius: 30,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
