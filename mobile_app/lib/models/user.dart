// ??? ????????
class User {
  final int id;
  final String username;
  final String email;
  final int roleId;
  final String? firstName;
  final String? lastName;
  final String? profilePicUrl;
  final bool isDeleted;
  final bool isTwoFactorEnabled;
  final bool emailVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.roleId,
    this.firstName,
    this.lastName,
    this.profilePicUrl,
    required this.isDeleted,
    required this.isTwoFactorEnabled,
    required this.emailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      roleId: json['role_id'] as int,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePicUrl: json['profile_pic_url'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isTwoFactorEnabled: json['is_two_factor_enabled'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
    );
  }

  String get role {
    switch (roleId) {
      case 1:
        return 'admin';
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
}
