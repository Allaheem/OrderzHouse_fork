// ??? ????????
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/project.dart';
import '../../../../core/models/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/gradient_fab.dart';
import '../../../../shared/widgets/app_gradient_filter_chip.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../common/presentation/providers/my_projects_filters_provider.dart';
import '../../../common/presentation/widgets/projects_filter_bottom_sheet.dart';
import '../widgets/client_project_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';

class ClientProjectsScreen extends ConsumerStatefulWidget {
  const ClientProjectsScreen({super.key});

  @override
  ConsumerState<ClientProjectsScreen> createState() =>
      _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends ConsumerState<ClientProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Store raw project data for additional fields (for future use if needed)
  final Map<int, Map<String, dynamic>> _projectDataMap = {};
  bool _isFetchingRawData = false;
  bool _hasFetchedRawData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentQuery = ref.read(myProjectsSearchQueryProvider);
        if (currentQuery.isNotEmpty && _searchController.text != currentQuery) {
          _searchController.text = currentQuery;
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch and store raw project data (only once per data load)
  Future<void> _fetchRawProjectDataForProjects(List<Project> projects) async {
    // Prevent multiple simultaneous calls and avoid retry loop on 403/error
    if (_isFetchingRawData || _hasFetchedRawData) {
      return;
    }

    _isFetchingRawData = true;

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getMyProjectsRaw();

      if (response.success && response.data != null && mounted) {
        setState(() {
          for (var rawProject in response.data!) {
            final projectId = rawProject['id'] as int?;
            if (projectId != null) {
              _projectDataMap[projectId] = rawProject;
            }
          }
        });
      }
    } catch (e) {
      // Silently fail - do not retry on every rebuild
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRawData = false;
          // Mark as attempted so we don't retry in a loop on 403/error until user refreshes
          _hasFetchedRawData = true;
        });
      }
    }
  }

  // Reset raw data fetch flag when refreshing
  void _onRefresh() {
    setState(() {
      _hasFetchedRawData = false;
    });
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentSort = ref.read(myProjectsFiltersProvider).sort;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sortBy,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SortOption(
              label: l10n.newestFirst,
              value: 'newest',
              isSelected: currentSort == 'newest',
              onTap: () {
                ref.read(myProjectsFiltersProvider.notifier).setSort('newest');
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: l10n.priceLowToHigh,
              value: 'budget_low_to_high',
              isSelected: currentSort == 'budget_low_to_high',
              onTap: () {
                ref
                    .read(myProjectsFiltersProvider.notifier)
                    .setSort('budget_low_to_high');
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: l10n.priceHighToLow,
              value: 'budget_high_to_low',
              isSelected: currentSort == 'budget_high_to_low',
              onTap: () {
                ref
                    .read(myProjectsFiltersProvider.notifier)
                    .setSort('budget_high_to_low');
                Navigator.pop(context);
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
    final filteredAsync = ref.watch(filteredMyProjectsProvider);
    final projectsAsync = ref.watch(myProjectsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final selectedStatus = ref.watch(myProjectsStatusProvider);

    final statuses =
        projectsAsync.value?.map((p) => p.status).toSet().toList() ?? [];
    final allStatuses = [l10n.all, ...statuses];

    final safe = MediaQuery.of(context).padding.bottom;
    final contentBottomPadding = safe + 80.0;

    return AppScaffold(
      body: Column(
        children: [
          // 1) Top Bar
          _buildTopBar(context, user),

          // 2) Search + Actions Row
          _buildSearchRow(context, ref),

          // 3) Category Chips Row
          _buildCategoryChips(context, allStatuses, selectedStatus),

          // 4) Projects Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _onRefresh();
                ref.invalidate(myProjectsProvider);
                await ref.read(myProjectsProvider.future);
              },
              child: filteredAsync.when(
                data: (filteredProjects) {
                  _fetchRawProjectDataForProjects(
                    projectsAsync.value ?? filteredProjects,
                  );
                  final hasFilters =
                      ref
                          .read(myProjectsSearchQueryProvider)
                          .trim()
                          .isNotEmpty ||
                      ref.read(myProjectsStatusProvider) != null;
                  if (filteredProjects.isEmpty) {
                    return EmptyState(
                      icon: Icons.work_outline,
                      title: hasFilters ? l10n.noResultsFound : l10n.noProjects,
                      message: hasFilters
                          ? l10n.noResultsFound
                          : l10n.noProjectsMessage,
                    );
                  }
                  return _buildProjectsGrid(
                    context,
                    filteredProjects,
                    bottomPadding: contentBottomPadding,
                  );
                },
                loading: () =>
                    _LoadingGrid(bottomPadding: contentBottomPadding),
                error: (error, stackTrace) => ErrorState(
                  message: error.toString().replaceAll('Exception: ', ''),
                  onRetry: () {
                    ref.invalidate(myProjectsProvider);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GradientFab(onPressed: () => context.go('/create-project')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
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

  // 1) Top Bar (matching Explore style)
  Widget _buildTopBar(BuildContext context, User? user) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Back arrow in white circle button
            if (context.canPop())
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF111827), // Black
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 40), // Spacer if no back button
            // Center: Title
            Text(
              l10n.myProjects,
              style: AppTextStyles.headlineMedium.copyWith(
                color: const Color(0xFF111827), // Black
                fontWeight: FontWeight.bold,
              ),
            ),

            // Right: Avatar
            GestureDetector(
              onTap: () {
                context.go('/client/profile');
              },
              child:
                  user?.profilePicUrl != null && user!.profilePicUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.profilePicUrl!.startsWith('http')
                            ? user.profilePicUrl!
                            : '${AppConfig.baseUrl}${user.profilePicUrl}',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildAvatarPlaceholder(),
                      ),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E7EB), // Light gray
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF6B7280), // Gray icon
        size: 24,
      ),
    );
  }

  // 2) Search + Actions Row (debounced search, filter sheet, sort dialog - same as Explore)
  Widget _buildSearchRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      ref.read(myProjectsSearchQueryProvider.notifier).state =
                          value;
                    }
                  });
                },
                onSubmitted: (value) {
                  _debounceTimer?.cancel();
                  ref.read(myProjectsSearchQueryProvider.notifier).state =
                      value;
                },
                decoration: InputDecoration(
                  hintText: l10n.searchProjects,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF111827),
                size: 20,
              ),
              onPressed: () => showProjectsFilterBottomSheet(
                context,
                ProjectsFilterTarget.myProjects,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.swap_vert_rounded,
                color: Color(0xFF111827),
                size: 20,
              ),
              onPressed: () => _showSortDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // 3) Category Chips Row (status filter - same pattern as Explore)
  Widget _buildCategoryChips(
    BuildContext context,
    List<String> statuses,
    String? selectedStatus,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: statuses.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isAll = status == l10n.all;
          final isSelected = isAll
              ? selectedStatus == null
              : selectedStatus == status;

          return AppGradientFilterChip(
            label: status,
            selected: isSelected,
            onTap: () {
              ref.read(myProjectsStatusProvider.notifier).state = isAll
                  ? null
                  : status;
            },
          );
        },
      ),
    );
  }

  // 4) Projects Grid (responsive columns + aspect — avoids sky-tall cards on iPad)
  Widget _buildProjectsGrid(
    BuildContext context,
    List<Project> projects, {
    double bottomPadding = 0,
  }) {
    final crossAxisCount = AppContentLayout.myProjectsCrossAxisCount(context);
    final aspectRatio =
        AppContentLayout.myProjectsGridChildAspectRatio(context, crossAxisCount);
    return GridView.builder(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: bottomPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: aspectRatio,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ClientProjectCard(
          project: project,
          projectData: _projectDataMap[project.id],
          onTap: () {
            context.push('/project/${project.id}', extra: project);
          },
        );
      },
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

// Loading Grid
class _LoadingGrid extends StatelessWidget {
  final double bottomPadding;

  const _LoadingGrid({this.bottomPadding = 0});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = AppContentLayout.myProjectsCrossAxisCount(context);
    final aspectRatio =
        AppContentLayout.myProjectsGridChildAspectRatio(context, crossAxisCount);
    return GridView.builder(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: bottomPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: aspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              16,
            ), // Matching Explore card radius
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingShimmer(
                height: 120, // Matching Explore card image height
                width: double.infinity,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12), // Matching Explore card padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer(width: 120, height: 16),
                    SizedBox(height: 6),
                    LoadingShimmer(width: 100, height: 12),
                    SizedBox(height: 6),
                    LoadingShimmer(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
