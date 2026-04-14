// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/home_header.dart';
import '../../../../core/widgets/home_hero_card_v2.dart';
import '../../../../core/widgets/quick_actions_row.dart';
import '../../../../core/widgets/home_project_card.dart';
import '../../../../core/widgets/section_title_row.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../../core/models/project.dart';
import '../../../common/presentation/screens/payments_screen.dart';

/// Premium Freelancer Home Dashboard
/// Data sources:
/// - User info: authStateProvider
/// - Projects: myProjectsProvider (for counts), exploreProjectsProvider (for recommendations)
/// - Latest projects: latestProjectsProvider
/// - Balance: balanceFromHistoryProvider (from payments history API)
class FreelancerHomeScreen extends ConsumerWidget {
  const FreelancerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProjectsAsync = ref.watch(myProjectsProvider);
    final latestProjectsAsync = ref.watch(latestProjectsProvider);
    final balanceAsync = ref.watch(balanceFromHistoryProvider);
    final workspaceAsync = ref.watch(workspaceItemsProvider);
    final selectedTab = ref.watch(workspaceTabProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProjectsProvider);
          ref.invalidate(latestProjectsProvider);
          ref.invalidate(balanceFromHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // A) TOP HEADER
              const HomeHeader(roleRoute: '/freelancer'),

              const SizedBox(height: AppSpacing.xl),

              // B) HERO ACTION CARD
              _buildHeroCard(context, ref, myProjectsAsync, balanceAsync, l10n),

              const SizedBox(height: AppSpacing.xl),

              // D) QUICK ACTIONS ROW
              _buildQuickActions(context, l10n),

              const SizedBox(height: AppSpacing.xl),

              // E) YOUR WORKSPACE SECTION
              SectionTitleRow(
                title: l10n.yourWorkspace,
                onSeeAllTap: () {
                  context.go('/freelancer/projects');
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Tabs: Action Required / Active
              _buildWorkspaceTabs(context, ref, selectedTab, l10n),

              const SizedBox(height: AppSpacing.md),

              _buildWorkspaceContent(
                context,
                ref,
                workspaceAsync,
                selectedTab,
                l10n,
              ),

              const SizedBox(height: AppSpacing.xl),

              // F) MAIN LIST SECTION: Recommended Projects
              SectionTitleRow(
                title: l10n.recommendedProjects,
                onSeeAllTap: () {
                  context.go('/freelancer/explore');
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _buildRecommendedProjects(context, latestProjectsAsync, l10n),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        items: [
          NavItem(
            icon: Icons.home_outlined,
            title: l10n.home,
            route: '/freelancer',
          ),
          NavItem(
            icon: Icons.work_outline,
            title: l10n.myProjects,
            route: '/freelancer/projects',
          ),
          NavItem(
            icon: Icons.explore_outlined,
            title: l10n.explore,
            route: '/freelancer/explore',
          ),
          NavItem(
            icon: Icons.payments_outlined,
            title: l10n.payments,
            route: '/freelancer/payments',
          ),
          NavItem(
            icon: Icons.person_outline,
            title: l10n.profile,
            route: '/freelancer/profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Project>> myProjectsAsync,
    AsyncValue<Map<String, dynamic>> balanceAsync,
    AppLocalizations l10n,
  ) {
    // Get balance and currency from payment history
    final balanceData = balanceAsync.when(
      data: (data) => data,
      loading: () => {'balance': 0.0, 'currency': 'JOD'},
      error: (_, _) => {'balance': 0.0, 'currency': 'JOD'},
    );
    final balance = balanceData['balance'] as double;
    final currency = balanceData['currency'] as String;

    return HomeHeroCardV2(
      chipLabel: l10n.balance,
      iconData: Icons.account_balance_wallet_outlined,
      onIconTap: () {
        context.go('/freelancer/payments');
      },
      title: l10n.yourBalance,
      bigNumber: '$currency ${balance.toStringAsFixed(2)}',
      subtitle: l10n.availableToWithdraw,
      ctaLabel: l10n.viewEarnings,
      onCtaTap: () {
        context.go('/freelancer/payments');
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return QuickActionsRow(
      actions: [
        QuickAction(
          icon: Icons.search_rounded,
          label: l10n.browseProjects,
          onTap: () {
            context.go('/freelancer/explore');
          },
        ),
        QuickAction(
          icon: Icons.payment_outlined,
          label: l10n.payments,
          onTap: () {
            context.go('/freelancer/payments');
          },
        ),
        QuickAction(
          icon: Icons.description_outlined,
          label: l10n.applicants,
          onTap: () {
            context.go('/freelancer/projects');
          },
        ),
        QuickAction(
          icon: Icons.file_upload_outlined,
          label: l10n.deliveries,
          onTap: () {
            context.go('/freelancer/projects');
          },
        ),
        QuickAction(
          icon: Icons.more_horiz_rounded,
          label: 'More',
          onTap: () {
            _showMoreBottomSheet(context, l10n);
          },
        ),
      ],
    );
  }

  void _showMoreBottomSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'More Actions',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.accentOrange,
                ),
                title: Text(l10n.notifications),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/freelancer/notifications');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.accentOrange,
                ),
                title: Text(l10n.settings),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceTabs(
    BuildContext context,
    WidgetRef ref,
    WorkspaceTab selectedTab,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _buildTabChip(
            context,
            ref,
            l10n.actionRequired,
            WorkspaceTab.actionRequired,
            selectedTab,
          ),
          const SizedBox(width: AppSpacing.md),
          _buildTabChip(
            context,
            ref,
            l10n.active,
            WorkspaceTab.active,
            selectedTab,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    WorkspaceTab tab,
    WorkspaceTab selectedTab,
  ) {
    final isSelected = selectedTab == tab;
    return GestureDetector(
      onTap: () {
        ref.read(workspaceTabProvider.notifier).state = tab;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Project>> workspaceAsync,
    WorkspaceTab selectedTab,
    AppLocalizations l10n,
  ) {
    return workspaceAsync.when(
      loading: () => _buildLoadingSkeleton(context),
      error: (err, stack) => _buildWorkspaceErrorState(context, ref, l10n),
      data: (projects) {
        if (projects.isEmpty) {
          return _buildEmptyWorkspace(context, selectedTab, l10n);
        }

        return SizedBox(
          height: AppContentLayout.homeHorizontalRailHeight(context),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: projects.length, // Already limited to 5 by provider
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final project = projects[index];
              return HomeProjectCard(
                project: project,
                onTap: () {
                  context.push('/project/${project.id}', extra: project);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceErrorState(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.failedToLoad,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(myProjectsProvider);
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWorkspace(
    BuildContext context,
    WorkspaceTab selectedTab,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 48,
              color: AppColors.iconGray,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              selectedTab == WorkspaceTab.actionRequired
                  ? l10n.noActionsRequired
                  : l10n.noActiveProjects,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGradientButton(
              label: l10n.browseProjects,
              onTap: () => context.go('/freelancer/explore'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientEnd.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedProjects(
    BuildContext context,
    AsyncValue<List<Project>> projectsAsync,
    AppLocalizations l10n,
  ) {
    return projectsAsync.when(
      loading: () => _buildLoadingSkeleton(context),
      error: (err, stack) => _buildErrorState(context, l10n),
      data: (projects) {
        if (projects.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        return SizedBox(
          height: AppContentLayout.homeHorizontalRailHeight(context),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final project = projects[index];
              return HomeProjectCard(
                project: project,
                onTap: () {
                  context.push('/project/${project.id}', extra: project);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return SizedBox(
      height: AppContentLayout.homeHorizontalRailHeight(context),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return Container(
            width: AppContentLayout.homeProjectCardWidth(context),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.failedToLoad,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    ref.invalidate(latestProjectsProvider);
                  },
                  child: Text(l10n.retry),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 48,
              color: AppColors.iconGray,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noDataFound,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                context.go('/freelancer/explore');
              },
              child: Text(l10n.explore),
            ),
          ],
        ),
      ),
    );
  }
}
