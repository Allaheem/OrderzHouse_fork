import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/home_header.dart';

/// Minimal home for staff (role_id = 1). Project management APIs are client/freelancer-only.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        children: [
          const HomeHeader(roleRoute: '/admin'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.adminMobileHomeTitle,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.adminMobileHomeBody,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => context.go('/admin/explore'),
            icon: const Icon(Icons.explore_outlined),
            label: Text(l10n.explore),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        items: [
          NavItem(
            icon: Icons.home_outlined,
            title: l10n.home,
            route: '/admin',
          ),
          NavItem(
            icon: Icons.explore_outlined,
            title: l10n.explore,
            route: '/admin/explore',
          ),
          NavItem(
            icon: Icons.payments_outlined,
            title: l10n.payments,
            route: '/admin/payments',
          ),
          NavItem(
            icon: Icons.person_outline,
            title: l10n.profile,
            route: '/admin/profile',
          ),
        ],
      ),
    );
  }
}
