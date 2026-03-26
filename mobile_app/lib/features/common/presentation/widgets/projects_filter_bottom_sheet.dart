// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/explore_filters_provider.dart';
import '../providers/my_projects_filters_provider.dart';

/// Target of the filter sheet: Explore or My Projects.
enum ProjectsFilterTarget { explore, myProjects }

/// Shows the shared filter bottom sheet (sort, project type, budget, delivery time).
/// Reused by Explore and My Projects screens.
void showProjectsFilterBottomSheet(
  BuildContext context,
  ProjectsFilterTarget target,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _ProjectsFilterSheetContent(target: target),
    ),
  );
}

class _ProjectsFilterSheetContent extends ConsumerWidget {
  const _ProjectsFilterSheetContent({required this.target});

  final ProjectsFilterTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filters = target == ProjectsFilterTarget.explore
        ? ref.watch(exploreFiltersProvider)
        : ref.watch(myProjectsFiltersProvider);
    final notifier = target == ProjectsFilterTarget.explore
        ? ref.read(exploreFiltersProvider.notifier)
        : ref.read(myProjectsFiltersProvider.notifier);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.filters,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterSectionTitle(title: l10n.sortBy),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FilterChip(
                  label: l10n.newestFirst,
                  value: 'newest',
                  selected: filters.sort == 'newest',
                  onTap: () => notifier.setSort('newest'),
                ),
                _FilterChip(
                  label: l10n.oldestFirst,
                  value: 'oldest',
                  selected: filters.sort == 'oldest',
                  onTap: () => notifier.setSort('oldest'),
                ),
                _FilterChip(
                  label: l10n.priceHighToLow,
                  value: 'budget_high_to_low',
                  selected: filters.sort == 'budget_high_to_low',
                  onTap: () => notifier.setSort('budget_high_to_low'),
                ),
                _FilterChip(
                  label: l10n.priceLowToHigh,
                  value: 'budget_low_to_high',
                  selected: filters.sort == 'budget_low_to_high',
                  onTap: () => notifier.setSort('budget_low_to_high'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterSectionTitle(title: l10n.projectType),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FilterChip(
                  label: l10n.allTypes,
                  value: 'all',
                  selected: filters.projectType == 'all',
                  onTap: () => notifier.setProjectType('all'),
                ),
                _FilterChip(
                  label: l10n.projectTypeFixed,
                  value: 'fixed',
                  selected: filters.projectType == 'fixed',
                  onTap: () => notifier.setProjectType('fixed'),
                ),
                _FilterChip(
                  label: l10n.projectTypeBidding,
                  value: 'bidding',
                  selected: filters.projectType == 'bidding',
                  onTap: () => notifier.setProjectType('bidding'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterSectionTitle(title: l10n.budget),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FilterChip(
                  label: l10n.anyBudget,
                  value: 'all',
                  selected: filters.budgetFilter == 'all',
                  onTap: () => notifier.setBudgetFilter('all'),
                ),
                _FilterChip(
                  label: l10n.budgetLessThan50,
                  value: 'lessThan50',
                  selected: filters.budgetFilter == 'lessThan50',
                  onTap: () => notifier.setBudgetFilter('lessThan50'),
                ),
                _FilterChip(
                  label: l10n.budget50To200,
                  value: '50To200',
                  selected: filters.budgetFilter == '50To200',
                  onTap: () => notifier.setBudgetFilter('50To200'),
                ),
                _FilterChip(
                  label: l10n.budgetAbove200,
                  value: 'above200',
                  selected: filters.budgetFilter == 'above200',
                  onTap: () => notifier.setBudgetFilter('above200'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterSectionTitle(title: l10n.deliveryTime),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FilterChip(
                  label: l10n.anyTime,
                  value: 'all',
                  selected: filters.durationFilter == 'all',
                  onTap: () => notifier.setDurationFilter('all'),
                ),
                _FilterChip(
                  label: l10n.deliveryShort,
                  value: 'short',
                  selected: filters.durationFilter == 'short',
                  onTap: () => notifier.setDurationFilter('short'),
                ),
                _FilterChip(
                  label: l10n.deliveryMedium,
                  value: 'medium',
                  selected: filters.durationFilter == 'medium',
                  onTap: () => notifier.setDurationFilter('medium'),
                ),
                _FilterChip(
                  label: l10n.deliveryLong,
                  value: 'long',
                  selected: filters.durationFilter == 'long',
                  onTap: () => notifier.setDurationFilter('long'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.reset(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n.reset),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GradientButton(
                    onPressed: () => Navigator.of(context).pop(),
                    label: l10n.apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentOrange.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accentOrange,
    );
  }
}
