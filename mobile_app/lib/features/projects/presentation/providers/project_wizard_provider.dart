// ??? ????????
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_draft.dart';

class ProjectWizardNotifier extends StateNotifier<ProjectDraft> {
  ProjectWizardNotifier() : super(ProjectDraft());

  void updateTitle(String? title) {
    state = ProjectDraft(
      title: title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateDescription(String? description) {
    state = ProjectDraft(
      title: state.title,
      description: description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateCategory(
    int? categoryId,
    int? subCategoryId,
    int? subSubCategoryId,
  ) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      subSubCategoryId: subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateProjectType(String? projectType) {
    // Clear budget fields when changing project type
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: projectType,
      budget: null,
      hourlyRate: null,
      budgetMin: null,
      budgetMax: null,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateBudget(double? budget) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateHourlyRate(double? hourlyRate) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateBiddingBudget(double? budgetMin, double? budgetMax) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateDuration(
    String? durationType,
    int? durationDays,
    int? durationHours,
  ) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: durationType,
      durationDays: durationDays,
      durationHours: durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updatePreferredSkills(List<String> skills) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: skills,
      coverPic: state.coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateCoverPic(File? coverPic) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: coverPic,
      projectFiles: state.projectFiles,
    );
  }

  void updateProjectFiles(List<File> files) {
    state = ProjectDraft(
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      subCategoryId: state.subCategoryId,
      subSubCategoryId: state.subSubCategoryId,
      projectType: state.projectType,
      budget: state.budget,
      hourlyRate: state.hourlyRate,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      durationType: state.durationType,
      durationDays: state.durationDays,
      durationHours: state.durationHours,
      preferredSkills: state.preferredSkills,
      coverPic: state.coverPic,
      projectFiles: files,
    );
  }

  void reset() {
    state = ProjectDraft();
  }
}

final projectWizardProvider =
    StateNotifierProvider<ProjectWizardNotifier, ProjectDraft>((ref) {
      return ProjectWizardNotifier();
    });
