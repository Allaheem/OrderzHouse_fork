// ??? ????????
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const User._();

  const factory User({
    required int id,
    required String username,
    required String email,
    @JsonKey(name: 'role_id') required int roleId,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_pic_url') String? profilePicUrl,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'is_two_factor_enabled')
    @Default(false)
    bool isTwoFactorEnabled,
    @JsonKey(name: 'email_verified') @Default(false) bool emailVerified,
    @JsonKey(name: 'must_accept_terms') @Default(false) bool mustAcceptTerms,
    @JsonKey(name: 'terms_version_required') String? termsVersionRequired,
    @JsonKey(name: 'can_post_without_payment')
    @Default(false)
    bool canPostWithoutPayment,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

extension UserExtension on User {
  String get role {
    switch (roleId) {
      case 2:
        return 'client';
      case 3:
        return 'freelancer';
      default:
        return 'unknown';
    }
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  bool get isClient => roleId == 2;
  bool get isFreelancer => roleId == 3;
}
