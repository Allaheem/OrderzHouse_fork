// ??? ????????
import 'dart:io';

class ProjectDraft {
  // Step 1: Project Details
  String? title;
  String? description;
  int? categoryId;
  int? subCategoryId;
  int? subSubCategoryId;
  String? projectType; // "fixed" | "hourly" | "bidding"

  // Budget fields (based on project_type)
  double? budget; // for fixed
  double? hourlyRate; // for hourly
  double? budgetMin; // for bidding
  double? budgetMax; // for bidding

  // Duration fields
  String? durationType; // "days" | "hours"
  int? durationDays;
  int? durationHours;

  // Preferred skills
  List<String> preferredSkills;

  // Step 2: Cover Image
  File? coverPic;

  // Step 3: Project Files
  List<File> projectFiles;

  ProjectDraft({
    this.title,
    this.description,
    this.categoryId,
    this.subCategoryId,
    this.subSubCategoryId,
    this.projectType,
    this.budget,
    this.hourlyRate,
    this.budgetMin,
    this.budgetMax,
    this.durationType,
    this.durationDays,
    this.durationHours,
    List<String>? preferredSkills,
    this.coverPic,
    List<File>? projectFiles,
  }) : preferredSkills = preferredSkills ?? [],
       projectFiles = projectFiles ?? [];

  // Validation for Step 1
  Map<String, String> validateStep1() {
    final errors = <String, String>{};

    if (title == null || title!.trim().isEmpty) {
      errors['title'] = 'Title is required';
    } else if (title!.trim().length < 10 || title!.trim().length > 100) {
      errors['title'] = 'Title must be between 10 and 100 characters';
    }

    if (description == null || description!.trim().isEmpty) {
      errors['description'] = 'Description is required';
    } else if (description!.trim().length < 100 ||
        description!.trim().length > 2000) {
      errors['description'] =
          'Description must be between 100 and 2000 characters';
    }

    if (categoryId == null) {
      errors['categoryId'] = 'Category is required';
    }

    if (subSubCategoryId == null) {
      errors['subSubCategoryId'] = 'Sub-sub-category is required';
    }

    if (projectType == null) {
      errors['projectType'] = 'Project type is required';
    } else {
      if (projectType == 'fixed') {
        if (budget == null || budget! <= 0) {
          errors['budget'] = 'Budget is required and must be greater than 0';
        }
      } else if (projectType == 'hourly') {
        if (hourlyRate == null || hourlyRate! <= 0) {
          errors['hourlyRate'] =
              'Hourly rate is required and must be greater than 0';
        }
      } else if (projectType == 'bidding') {
        if (budgetMin == null || budgetMin! <= 0) {
          errors['budgetMin'] =
              'Minimum budget is required and must be greater than 0';
        }
        if (budgetMax == null || budgetMax! <= 0) {
          errors['budgetMax'] =
              'Maximum budget is required and must be greater than 0';
        }
        if (budgetMin != null && budgetMax != null && budgetMax! < budgetMin!) {
          errors['budgetMax'] =
              'Maximum budget must be greater than or equal to minimum budget';
        }
      }
    }

    if (durationType == null) {
      errors['durationType'] = 'Duration type is required';
    } else {
      if (durationType == 'days') {
        if (durationDays == null || durationDays! <= 0) {
          errors['durationDays'] =
              'Duration days is required and must be greater than 0';
        }
      } else if (durationType == 'hours') {
        if (durationHours == null || durationHours! <= 0) {
          errors['durationHours'] =
              'Duration hours is required and must be greater than 0';
        }
      }
    }

    return errors;
  }

  bool get isStep1Valid => validateStep1().isEmpty;

  // Validation for Step 2 (Cover Image) - Optional, so always valid
  Map<String, String> validateStep2() {
    // Cover image is optional, so no validation errors
    return {};
  }

  bool get isStep2Valid => validateStep2().isEmpty;

  // Validation for Step 3 (Project Files) - Optional, but check file count limit
  Map<String, String> validateStep3() {
    final errors = <String, String>{};

    // Check file count limit (max 5 files)
    if (projectFiles.length > 5) {
      errors['projectFiles'] = 'Maximum 5 files allowed';
    }

    return errors;
  }

  bool get isStep3Valid => validateStep3().isEmpty;

  // Generic validation method for any step
  Map<String, String> validateStep(int step) {
    switch (step) {
      case 0:
        return validateStep1();
      case 1:
        return validateStep2();
      case 2:
        return validateStep3();
      default:
        return {};
    }
  }

  // Check if a step is valid
  bool isStepValid(int step) {
    return validateStep(step).isEmpty;
  }

  // Check if payment step is needed
  bool get needsPayment => projectType != 'bidding';

  // Get total steps (4 if needs payment, 3 if bidding)
  int get totalSteps => needsPayment ? 4 : 3;
}
