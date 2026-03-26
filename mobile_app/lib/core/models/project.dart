// ??? ????????
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

DateTime _dateTimeFromJson(dynamic value) {
  if (value is String) {
    return DateTime.parse(value);
  }
  return DateTime.now();
}

double? _doubleFromJson(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed;
  }
  return null;
}

int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed;
  }
  return null;
}

@freezed
class Project with _$Project {
  const Project._();

  const factory Project({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required String title,
    required String description,
    @JsonKey(name: 'cover_pic') String? coverPic,
    @JsonKey(name: 'project_type') required String projectType,
    required String status,
    @JsonKey(fromJson: _doubleFromJson) double? budget,
    @JsonKey(name: 'budget_min', fromJson: _doubleFromJson) double? budgetMin,
    @JsonKey(name: 'budget_max', fromJson: _doubleFromJson) double? budgetMax,
    @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson) double? hourlyRate,
    @JsonKey(name: 'duration_days', fromJson: _intFromJson) int? durationDays,
    @JsonKey(name: 'duration_hours', fromJson: _intFromJson) int? durationHours,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
    required DateTime createdAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}

extension ProjectExtension on Project {
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
