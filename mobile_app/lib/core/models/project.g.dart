// ??? ????????
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      coverPic: json['cover_pic'] as String?,
      projectType: json['project_type'] as String,
      status: json['status'] as String,
      budget: _doubleFromJson(json['budget']),
      budgetMin: _doubleFromJson(json['budget_min']),
      budgetMax: _doubleFromJson(json['budget_max']),
      hourlyRate: _doubleFromJson(json['hourly_rate']),
      durationDays: _intFromJson(json['duration_days']),
      durationHours: _intFromJson(json['duration_hours']),
      createdAt: _dateTimeFromJson(json['created_at']),
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'cover_pic': instance.coverPic,
      'project_type': instance.projectType,
      'status': instance.status,
      'budget': instance.budget,
      'budget_min': instance.budgetMin,
      'budget_max': instance.budgetMax,
      'hourly_rate': instance.hourlyRate,
      'duration_days': instance.durationDays,
      'duration_hours': instance.durationHours,
      'created_at': instance.createdAt.toIso8601String(),
    };
