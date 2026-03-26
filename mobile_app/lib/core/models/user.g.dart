// ??? ????????
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  roleId: (json['role_id'] as num).toInt(),
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  profilePicUrl: json['profile_pic_url'] as String?,
  isDeleted: json['is_deleted'] as bool? ?? false,
  isTwoFactorEnabled: json['is_two_factor_enabled'] as bool? ?? false,
  emailVerified: json['email_verified'] as bool? ?? false,
  mustAcceptTerms: json['must_accept_terms'] as bool? ?? false,
  termsVersionRequired: json['terms_version_required'] as String?,
  canPostWithoutPayment: json['can_post_without_payment'] as bool? ?? false,
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'role_id': instance.roleId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic_url': instance.profilePicUrl,
      'is_deleted': instance.isDeleted,
      'is_two_factor_enabled': instance.isTwoFactorEnabled,
      'email_verified': instance.emailVerified,
      'must_accept_terms': instance.mustAcceptTerms,
      'terms_version_required': instance.termsVersionRequired,
      'can_post_without_payment': instance.canPostWithoutPayment,
    };
