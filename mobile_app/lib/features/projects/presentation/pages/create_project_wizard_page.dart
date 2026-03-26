// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/project_wizard_provider.dart';
import '../widgets/wizard_steps/project_details_step_view.dart';
import '../widgets/wizard_steps/project_cover_step_view.dart';
import '../widgets/wizard_steps/project_files_step_view.dart';
import '../widgets/wizard_steps/payment_step_view.dart';
import '../widgets/wizard_steps/internal_skip_step_view.dart';
import '../../data/repositories/projects_repository.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CreateProjectWizardPage extends ConsumerStatefulWidget {
  const CreateProjectWizardPage({super.key});

  @override
  ConsumerState<CreateProjectWizardPage> createState() =>
      _CreateProjectWizardPageState();
}

class _CreateProjectWizardPageState
    extends ConsumerState<CreateProjectWizardPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getLocalizedValidationError(AppLocalizations l10n, String error) {
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
      case 'Maximum 5 files allowed':
        return l10n.maxFilesError;
      default:
        return error;
    }
  }

  void _nextStep() {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.read(projectWizardProvider);

    // Validate current step before proceeding
    final errors = draft.validateStep(_currentStep);
    if (errors.isNotEmpty) {
      // Show first error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getLocalizedValidationError(l10n, errors.values.first),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // Block navigation
    }

    // Only proceed if validation passes
    if (_currentStep < _getTotalSteps() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  int _getTotalSteps() {
    final draft = ref.read(projectWizardProvider);
    return draft.projectType != 'bidding' ? 4 : 3;
  }

  bool _isInternalSkipStep() {
    final draft = ref.read(projectWizardProvider);
    final user = ref.read(authStateProvider).user;
    if (draft.projectType == 'bidding') return false;
    return user?.canPostWithoutPayment == true && user?.roleId == 2;
  }

  Future<void> _submitProjectFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.read(projectWizardProvider);
    final user = ref.read(authStateProvider).user;
    final repository = ProjectsRepository();

    if (_isSubmitting) return;
    final token = await SecureStore.readAccessToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.authRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final step1Errors = draft.validateStep1();
    final step2Errors = draft.validateStep2();
    final step3Errors = draft.validateStep3();
    if (step1Errors.isNotEmpty ||
        step2Errors.isNotEmpty ||
        step3Errors.isNotEmpty) {
      final allErrors = <String, String>{};
      allErrors.addAll(step1Errors);
      allErrors.addAll(step2Errors);
      allErrors.addAll(step3Errors);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getLocalizedValidationError(l10n, allErrors.values.first),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // A) BIDDING: create project directly, no payment
      if (draft.projectType == 'bidding') {
        final createResponse = await repository.createProject(
          categoryId: draft.categoryId!,
          subCategoryId: draft.subCategoryId,
          subSubCategoryId: draft.subSubCategoryId!,
          title: draft.title!,
          description: draft.description!,
          projectType: draft.projectType!,
          budget: draft.budget,
          hourlyRate: draft.hourlyRate,
          budgetMin: draft.budgetMin,
          budgetMax: draft.budgetMax,
          durationType: draft.durationType!,
          durationDays: draft.durationDays,
          durationHours: draft.durationHours,
          preferredSkills: draft.preferredSkills.isNotEmpty
              ? draft.preferredSkills
              : null,
          coverPicPath: draft.coverPic?.path,
        );
        if (!createResponse.success || createResponse.data == null) {
          throw Exception(createResponse.message ?? 'Failed to create project');
        }
        final idRaw = createResponse.data!['id'];
        final projectId = idRaw is int
            ? idRaw
            : (idRaw is num
                  ? idRaw.toInt()
                  : int.tryParse(idRaw?.toString() ?? '') ?? 0);
        if (projectId <= 0) {
          throw Exception(createResponse.message ?? 'Invalid project id');
        }
        if (draft.projectFiles.isNotEmpty) {
          final filePaths = draft.projectFiles.map((f) => f.path).toList();
          final uploadResponse = await repository.uploadProjectFiles(
            projectId,
            filePaths,
          );
          if (!uploadResponse.success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.projectCreatedButFilesFailed(
                    uploadResponse.message ?? '',
                  ),
                ),
                backgroundColor: AppColors.accentOrange,
              ),
            );
          }
        }
        if (mounted) {
          ref.read(projectWizardProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.projectCreated),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/project-success/$projectId');
        }
        return;
      }

      final canSkipPayment =
          user?.canPostWithoutPayment == true && user?.roleId == 2;

      // B) INTERNAL: skip payment, create project directly
      if (canSkipPayment) {
        final createResponse = await repository.createProject(
          categoryId: draft.categoryId!,
          subCategoryId: draft.subCategoryId,
          subSubCategoryId: draft.subSubCategoryId!,
          title: draft.title!,
          description: draft.description!,
          projectType: draft.projectType!,
          budget: draft.budget,
          hourlyRate: draft.hourlyRate,
          budgetMin: draft.budgetMin,
          budgetMax: draft.budgetMax,
          durationType: draft.durationType!,
          durationDays: draft.durationDays,
          durationHours: draft.durationHours,
          preferredSkills: draft.preferredSkills.isNotEmpty
              ? draft.preferredSkills
              : null,
          coverPicPath: draft.coverPic?.path,
        );
        if (!createResponse.success || createResponse.data == null) {
          throw Exception(createResponse.message ?? 'Failed to create project');
        }
        final idRawB = createResponse.data!['id'];
        final projectIdB = idRawB is int
            ? idRawB
            : (idRawB is num
                  ? idRawB.toInt()
                  : int.tryParse(idRawB?.toString() ?? '') ?? 0);
        if (projectIdB <= 0) {
          throw Exception(createResponse.message ?? 'Invalid project id');
        }
        if (draft.projectFiles.isNotEmpty) {
          final filePaths = draft.projectFiles.map((f) => f.path).toList();
          await repository.uploadProjectFiles(projectIdB, filePaths);
        }
        if (mounted) {
          ref.read(projectWizardProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.projectCreated),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/project-success/$projectIdB');
        }
        return;
      }

      // C) CliQ: create project, upload files, set offline payment, go to success
      final createResponse = await repository.createProject(
        categoryId: draft.categoryId!,
        subCategoryId: draft.subCategoryId,
        subSubCategoryId: draft.subSubCategoryId!,
        title: draft.title!,
        description: draft.description!,
        projectType: draft.projectType!,
        budget: draft.budget,
        hourlyRate: draft.hourlyRate,
        budgetMin: draft.budgetMin,
        budgetMax: draft.budgetMax,
        durationType: draft.durationType!,
        durationDays: draft.durationDays,
        durationHours: draft.durationHours,
        preferredSkills: draft.preferredSkills.isNotEmpty
            ? draft.preferredSkills
            : null,
        coverPicPath: draft.coverPic?.path,
      );
      if (!createResponse.success || createResponse.data == null) {
        throw Exception(createResponse.message ?? 'Failed to create project');
      }
      final idRawC = createResponse.data!['id'];
      final projectIdC = idRawC is int
          ? idRawC
          : (idRawC is num
                ? idRawC.toInt()
                : int.tryParse(idRawC?.toString() ?? '') ?? 0);
      if (projectIdC <= 0) {
        throw Exception(createResponse.message ?? 'Invalid project id');
      }

      if (draft.projectFiles.isNotEmpty) {
        final filePaths = draft.projectFiles.map((f) => f.path).toList();
        await repository.uploadProjectFiles(projectIdC, filePaths);
      }

      final offlineResponse = await repository.setProjectOfflinePayment(
        projectIdC,
        'cliq',
      );
      if (!offlineResponse.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              offlineResponse.message ?? 'Failed to set CliQ payment',
            ),
            backgroundColor: AppColors.accentOrange,
          ),
        );
      }

      if (mounted) {
        ref.read(projectWizardProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.projectCreated),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/project-success/$projectIdC');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getActionButtonLabel(AppLocalizations l10n) {
    final totalSteps = _getTotalSteps();
    if (_currentStep != totalSteps - 1) return l10n.continue_;
    final draft = ref.read(projectWizardProvider);
    if (draft.projectType == 'bidding') return l10n.createProject;
    if (_isInternalSkipStep()) return l10n.createProject;
    return 'Submit via CliQ';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.read(projectWizardProvider);
    final totalSteps = _getTotalSteps();

    return AppScaffold(
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: AppColors.accentOrange,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/client');
                      }
                    },
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    l10n.createProject,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),
          ),

          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < totalSteps - 1 ? AppSpacing.xs : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? AppColors.accentOrange
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Steps Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ProjectDetailsStepView(
                  onNext: _nextStep, // _nextStep now validates internally
                ),
                ProjectCoverStepView(
                  onNext: _nextStep,
                ), // _nextStep now validates internally
                ProjectFilesStepView(
                  onNext: draft.projectType != 'bidding' ? _nextStep : null,
                ),
                if (draft.projectType != 'bidding')
                  _isInternalSkipStep()
                      ? InternalSkipStepView(
                          onBack: _previousStep,
                          onCreateProject: _submitProjectFlow,
                          isSubmitting: _isSubmitting,
                        )
                      : PaymentStepView(onSubmit: _submitProjectFlow),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColorLight,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentStep > 0 && !_isSubmitting
                        ? _previousStep
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: _currentStep > 0
                            ? AppColors.border
                            : AppColors.borderLight,
                      ),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(
                      l10n.back,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Continue/Create/Pay Button
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : (_currentStep == totalSteps - 1
                                ? _submitProjectFlow
                                : _nextStep),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _getActionButtonLabel(l10n),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
