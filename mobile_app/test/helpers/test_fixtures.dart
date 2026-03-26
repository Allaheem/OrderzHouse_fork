import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/models/signup_payload.dart';

User buildTestUser({int roleId = 2, bool mustAcceptTerms = false}) {
  return User(
    id: 1,
    username: 'tester',
    email: 'tester@example.com',
    roleId: roleId,
    firstName: 'Test',
    lastName: 'User',
    mustAcceptTerms: mustAcceptTerms,
  );
}

SignupPayload buildSignupPayload() {
  return const SignupPayload(
    roleId: 2,
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'JANE@EXAMPLE.COM',
    password: 'Password123',
    phoneNumber: '+1234567890',
    country: 'US',
    username: 'janedoe',
    categoryIds: <int>[1, 3],
    referralCode: ' ref42 ',
  );
}
