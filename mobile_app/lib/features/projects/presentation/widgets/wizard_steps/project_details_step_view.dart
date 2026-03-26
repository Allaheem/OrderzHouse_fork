// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../features/categories/data/repositories/categories_repository.dart';
import '../../../../../../features/categories/presentation/providers/categories_provider.dart';
import '../../providers/project_wizard_provider.dart';

class ProjectDetailsStepView extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ProjectDetailsStepView({super.key, required this.onNext});

  @override
  ConsumerState<ProjectDetailsStepView> createState() =>
      _ProjectDetailsStepViewState();
}

class _ProjectDetailsStepViewState
    extends ConsumerState<ProjectDetailsStepView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _durationDaysController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _skillsController = TextEditingController();

  List<Map<String, dynamic>>? _subSubCategories;
  bool _loadingSubSubCategories = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final draft = ref.read(projectWizardProvider);
    // Hourly rate option is disabled; reset to fixed if it was selected
    if (draft.projectType == 'hourly') {
      ref.read(projectWizardProvider.notifier).updateProjectType('fixed');
    }
    final draftAfter = ref.read(projectWizardProvider);
    _titleController.text = draftAfter.title ?? '';
    _descriptionController.text = draftAfter.description ?? '';
    if (draftAfter.budget != null)
      _budgetController.text = draftAfter.budget.toString();
    if (draftAfter.hourlyRate != null) {
      _hourlyRateController.text = draftAfter.hourlyRate.toString();
    }
    if (draftAfter.budgetMin != null) {
      _budgetMinController.text = draftAfter.budgetMin.toString();
    }
    if (draftAfter.budgetMax != null) {
      _budgetMaxController.text = draftAfter.budgetMax.toString();
    }
    if (draftAfter.durationDays != null) {
      _durationDaysController.text = draftAfter.durationDays.toString();
    }
    if (draftAfter.durationHours != null) {
      _durationHoursController.text = draftAfter.durationHours.toString();
    }
    if (draftAfter.preferredSkills.isNotEmpty) {
      _skillsController.text = draftAfter.preferredSkills.join(', ');
    }

    if (draftAfter.categoryId != null) {
      _loadSubCategories(draftAfter.categoryId!);
    }
    if (draftAfter.subCategoryId != null && draftAfter.categoryId != null) {
      _loadSubSubCategories(draftAfter.categoryId!, draftAfter.subCategoryId!);
    }
  }

  Future<void> _loadSubCategories(int categoryId) async {
    // Load sub-sub-categories directly by category ID
    setState(() {
      _loadingSubSubCategories = true;
    });

    try {
      final repository = CategoriesRepository();
      final response = await repository.fetchSubSubCategoriesByCategoryId(
        categoryId,
      );
      if (response.success && response.data != null) {
        setState(() {
          _subSubCategories = response.data;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _loadingSubSubCategories = false;
      });
    }
  }

  Future<void> _loadSubSubCategories(int categoryId, int subCategoryId) async {
    setState(() {
      _loadingSubSubCategories = true;
    });

    try {
      final repository = CategoriesRepository();
      final response = await repository.fetchSubSubCategories(subCategoryId);
      if (response.success && response.data != null) {
        setState(() {
          _subSubCategories = response.data;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _loadingSubSubCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _hourlyRateController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _durationDaysController.dispose();
    _durationHoursController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  // Helper to get localized error message
  String? _getLocalizedError(
    AppLocalizations l10n,
    Map<String, String> errors,
    String key,
  ) {
    final error = errors[key];
    if (error == null) return null;

    // Map error messages to localized versions
    switch (error) {
      case 'Title is required':
        return l10n.titleIsRequired;
      case 'Title must be between 10 and 100 characters':
        return l10n.titleLengthError;
      case 'Description is required':
        return l10n.descriptionIsRequired;
      case 'Description must be between 100 and 2000 characters':
        return l10n.descriptionLengthError;
      case 'Category is required':
        return l10n.categoryIsRequired;
      case 'Sub-sub-category is required':
        return l10n.subSubCategoryIsRequired;
      case 'Project type is required':
        return l10n.projectTypeIsRequired;
      case 'Budget is required and must be greater than 0':
        return l10n.budgetIsRequired;
      case 'Hourly rate is required and must be greater than 0':
        return l10n.hourlyRateIsRequired;
      case 'Minimum budget is required and must be greater than 0':
        return l10n.minBudgetIsRequired;
      case 'Maximum budget is required and must be greater than 0':
        return l10n.maxBudgetIsRequired;
      case 'Maximum budget must be greater than or equal to minimum budget':
        return l10n.maxBudgetMustBeGreater;
      case 'Duration type is required':
        return l10n.durationTypeIsRequired;
      case 'Duration days is required and must be greater than 0':
        return l10n.durationDaysIsRequired;
      case 'Duration hours is required and must be greater than 0':
        return l10n.durationHoursIsRequired;
      default:
        return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(projectWizardProvider);
    final categoriesAsync = ref.watch(exploreCategoriesProvider);
    final errors = draft.validateStep1();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.projectTitleLabel,
              hintText: l10n.projectTitleHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _getLocalizedError(l10n, errors, 'title'),
            ),
            maxLength: 100,
            onChanged: (value) {
              ref.read(projectWizardProvider.notifier).updateTitle(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.descriptionLabel,
              hintText: l10n.descriptionHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _getLocalizedError(l10n, errors, 'description'),
            ),
            maxLines: 6,
            maxLength: 2000,
            onChanged: (value) {
              ref.read(projectWizardProvider.notifier).updateDescription(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Category
          categoriesAsync.when(
            data: (categories) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.categoryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: draft.categoryId,
                  decoration: InputDecoration(
                    hintText: l10n.selectCategoryHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _getLocalizedError(l10n, errors, 'categoryId'),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(projectWizardProvider.notifier)
                          .updateCategory(value, null, null);
                      _loadSubCategories(value);
                    }
                  },
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => Text(l10n.failedToLoadCategories),
          ),

          const SizedBox(height: AppSpacing.md),

          // Sub-Sub-Category
          if (draft.categoryId != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.subSubCategoryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _loadingSubSubCategories
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        initialValue: draft.subSubCategoryId,
                        decoration: InputDecoration(
                          hintText: l10n.selectSubSubCategoryHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _getLocalizedError(
                            l10n,
                            errors,
                            'subSubCategoryId',
                          ),
                        ),
                        items:
                            _subSubCategories?.map((ssc) {
                              return DropdownMenuItem(
                                value: ssc['id'] as int,
                                child: Text(ssc['name'] as String),
                              );
                            }).toList() ??
                            [],
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(projectWizardProvider.notifier)
                                .updateCategory(
                                  draft.categoryId,
                                  draft.subCategoryId,
                                  value,
                                );
                          }
                        },
                      ),
              ],
            ),

          const SizedBox(height: AppSpacing.md),

          // Project Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.projectTypeLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: (draft.projectType == 'hourly')
                    ? 'fixed'
                    : draft.projectType,
                decoration: InputDecoration(
                  hintText: l10n.selectProjectTypeHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _getLocalizedError(l10n, errors, 'projectType'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text(l10n.projectTypeFixed),
                  ),
                  DropdownMenuItem(
                    value: 'bidding',
                    child: Text(l10n.projectTypeBidding),
                  ),
                ],
                onChanged: (value) {
                  ref
                      .read(projectWizardProvider.notifier)
                      .updateProjectType(value);
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Budget fields based on project type
          if (draft.projectType == 'fixed') ...[
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.budgetJodLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _getLocalizedError(l10n, errors, 'budget'),
              ),
              onChanged: (value) {
                final budget = double.tryParse(value);
                ref.read(projectWizardProvider.notifier).updateBudget(budget);
              },
            ),
          ] else if (draft.projectType == 'hourly') ...[
            TextFormField(
              controller: _hourlyRateController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.hourlyRateJodLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _getLocalizedError(l10n, errors, 'hourlyRate'),
              ),
              onChanged: (value) {
                final rate = double.tryParse(value);
                ref.read(projectWizardProvider.notifier).updateHourlyRate(rate);
              },
            ),
          ] else if (draft.projectType == 'bidding') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.minBudgetJodLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _getLocalizedError(l10n, errors, 'budgetMin'),
                    ),
                    onChanged: (value) {
                      final min = double.tryParse(value);
                      ref
                          .read(projectWizardProvider.notifier)
                          .updateBiddingBudget(min, draft.budgetMax);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.maxBudgetJodLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _getLocalizedError(l10n, errors, 'budgetMax'),
                    ),
                    onChanged: (value) {
                      final max = double.tryParse(value);
                      ref
                          .read(projectWizardProvider.notifier)
                          .updateBiddingBudget(draft.budgetMin, max);
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Duration Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.durationTypeLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: draft.durationType,
                decoration: InputDecoration(
                  hintText: l10n.selectDurationTypeHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _getLocalizedError(l10n, errors, 'durationType'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'days',
                    child: Text(l10n.durationTypeDays),
                  ),
                  DropdownMenuItem(
                    value: 'hours',
                    child: Text(l10n.durationTypeHours),
                  ),
                ],
                onChanged: (value) {
                  ref
                      .read(projectWizardProvider.notifier)
                      .updateDuration(
                        value,
                        value == 'days' ? draft.durationDays : null,
                        value == 'hours' ? draft.durationHours : null,
                      );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Duration value
          if (draft.durationType == 'days') ...[
            TextFormField(
              controller: _durationDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.durationDaysLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _getLocalizedError(l10n, errors, 'durationDays'),
              ),
              onChanged: (value) {
                final days = int.tryParse(value);
                ref
                    .read(projectWizardProvider.notifier)
                    .updateDuration('days', days, null);
              },
            ),
          ] else if (draft.durationType == 'hours') ...[
            TextFormField(
              controller: _durationHoursController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.durationHoursLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _getLocalizedError(l10n, errors, 'durationHours'),
              ),
              onChanged: (value) {
                final hours = int.tryParse(value);
                ref
                    .read(projectWizardProvider.notifier)
                    .updateDuration('hours', null, hours);
              },
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Preferred Skills
          TextFormField(
            controller: _skillsController,
            decoration: InputDecoration(
              labelText: l10n.preferredSkillsLabel,
              hintText: l10n.preferredSkillsHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final skills = value
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              ref
                  .read(projectWizardProvider.notifier)
                  .updatePreferredSkills(skills);
            },
          ),
        ],
      ),
    );
  }
}
