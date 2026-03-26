// ??? ????????
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_pic')
  String? get coverPic => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_type')
  String get projectType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _doubleFromJson)
  double? get budget => throw _privateConstructorUsedError;
  @JsonKey(name: 'budget_min', fromJson: _doubleFromJson)
  double? get budgetMin => throw _privateConstructorUsedError;
  @JsonKey(name: 'budget_max', fromJson: _doubleFromJson)
  double? get budgetMax => throw _privateConstructorUsedError;
  @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson)
  double? get hourlyRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_days', fromJson: _intFromJson)
  int? get durationDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_hours', fromJson: _intFromJson)
  int? get durationHours => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'user_id') int userId,
    String title,
    String description,
    @JsonKey(name: 'cover_pic') String? coverPic,
    @JsonKey(name: 'project_type') String projectType,
    String status,
    @JsonKey(fromJson: _doubleFromJson) double? budget,
    @JsonKey(name: 'budget_min', fromJson: _doubleFromJson) double? budgetMin,
    @JsonKey(name: 'budget_max', fromJson: _doubleFromJson) double? budgetMax,
    @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson) double? hourlyRate,
    @JsonKey(name: 'duration_days', fromJson: _intFromJson) int? durationDays,
    @JsonKey(name: 'duration_hours', fromJson: _intFromJson) int? durationHours,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
    DateTime createdAt,
  });
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = null,
    Object? coverPic = freezed,
    Object? projectType = null,
    Object? status = null,
    Object? budget = freezed,
    Object? budgetMin = freezed,
    Object? budgetMax = freezed,
    Object? hourlyRate = freezed,
    Object? durationDays = freezed,
    Object? durationHours = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            coverPic: freezed == coverPic
                ? _value.coverPic
                : coverPic // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectType: null == projectType
                ? _value.projectType
                : projectType // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            budget: freezed == budget
                ? _value.budget
                : budget // ignore: cast_nullable_to_non_nullable
                      as double?,
            budgetMin: freezed == budgetMin
                ? _value.budgetMin
                : budgetMin // ignore: cast_nullable_to_non_nullable
                      as double?,
            budgetMax: freezed == budgetMax
                ? _value.budgetMax
                : budgetMax // ignore: cast_nullable_to_non_nullable
                      as double?,
            hourlyRate: freezed == hourlyRate
                ? _value.hourlyRate
                : hourlyRate // ignore: cast_nullable_to_non_nullable
                      as double?,
            durationDays: freezed == durationDays
                ? _value.durationDays
                : durationDays // ignore: cast_nullable_to_non_nullable
                      as int?,
            durationHours: freezed == durationHours
                ? _value.durationHours
                : durationHours // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
    _$ProjectImpl value,
    $Res Function(_$ProjectImpl) then,
  ) = __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'user_id') int userId,
    String title,
    String description,
    @JsonKey(name: 'cover_pic') String? coverPic,
    @JsonKey(name: 'project_type') String projectType,
    String status,
    @JsonKey(fromJson: _doubleFromJson) double? budget,
    @JsonKey(name: 'budget_min', fromJson: _doubleFromJson) double? budgetMin,
    @JsonKey(name: 'budget_max', fromJson: _doubleFromJson) double? budgetMax,
    @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson) double? hourlyRate,
    @JsonKey(name: 'duration_days', fromJson: _intFromJson) int? durationDays,
    @JsonKey(name: 'duration_hours', fromJson: _intFromJson) int? durationHours,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
    _$ProjectImpl _value,
    $Res Function(_$ProjectImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = null,
    Object? coverPic = freezed,
    Object? projectType = null,
    Object? status = null,
    Object? budget = freezed,
    Object? budgetMin = freezed,
    Object? budgetMax = freezed,
    Object? hourlyRate = freezed,
    Object? durationDays = freezed,
    Object? durationHours = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$ProjectImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        coverPic: freezed == coverPic
            ? _value.coverPic
            : coverPic // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectType: null == projectType
            ? _value.projectType
            : projectType // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        budget: freezed == budget
            ? _value.budget
            : budget // ignore: cast_nullable_to_non_nullable
                  as double?,
        budgetMin: freezed == budgetMin
            ? _value.budgetMin
            : budgetMin // ignore: cast_nullable_to_non_nullable
                  as double?,
        budgetMax: freezed == budgetMax
            ? _value.budgetMax
            : budgetMax // ignore: cast_nullable_to_non_nullable
                  as double?,
        hourlyRate: freezed == hourlyRate
            ? _value.hourlyRate
            : hourlyRate // ignore: cast_nullable_to_non_nullable
                  as double?,
        durationDays: freezed == durationDays
            ? _value.durationDays
            : durationDays // ignore: cast_nullable_to_non_nullable
                  as int?,
        durationHours: freezed == durationHours
            ? _value.durationHours
            : durationHours // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl extends _Project {
  const _$ProjectImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    required this.title,
    required this.description,
    @JsonKey(name: 'cover_pic') this.coverPic,
    @JsonKey(name: 'project_type') required this.projectType,
    required this.status,
    @JsonKey(fromJson: _doubleFromJson) this.budget,
    @JsonKey(name: 'budget_min', fromJson: _doubleFromJson) this.budgetMin,
    @JsonKey(name: 'budget_max', fromJson: _doubleFromJson) this.budgetMax,
    @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson) this.hourlyRate,
    @JsonKey(name: 'duration_days', fromJson: _intFromJson) this.durationDays,
    @JsonKey(name: 'duration_hours', fromJson: _intFromJson) this.durationHours,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
    required this.createdAt,
  }) : super._();

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey(name: 'cover_pic')
  final String? coverPic;
  @override
  @JsonKey(name: 'project_type')
  final String projectType;
  @override
  final String status;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  final double? budget;
  @override
  @JsonKey(name: 'budget_min', fromJson: _doubleFromJson)
  final double? budgetMin;
  @override
  @JsonKey(name: 'budget_max', fromJson: _doubleFromJson)
  final double? budgetMax;
  @override
  @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson)
  final double? hourlyRate;
  @override
  @JsonKey(name: 'duration_days', fromJson: _intFromJson)
  final int? durationDays;
  @override
  @JsonKey(name: 'duration_hours', fromJson: _intFromJson)
  final int? durationHours;
  @override
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;

  @override
  String toString() {
    return 'Project(id: $id, userId: $userId, title: $title, description: $description, coverPic: $coverPic, projectType: $projectType, status: $status, budget: $budget, budgetMin: $budgetMin, budgetMax: $budgetMax, hourlyRate: $hourlyRate, durationDays: $durationDays, durationHours: $durationHours, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverPic, coverPic) ||
                other.coverPic == coverPic) &&
            (identical(other.projectType, projectType) ||
                other.projectType == projectType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.budget, budget) || other.budget == budget) &&
            (identical(other.budgetMin, budgetMin) ||
                other.budgetMin == budgetMin) &&
            (identical(other.budgetMax, budgetMax) ||
                other.budgetMax == budgetMax) &&
            (identical(other.hourlyRate, hourlyRate) ||
                other.hourlyRate == hourlyRate) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.durationHours, durationHours) ||
                other.durationHours == durationHours) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    title,
    description,
    coverPic,
    projectType,
    status,
    budget,
    budgetMin,
    budgetMax,
    hourlyRate,
    durationDays,
    durationHours,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(this);
  }
}

