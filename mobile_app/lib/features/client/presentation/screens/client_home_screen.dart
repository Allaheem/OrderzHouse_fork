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

/// Premium Client Home Dashboard
/// Data sources:
/// - User info: authStateProvider
/// - Projects: myProjectsProvider (for counts and workspace)
/// - Latest projects: latestProjectsProvider (for inspiration)
/// - Workspace: workspaceItemsProvider (filtered, max 5)
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProjectsAsync = ref.watch(myProjectsProvider);
    final latestProjectsAsync = ref.watch(latestProjectsProvider);
    final workspaceAsync = ref.watch(workspaceItemsProvider);
    final selectedTab = ref.watch(workspaceTabProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProjectsProvider);
          ref.invalidate(latestProjectsProvider);
          ref.invalidate(workspaceInProgressProjectsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // A) TOP HEADER
              const HomeHeader(roleRoute: '/client'),

              const SizedBox(height: AppSpacing.xl),

              // B) HERO ACTION CARD
              _buildHeroCard(context, ref, myProjectsAsync, l10n),

              const SizedBox(height: AppSpacing.xl),

              // D) QUICK ACTIONS ROW
              _buildQuickActions(context, l10n),

              const SizedBox(height: AppSpacing.xl),

              // F) MAIN LIST SECTION: Your Workspace
              SectionTitleRow(
                title: l10n.yourWorkspace,
                onSeeAllTap: () {
                  context.go('/client/projects');
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

              // G) INSPIRATION SECTION
              SectionTitleRow(
                title: l10n.getInspired,
                onSeeAllTap: () {
                  context.go('/client/explore');
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _buildInspirationProjects(
                context,
                ref,
                latestProjectsAsync,
                l10n,
              ),

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
            route: '/client',
          ),
          NavItem(
            icon: Icons.work_outline,
            title: l10n.myProjects,
            route: '/client/projects',
          ),
          NavItem(
            icon: Icons.explore_outlined,
            title: l10n.explore,
            route: '/client/explore',
          ),
          NavItem(
            icon: Icons.payments_outlined,
            title: l10n.payments,
            route: '/client/payments',
          ),
          NavItem(
            icon: Icons.person_outline,
            title: l10n.profile,
            route: '/client/profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Project>> myProjectsAsync,
    AppLocalizations l10n,
  ) {
    return HomeHeroCardV2(
      chipLabel: l10n.actionRequired,
      iconData: Icons.work_outline_rounded,
      onIconTap: () {
        context.go('/client/projects');
      },
      title: l10n.manageProjects,
      subtitle: l10n.viewProjects,
      ctaLabel: l10n.postProject,
      ctaIcon: Icons.add_rounded,
      onCtaTap: () {
        context.go('/create-project');
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return QuickActionsRow(
      actions: [
        QuickAction(
          icon: Icons.add_circle_outline_rounded,
          label: l10n.postProject,
          onTap: () {
            context.go('/create-project');
          },
        ),
        QuickAction(
          icon: Icons.work_outline_rounded,
          label: l10n.projects,
          onTap: () {
            context.go('/client/projects');
          },
        ),
        QuickAction(
          icon: Icons.people_outline_rounded,
          label: l10n.applicants,
          onTap: () {
            context.go('/client/projects');
          },
        ),
        QuickAction(
          icon: Icons.payment_outlined,
          label: l10n.payments,
          onTap: () {
            context.go('/client/payments');
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
                  Icons.explore_outlined,
                  color: AppColors.accentOrange,
                ),
                title: Text(l10n.explore),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/client/explore');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.accentOrange,
                ),
                title: Text(l10n.notifications),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/client/notifications');
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
      error: (err, stack) => _buildErrorState(context, ref, 'workspace', l10n),
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

  Widget _buildInspirationProjects(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Project>> projectsAsync,
    AppLocalizations l10n,
  ) {
    return projectsAsync.when(
      loading: () => _buildLoadingSkeleton(context),
      error: (err, stack) => _buildErrorState(context, ref, 'latest', l10n),
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

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String providerKey,
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
                if (providerKey == 'workspace') {
                  ref.invalidate(myProjectsProvider);
                  ref.invalidate(workspaceInProgressProjectsProvider);
                } else {
                  ref.invalidate(latestProjectsProvider);
                }
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
              label: l10n.postProject,
              onTap: () => context.go('/create-project'),
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

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              size: 48,
              color: AppColors.iconGray,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.getInspired,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
