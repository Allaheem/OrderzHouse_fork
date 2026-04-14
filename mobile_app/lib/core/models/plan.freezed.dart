// ??? ????????
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Plan _$PlanFromJson(Map<String, dynamic> json) {
  return _Plan.fromJson(json);
}

/// @nodoc
mixin _$Plan {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _descriptionFromJson)
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _priceFromJson)
  num get price => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _durationFromJson)
  int get duration => throw _privateConstructorUsedError; // Duration in days
  @JsonKey(name: 'plan_type')
  String get planType => throw _privateConstructorUsedError; // 'monthly', 'yearly', 'popular'
  @JsonKey(fromJson: _featuresFromJson)
  List<String> get features => throw _privateConstructorUsedError;
  @JsonKey(name: 'apple_product_id')
  String? get appleProductId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlanCopyWith<Plan> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanCopyWith<$Res> {
  factory $PlanCopyWith(Plan value, $Res Function(Plan) then) =
      _$PlanCopyWithImpl<$Res, Plan>;
  @useResult
  $Res call({
    int id,
    String name,
    @JsonKey(fromJson: _descriptionFromJson) String? description,
    @JsonKey(fromJson: _priceFromJson) num price,
    @JsonKey(fromJson: _durationFromJson) int duration,
    @JsonKey(name: 'plan_type') String planType,
    @JsonKey(fromJson: _featuresFromJson) List<String> features,
    @JsonKey(name: 'apple_product_id') String? appleProductId,
  });
}

/// @nodoc
class _$PlanCopyWithImpl<$Res, $Val extends Plan>
    implements $PlanCopyWith<$Res> {
  _$PlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? duration = null,
    Object? planType = null,
    Object? features = null,
    Object? appleProductId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as num,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int,
            planType: null == planType
                ? _value.planType
                : planType // ignore: cast_nullable_to_non_nullable
                      as String,
            features: null == features
                ? _value.features
                : features // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            appleProductId: freezed == appleProductId
                ? _value.appleProductId
                : appleProductId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlanImplCopyWith<$Res> implements $PlanCopyWith<$Res> {
  factory _$$PlanImplCopyWith(
    _$PlanImpl value,
    $Res Function(_$PlanImpl) then,
  ) = __$$PlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    @JsonKey(fromJson: _descriptionFromJson) String? description,
    @JsonKey(fromJson: _priceFromJson) num price,
    @JsonKey(fromJson: _durationFromJson) int duration,
    @JsonKey(name: 'plan_type') String planType,
    @JsonKey(fromJson: _featuresFromJson) List<String> features,
    @JsonKey(name: 'apple_product_id') String? appleProductId,
  });
}

/// @nodoc
class __$$PlanImplCopyWithImpl<$Res>
    extends _$PlanCopyWithImpl<$Res, _$PlanImpl>
    implements _$$PlanImplCopyWith<$Res> {
  __$$PlanImplCopyWithImpl(_$PlanImpl _value, $Res Function(_$PlanImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? duration = null,
    Object? planType = null,
    Object? features = null,
    Object? appleProductId = freezed,
  }) {
    return _then(
      _$PlanImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as num,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int,
        planType: null == planType
            ? _value.planType
            : planType // ignore: cast_nullable_to_non_nullable
                  as String,
        features: null == features
            ? _value._features
            : features // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        appleProductId: freezed == appleProductId
            ? _value.appleProductId
            : appleProductId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlanImpl extends _Plan {
  const _$PlanImpl({
    required this.id,
    required this.name,
    @JsonKey(fromJson: _descriptionFromJson) this.description,
    @JsonKey(fromJson: _priceFromJson) required this.price,
    @JsonKey(fromJson: _durationFromJson) required this.duration,
    @JsonKey(name: 'plan_type') required this.planType,
    @JsonKey(fromJson: _featuresFromJson)
    final List<String> features = const [],
    @JsonKey(name: 'apple_product_id') this.appleProductId,
  }) : _features = features,
       super._();

  factory _$PlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlanImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey(fromJson: _descriptionFromJson)
  final String? description;
  @override
  @JsonKey(fromJson: _priceFromJson)
  final num price;
  @override
  @JsonKey(fromJson: _durationFromJson)
  final int duration;
  // Duration in days
  @override
  @JsonKey(name: 'plan_type')
  final String planType;
  // 'monthly', 'yearly', 'popular'
  final List<String> _features;
  // 'monthly', 'yearly', 'popular'
  @override
  @JsonKey(fromJson: _featuresFromJson)
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  @override
  @JsonKey(name: 'apple_product_id')
  final String? appleProductId;

  @override
  String toString() {
    return 'Plan(id: $id, name: $name, description: $description, price: $price, duration: $duration, planType: $planType, features: $features, appleProductId: $appleProductId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.planType, planType) ||
                other.planType == planType) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.appleProductId, appleProductId) ||
                other.appleProductId == appleProductId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    price,
    duration,
    planType,
    const DeepCollectionEquality().hash(_features),
    appleProductId,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanImplCopyWith<_$PlanImpl> get copyWith =>
      __$$PlanImplCopyWithImpl<_$PlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlanImplToJson(this);
  }
}

abstract class _Plan extends Plan {
  const factory _Plan({
    required final int id,
    required final String name,
    @JsonKey(fromJson: _descriptionFromJson) final String? description,
    @JsonKey(fromJson: _priceFromJson) required final num price,
    @JsonKey(fromJson: _durationFromJson) required final int duration,
    @JsonKey(name: 'plan_type') required final String planType,
    @JsonKey(fromJson: _featuresFromJson) final List<String> features,
    @JsonKey(name: 'apple_product_id') final String? appleProductId,
  }) = _$PlanImpl;
  const _Plan._() : super._();

  factory _Plan.fromJson(Map<String, dynamic> json) = _$PlanImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(fromJson: _descriptionFromJson)
  String? get description;
  @override
  @JsonKey(fromJson: _priceFromJson)
  num get price;
  @override
  @JsonKey(fromJson: _durationFromJson)
  int get duration;
  @override // Duration in days
  @JsonKey(name: 'plan_type')
  String get planType;
  @override // 'monthly', 'yearly', 'popular'
  @JsonKey(fromJson: _featuresFromJson)
  List<String> get features;
  @override
  @JsonKey(name: 'apple_product_id')
  String? get appleProductId;
  @override
  @JsonKey(ignore: true)
  _$$PlanImplCopyWith<_$PlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
