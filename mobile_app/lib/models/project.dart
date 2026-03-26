// ??? ????????
class Project {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String? coverPic;
  final String projectType; // 'fixed', 'hourly', 'bidding'
  final String
  status; // 'active', 'bidding', 'in_progress', 'completed', 'cancelled'
  final double? budget;
  final double? budgetMin;
  final double? budgetMax;
  final double? hourlyRate;
  final int? durationDays;
  final int? durationHours;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.coverPic,
    required this.projectType,
    required this.status,
    this.budget,
    this.budgetMin,
    this.budgetMax,
    this.hourlyRate,
    this.durationDays,
    this.durationHours,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      coverPic: json['cover_pic'] as String?,
      projectType: json['project_type'] as String,
      status: json['status'] as String,
      budget: json['budget'] != null
          ? (json['budget'] as num).toDouble()
          : null,
      budgetMin: json['budget_min'] != null
          ? (json['budget_min'] as num).toDouble()
          : null,
      budgetMax: json['budget_max'] != null
          ? (json['budget_max'] as num).toDouble()
          : null,
      hourlyRate: json['hourly_rate'] != null
          ? (json['hourly_rate'] as num).toDouble()
          : null,
      durationDays: json['duration_days'] as int?,
      durationHours: json['duration_hours'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get budgetDisplay {
    if (projectType == 'fixed' && budget != null) {
      return '${budget!.toStringAsFixed(0)} JOD';
    } else if (projectType == 'hourly' && hourlyRate != null) {
      return '${hourlyRate!.toStringAsFixed(0)} JOD/hour';
    } else if (projectType == 'bidding' &&
        budgetMin != null &&
        budgetMax != null) {
      return '${budgetMin!.toStringAsFixed(0)} - ${budgetMax!.toStringAsFixed(0)} JOD';
    }
    return 'Negotiable';
  }
}
