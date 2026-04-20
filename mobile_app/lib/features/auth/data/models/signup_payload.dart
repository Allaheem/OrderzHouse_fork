// ??? ????????
/// Payload for two-step signup: collected on register screen, sent after OTP verification.
class SignupPayload {
  final int roleId;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String country;
  final String username;
  final List<int>? categoryIds;
  final String? referralCode;

  const SignupPayload({
    required this.roleId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phoneNumber,
    required this.country,
    required this.username,
    this.categoryIds,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'role_id': roleId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email.trim().toLowerCase(),
      'password': password,
      'country': country,
      'username': username,
    };
    final pn = phoneNumber?.trim();
    if (pn != null && pn.isNotEmpty) {
      data['phone_number'] = pn;
    }
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      data['category_ids'] = categoryIds;
    }
    if (referralCode != null && referralCode!.trim().isNotEmpty) {
      data['referral_code'] = referralCode!.trim().toUpperCase();
    }
    return data;
  }
}