abstract class _Project extends Project {
  const factory _Project({
    required final int id,
    @JsonKey(name: 'user_id') required final int userId,
    required final String title,
    required final String description,
    @JsonKey(name: 'cover_pic') final String? coverPic,
    @JsonKey(name: 'project_type') required final String projectType,
    required final String status,
    @JsonKey(fromJson: _doubleFromJson) final double? budget,
    @JsonKey(name: 'budget_min', fromJson: _doubleFromJson)
    final double? budgetMin,
    @JsonKey(name: 'budget_max', fromJson: _doubleFromJson)
    final double? budgetMax,
    @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson)
    final double? hourlyRate,
    @JsonKey(name: 'duration_days', fromJson: _intFromJson)
    final int? durationDays,
    @JsonKey(name: 'duration_hours', fromJson: _intFromJson)
    final int? durationHours,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
    required final DateTime createdAt,
  }) = _$ProjectImpl;
  const _Project._() : super._();

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get title;
  @override
  String get description;
  @override
  @JsonKey(name: 'cover_pic')
  String? get coverPic;
  @override
  @JsonKey(name: 'project_type')
  String get projectType;
  @override
  String get status;
  @override
  @JsonKey(fromJson: _doubleFromJson)
  double? get budget;
  @override
  @JsonKey(name: 'budget_min', fromJson: _doubleFromJson)
  double? get budgetMin;
  @override
  @JsonKey(name: 'budget_max', fromJson: _doubleFromJson)
  double? get budgetMax;
  @override
  @JsonKey(name: 'hourly_rate', fromJson: _doubleFromJson)
  double? get hourlyRate;
  @override
  @JsonKey(name: 'duration_days', fromJson: _intFromJson)
  int? get durationDays;
  @override
  @JsonKey(name: 'duration_hours', fromJson: _intFromJson)
  int? get durationHours;
  @override
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
