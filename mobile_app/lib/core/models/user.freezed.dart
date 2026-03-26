// ??? ????????
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'role_id')
  int get roleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String? get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String? get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_pic_url')
  String? get profilePicUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_two_factor_enabled')
  bool get isTwoFactorEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'email_verified')
  bool get emailVerified => throw _privateConstructorUsedError;
  @JsonKey(name: 'must_accept_terms')
  bool get mustAcceptTerms => throw _privateConstructorUsedError;
  @JsonKey(name: 'terms_version_required')
  String? get termsVersionRequired => throw _privateConstructorUsedError;
  @JsonKey(name: 'can_post_without_payment')
  bool get canPostWithoutPayment => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call({
    int id,
    String username,
    String email,
    @JsonKey(name: 'role_id') int roleId,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_pic_url') String? profilePicUrl,
    @JsonKey(name: 'is_deleted') bool isDeleted,
    @JsonKey(name: 'is_two_factor_enabled') bool isTwoFactorEnabled,
    @JsonKey(name: 'email_verified') bool emailVerified,
    @JsonKey(name: 'must_accept_terms') bool mustAcceptTerms,
    @JsonKey(name: 'terms_version_required') String? termsVersionRequired,
    @JsonKey(name: 'can_post_without_payment') bool canPostWithoutPayment,
  });
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? roleId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? profilePicUrl = freezed,
    Object? isDeleted = null,
    Object? isTwoFactorEnabled = null,
    Object? emailVerified = null,
    Object? mustAcceptTerms = null,
    Object? termsVersionRequired = freezed,
    Object? canPostWithoutPayment = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            roleId: null == roleId
                ? _value.roleId
                : roleId // ignore: cast_nullable_to_non_nullable
                      as int,
            firstName: freezed == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastName: freezed == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String?,
            profilePicUrl: freezed == profilePicUrl
                ? _value.profilePicUrl
                : profilePicUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTwoFactorEnabled: null == isTwoFactorEnabled
                ? _value.isTwoFactorEnabled
                : isTwoFactorEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            emailVerified: null == emailVerified
                ? _value.emailVerified
                : emailVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            mustAcceptTerms: null == mustAcceptTerms
                ? _value.mustAcceptTerms
                : mustAcceptTerms // ignore: cast_nullable_to_non_nullable
                      as bool,
            termsVersionRequired: freezed == termsVersionRequired
                ? _value.termsVersionRequired
                : termsVersionRequired // ignore: cast_nullable_to_non_nullable
                      as String?,
            canPostWithoutPayment: null == canPostWithoutPayment
                ? _value.canPostWithoutPayment
                : canPostWithoutPayment // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String username,
    String email,
    @JsonKey(name: 'role_id') int roleId,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_pic_url') String? profilePicUrl,
    @JsonKey(name: 'is_deleted') bool isDeleted,
    @JsonKey(name: 'is_two_factor_enabled') bool isTwoFactorEnabled,
    @JsonKey(name: 'email_verified') bool emailVerified,
    @JsonKey(name: 'must_accept_terms') bool mustAcceptTerms,
    @JsonKey(name: 'terms_version_required') String? termsVersionRequired,
    @JsonKey(name: 'can_post_without_payment') bool canPostWithoutPayment,
  });
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? roleId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? profilePicUrl = freezed,
    Object? isDeleted = null,
    Object? isTwoFactorEnabled = null,
    Object? emailVerified = null,
    Object? mustAcceptTerms = null,
    Object? termsVersionRequired = freezed,
    Object? canPostWithoutPayment = null,
  }) {
    return _then(
      _$UserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        roleId: null == roleId
            ? _value.roleId
            : roleId // ignore: cast_nullable_to_non_nullable
                  as int,
        firstName: freezed == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastName: freezed == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String?,
        profilePicUrl: freezed == profilePicUrl
            ? _value.profilePicUrl
            : profilePicUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTwoFactorEnabled: null == isTwoFactorEnabled
            ? _value.isTwoFactorEnabled
            : isTwoFactorEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        emailVerified: null == emailVerified
            ? _value.emailVerified
            : emailVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        mustAcceptTerms: null == mustAcceptTerms
            ? _value.mustAcceptTerms
            : mustAcceptTerms // ignore: cast_nullable_to_non_nullable
                  as bool,
        termsVersionRequired: freezed == termsVersionRequired
            ? _value.termsVersionRequired
            : termsVersionRequired // ignore: cast_nullable_to_non_nullable
                  as String?,
        canPostWithoutPayment: null == canPostWithoutPayment
            ? _value.canPostWithoutPayment
            : canPostWithoutPayment // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl extends _User {
  const _$UserImpl({
    required this.id,
    required this.username,
    required this.email,
    @JsonKey(name: 'role_id') required this.roleId,
    @JsonKey(name: 'first_name') this.firstName,
    @JsonKey(name: 'last_name') this.lastName,
    @JsonKey(name: 'profile_pic_url') this.profilePicUrl,
    @JsonKey(name: 'is_deleted') this.isDeleted = false,
    @JsonKey(name: 'is_two_factor_enabled') this.isTwoFactorEnabled = false,
    @JsonKey(name: 'email_verified') this.emailVerified = false,
    @JsonKey(name: 'must_accept_terms') this.mustAcceptTerms = false,
    @JsonKey(name: 'terms_version_required') this.termsVersionRequired,
    @JsonKey(name: 'can_post_without_payment') bool? canPostWithoutPayment,
  }) : this.canPostWithoutPayment = canPostWithoutPayment ?? false,
       super._();

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String email;
  @override
  @JsonKey(name: 'role_id')
  final int roleId;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  @override
  @JsonKey(name: 'profile_pic_url')
  final String? profilePicUrl;
  @override
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  @override
  @JsonKey(name: 'is_two_factor_enabled')
  final bool isTwoFactorEnabled;
  @override
  @JsonKey(name: 'email_verified')
  final bool emailVerified;
  @override
  @JsonKey(name: 'must_accept_terms')
  final bool mustAcceptTerms;
  @override
  @JsonKey(name: 'terms_version_required')
  final String? termsVersionRequired;
  @override
  @JsonKey(name: 'can_post_without_payment')
  final bool canPostWithoutPayment;

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, roleId: $roleId, firstName: $firstName, lastName: $lastName, profilePicUrl: $profilePicUrl, isDeleted: $isDeleted, isTwoFactorEnabled: $isTwoFactorEnabled, emailVerified: $emailVerified, mustAcceptTerms: $mustAcceptTerms, termsVersionRequired: $termsVersionRequired, canPostWithoutPayment: $canPostWithoutPayment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.profilePicUrl, profilePicUrl) ||
                other.profilePicUrl == profilePicUrl) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.isTwoFactorEnabled, isTwoFactorEnabled) ||
                other.isTwoFactorEnabled == isTwoFactorEnabled) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.mustAcceptTerms, mustAcceptTerms) ||
                other.mustAcceptTerms == mustAcceptTerms) &&
            (identical(other.termsVersionRequired, termsVersionRequired) ||
                other.termsVersionRequired == termsVersionRequired) &&
            (identical(other.canPostWithoutPayment, canPostWithoutPayment) ||
                other.canPostWithoutPayment == canPostWithoutPayment));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    username,
    email,
    roleId,
    firstName,
    lastName,
    profilePicUrl,
    isDeleted,
    isTwoFactorEnabled,
    emailVerified,
    mustAcceptTerms,
    termsVersionRequired,
    canPostWithoutPayment,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User extends User {
  const factory _User({
    required final int id,
    required final String username,
    required final String email,
    @JsonKey(name: 'role_id') required final int roleId,
    @JsonKey(name: 'first_name') final String? firstName,
    @JsonKey(name: 'last_name') final String? lastName,
    @JsonKey(name: 'profile_pic_url') final String? profilePicUrl,
    @JsonKey(name: 'is_deleted') final bool isDeleted,
    @JsonKey(name: 'is_two_factor_enabled') final bool isTwoFactorEnabled,
    @JsonKey(name: 'email_verified') final bool emailVerified,
    @JsonKey(name: 'must_accept_terms') final bool mustAcceptTerms,
    @JsonKey(name: 'terms_version_required') final String? termsVersionRequired,
    @JsonKey(name: 'can_post_without_payment')
    final bool? canPostWithoutPayment,
  }) = _$UserImpl;
  const _User._() : super._();

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String get email;
  @override
  @JsonKey(name: 'role_id')
  int get roleId;
  @override
  @JsonKey(name: 'first_name')
  String? get firstName;
  @override
  @JsonKey(name: 'last_name')
  String? get lastName;
  @override
  @JsonKey(name: 'profile_pic_url')
  String? get profilePicUrl;
  @override
  @JsonKey(name: 'is_deleted')
  bool get isDeleted;
  @override
  @JsonKey(name: 'is_two_factor_enabled')
  bool get isTwoFactorEnabled;
  @override
  @JsonKey(name: 'email_verified')
  bool get emailVerified;
  @override
  @JsonKey(name: 'must_accept_terms')
  bool get mustAcceptTerms;
  @override
  @JsonKey(name: 'terms_version_required')
  String? get termsVersionRequired;
  @override
  @JsonKey(name: 'can_post_without_payment')
  bool get canPostWithoutPayment;
  @override
  @JsonKey(ignore: true)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
