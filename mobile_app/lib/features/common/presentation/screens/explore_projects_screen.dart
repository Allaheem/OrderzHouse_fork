// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/project.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/search_result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/explore_project_card.dart';
import '../../../../core/widgets/explore_skeleton.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/gradient_fab.dart';
import '../../../../shared/widgets/app_gradient_filter_chip.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/favorite_project_ids_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../providers/explore_filters_provider.dart';
import '../widgets/projects_filter_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import 'dart:async';

class ExploreProjectsScreen extends ConsumerStatefulWidget {
  final bool readOnly;

  const ExploreProjectsScreen({super.key, this.readOnly = false});

  @override
  ConsumerState<ExploreProjectsScreen> createState() =>
      _ExploreProjectsScreenState();
}

class _ExploreProjectsScreenState extends ConsumerState<ExploreProjectsScreen> {
  final _searchController = TextEditingController();
  final _categoryScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _savedQueryApplied = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  bool _hasSyncedSharedCategory = false;

  @override
  void initState() {
    super.initState();
    // Sync search controller with provider on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentQuery = ref.read(searchQueryProvider);
        if (currentQuery.isNotEmpty && _searchController.text != currentQuery) {
          _searchController.text = currentQuery;
        }
      }
    });
  }

  void _refresh() {
    ref.read(exploreRefreshErrorProvider.notifier).state = null;
    ref.read(exploreProjectsStateProvider.notifier).load();
    ref.invalidate(exploreCategoriesProvider);
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final String currentSort = ref.read(exploreSortByProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Consumer(
          builder: (context, ref, _) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
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
                    ref.read(exploreSortByProvider.notifier).state = 'newest';
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  label: l10n.priceLowToHigh,
                  value: 'price_low_to_high',
                  isSelected: currentSort == 'price_low_to_high',
                  onTap: () {
                    ref.read(exploreSortByProvider.notifier).state =
                        'price_low_to_high';
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  label: l10n.priceHighToLow,
                  value: 'price_high_to_low',
                  isSelected: currentSort == 'price_high_to_low',
                  onTap: () {
                    ref.read(exploreSortByProvider.notifier).state =
                        'price_high_to_low';
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showProjectsFilterBottomSheet(context, ProjectsFilterTarget.explore);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_savedQueryApplied) {
      _savedQueryApplied = true;
      final saved = GoRouterState.of(context).uri.queryParameters['saved'];
      if (saved == '1') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(showSavedProjectsOnlyProvider.notifier).state = true;
          }
        });
      }
    }
    final searchQuery = ref.watch(searchQueryProvider);
    final categoriesAsync = ref.watch(exploreCategoriesProvider);
    final selectedCategoryId = ref.watch(selectedExploreCategoryIdProvider);
    final sharedCategoryId = ref.watch(exploreSelectedCategoryIdProvider);
    final String sortBy = ref.watch(exploreSortByProvider);

    // Sync shared provider to local provider on first build
    if (!_hasSyncedSharedCategory && sharedCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Set the local provider to match shared state
          ref.read(selectedExploreCategoryIdProvider.notifier).state =
              sharedCategoryId;
          // Clear shared state after syncing (so it doesn't persist on next visit)
          ref.read(exploreSelectedCategoryIdProvider.notifier).state = null;
          _hasSyncedSharedCategory = true;
        }
      });
    }

    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return AppScaffold(
      body: Column(
        children: [
          _buildTopRow(context, user),
          _buildSearchRow(context),
          Expanded(
            child: Column(
              children: [
                _buildCategoryChips(categoriesAsync, selectedCategoryId),
                _buildSavedOnlyChip(l10n),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.read(exploreRefreshErrorProvider.notifier).state =
                          null;
                      await ref
                          .read(exploreProjectsStateProvider.notifier)
                          .load();
                    },
                    child: Consumer(
                      builder: (context, ref, _) {
                        ref.listen(exploreRefreshErrorProvider, (prev, msg) {
                          if (msg != null && msg != prev && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            ref
                                    .read(exploreRefreshErrorProvider.notifier)
                                    .state =
                                null;
                          }
                        });
                        final lastData = ref.watch(
                          exploreProjectsLastDataProvider,
                        );
                        final projectsAsync = ref.watch(
                          filteredExploreProjectsProvider,
                        );
                        return _ExploreGridContent(
                          projectsAsync: projectsAsync,
                          lastData: lastData,
                          l10n: l10n,
                          selectedCategoryId: selectedCategoryId,
                          searchQuery: searchQuery,
                          onRetry: _refresh,
                          buildGrid: _buildProjectsGrid,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // 1) Top Row
  Widget _buildTopRow(BuildContext context, User? user) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Menu/Grid Icon Button (rounded square, like screenshot)
            // If Explore is opened from navigation stack, show back arrow
            // If Explore is a main bottom-nav tab, show menu/grid icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12), // Rounded square
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: context.canPop()
                    ? const Icon(Icons.chevron_left_rounded)
                    : const Icon(
                        Icons.grid_view_rounded,
                      ), // Menu/grid icon for main tab
                color: const Color(0xFF111827), // Near-black
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  // Guest/main explore: use this button as a quick filter entry point.
                  _showFilterBottomSheet(context, ref);
                },
              ),
            ),

            // Center: Title
            Text(
              l10n.explore,
              style: AppTextStyles.headlineMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
              ),
            ),

            // Right: Avatar
            GestureDetector(
              onTap: () {
                if (user == null) {
                  context.go('/login');
                  return;
                }
                final location = GoRouterState.of(context).uri.path;
                if (location.contains('/admin')) {
                  context.go('/admin/profile');
                } else if (location.contains('/client')) {
                  context.go('/client/profile');
                } else {
                  context.go('/freelancer/profile');
                }
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
        color: Color(0xFFE5E7EB), // Light gray background
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF6B7280), // Gray icon
        size: 24,
      ),
    );
  }

  // 2) Search + Actions Row
  Widget _buildSearchRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Search Field
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
                  // Debounce search input
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      // Update search query provider (provider watches this and will auto-refetch)
                      ref.read(searchQueryProvider.notifier).state = value;
                    }
                  });
                },
                onSubmitted: (value) {
                  // On submit, update immediately without debounce
                  _debounceTimer?.cancel();
                  if (mounted) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  }
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

          // Filter Button
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
              onPressed: () => _showFilterBottomSheet(context, ref),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Sort Button
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
              onPressed: () {
                _showSortDialog(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 3) Horizontal Chips Row
  Widget _buildCategoryChips(
    AsyncValue<List<Category>> categoriesAsync,
    int? selectedCategoryId,
  ) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: categoriesAsync.when(
        data: (categories) {
          final l10n = AppLocalizations.of(context)!;
          // Use real categories if available, otherwise use placeholders
          final chipLabels = categories.isNotEmpty
              ? [l10n.all, ...categories.map((c) => c.name)]
              : [
                  l10n.all,
                  'Design',
                  'Writing',
                  'Development',
                  'Marketing',
                  'Video',
                ];

          // Find the index of the selected category chip
          int? selectedIndex;
          if (selectedCategoryId != null && categories.isNotEmpty) {
            try {
              final selectedCategory = categories.firstWhere(
                (c) => c.id == selectedCategoryId,
              );
              selectedIndex = chipLabels.indexOf(selectedCategory.name);
            } catch (e) {
              selectedIndex = null;
            }
          }

          // Scroll to selected chip after build
          if (selectedIndex != null && selectedIndex >= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_categoryScrollController.hasClients && mounted) {
                // Calculate approximate position (each chip is ~100px wide + spacing)
                final double estimatedPosition = selectedIndex! * 110.0;
                _categoryScrollController.animateTo(
                  estimatedPosition,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          }

          return ListView.separated(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: chipLabels.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final label = chipLabels[index];
              final isSelected = label == l10n.all
                  ? selectedCategoryId == null
                  : categories.isNotEmpty &&
                        categories.any(
                          (c) => c.name == label && c.id == selectedCategoryId,
                        );

              return AppGradientFilterChip(
                label: label,
                selected: isSelected,
                onTap: () {
                  if (label == l10n.all) {
                    ref.read(selectedExploreCategoryIdProvider.notifier).state =
                        null;
                  } else if (categories.isNotEmpty) {
                    final category = categories.firstWhere(
                      (c) => c.name == label,
                    );
                    ref.read(selectedExploreCategoryIdProvider.notifier).state =
                        category.id;
                  }
                },
              );
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              width: 100,
              height: 40,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
        error: (error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSavedOnlyChip(AppLocalizations l10n) {
    final savedOnly = ref.watch(showSavedProjectsOnlyProvider);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppGradientFilterChip(
          label: l10n.savedProjects,
          icon: Icons.bookmark_outline_rounded,
          selected: savedOnly,
          onTap: () {
            ref.read(showSavedProjectsOnlyProvider.notifier).state =
                !savedOnly;
          },
        ),
      ),
    );
  }

  // 4) Projects Grid (2-column masonry/staggered grid like Pinterest)
  Widget _buildProjectsGrid(
    BuildContext context,
    List<Project> projects, {
    bool shrinkWrap = false,
  }) {
    final favoriteIds = ref.watch(favoriteProjectIdsProvider);
    return MasonryGridView.count(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: shrinkWrap
          ? EdgeInsets.zero
          : const EdgeInsets.all(AppSpacing.lg),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ExploreProjectCard(
          project: project,
          isFavorite: favoriteIds.contains(project.id),
          onTap: () {
            context.push('/project/${project.id}', extra: project);
          },
          onFavorite: () {
            ref.read(favoriteProjectIdsProvider.notifier).toggle(project.id);
          },
        );
      },
    );
  }

  // 5) Floating Action Button
  // Search Results UI
  // ignore: unused_element
  Widget _buildSearchResults(
    BuildContext context,
    AsyncValue<SearchResult> searchResultsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(searchResultsProvider);
        await ref.read(searchResultsProvider.future);
      },
      child: searchResultsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, stackTrace) => ErrorState(
          message: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
        data: (searchResult) {
          final l10n = AppLocalizations.of(context)!;
          if (searchResult.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.noResultsFound,
              message: l10n.tryAgain,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Categories Section
                if (searchResult.categories.isNotEmpty) ...[
                  Text(
                    l10n.categories,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: searchResult.categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final category = searchResult.categories[index];
                        return GestureDetector(
                          onTap: () {
                            // Set category filter and clear search
                            ref
                                .read(
                                  exploreSelectedCategoryIdProvider.notifier,
                                )
                                .state = category
                                .id;
                            ref
                                .read(
                                  selectedExploreCategoryIdProvider.notifier,
                                )
                                .state = category
                                .id;
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF111827,
                              ), // Near-black for active
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                category.name,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // Projects Section
                if (searchResult.projects.isNotEmpty) ...[
                  Text(
                    l10n.projects,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildProjectsGrid(
                    context,
                    searchResult.projects,
                    shrinkWrap: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isClient = location.contains('/client');

    if (!isClient) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientFab(onPressed: () => context.go('/create-project')),
    );
  }

  Widget? _buildBottomNav(BuildContext context) {
    // Determine current index based on route
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 2; // Default to explore

    if (location.contains('/client')) {
      if (location.contains('/projects')) {
        currentIndex = 1;
      } else if (location.contains('/explore')) {
        currentIndex = 2;
      } else if (location.contains('/payments')) {
        currentIndex = 3;
      } else if (location.contains('/profile')) {
        currentIndex = 4;
      } else {
        currentIndex = 0;
      }

      final l10n = AppLocalizations.of(context)!;
      return AppBottomNavBar(
        currentIndex: currentIndex,
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
      );
    } else if (location.contains('/freelancer')) {
      if (location.contains('/projects')) {
        currentIndex = 1;
      } else if (location.contains('/explore')) {
        currentIndex = 2;
      } else if (location.contains('/payments')) {
        currentIndex = 3;
      } else if (location.contains('/profile')) {
        currentIndex = 4;
      } else {
        currentIndex = 0;
      }

      final l10n = AppLocalizations.of(context)!;
      return AppBottomNavBar(
        currentIndex: currentIndex,
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
      );
    } else if (location.contains('/admin')) {
      if (location.contains('/explore')) {
        currentIndex = 1;
      } else if (location.contains('/payments')) {
        currentIndex = 2;
      } else if (location.contains('/profile')) {
        currentIndex = 3;
      } else {
        currentIndex = 0;
      }

      final l10n = AppLocalizations.of(context)!;
      return AppBottomNavBar(
        currentIndex: currentIndex,
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
      );
    }

    return null;
  }
}

// Sort Option Widget
class _SortOption extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

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

/// Grid content: shows lastData + overlay while loading, skeleton when no lastData, or data/error.
class _ExploreGridContent extends StatelessWidget {
  const _ExploreGridContent({
    required this.projectsAsync,
    required this.lastData,
    required this.l10n,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.onRetry,
    required this.buildGrid,
  });

  final AsyncValue<List<Project>> projectsAsync;
  final List<Project>? lastData;
  final AppLocalizations l10n;
  final int? selectedCategoryId;
  final String searchQuery;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, List<Project> projects) buildGrid;

  @override
  Widget build(BuildContext context) {
    // Loading with previous data: show grid + small loading indicator
    if (projectsAsync.isLoading && lastData != null && lastData!.isNotEmpty) {
      return Stack(
        children: [
          buildGrid(context, lastData!),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 0,
              color: Colors.transparent,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentOrange,
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Loading with no previous data: skeleton grid
    if (projectsAsync.isLoading) {
      return const ExploreSkeletonGrid(itemCount: 8);
    }
    // Error with previous data: show grid + error bar with retry
    if (projectsAsync.hasError && lastData != null && lastData!.isNotEmpty) {
      final errorMessage = projectsAsync.error.toString().replaceAll(
        'Exception: ',
        '',
      );
      final is403 =
          errorMessage.toLowerCase().contains('permission') ||
          errorMessage.toLowerCase().contains('access denied') ||
          errorMessage.toLowerCase().contains('forbidden');
      return Stack(
        children: [
          buildGrid(context, lastData!),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.white,
              elevation: 4,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          is403
                              ? 'Permission denied. Verify your account.'
                              : errorMessage.length > 60
                              ? '${errorMessage.substring(0, 60)}...'
                              : errorMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Error with no previous data: full error state
    if (projectsAsync.hasError) {
      final errorMessage = projectsAsync.error.toString().replaceAll(
        'Exception: ',
        '',
      );
      final is403 =
          errorMessage.toLowerCase().contains('permission') ||
          errorMessage.toLowerCase().contains('access denied') ||
          errorMessage.toLowerCase().contains('forbidden');
      return ErrorState(
        message: is403
            ? 'You don\'t have permission to view these projects. Please verify your account or log in with a different role.'
            : errorMessage,
        onRetry: onRetry,
      );
    }
    // Data case
    final projects = projectsAsync.value!;
    if (projects.isEmpty) {
      return EmptyState(
        icon: Icons.explore_outlined,
        title: l10n.noResultsFound,
        message: l10n.noResultsFound,
      );
    }
    return buildGrid(context, projects);
  }
}
