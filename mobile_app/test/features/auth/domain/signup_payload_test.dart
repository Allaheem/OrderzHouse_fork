import 'package:OrderzHouse/features/auth/data/models/signup_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignupPayload.toJson', () {
    test('normalizes email and referral code', () {
      const payload = SignupPayload(
        roleId: 2,
        firstName: 'Jane',
        lastName: 'Doe',
        email: ' Jane@Example.COM ',
        password: 'Password123',
        phoneNumber: '+1234',
        country: 'US',
        username: 'jane',
        referralCode: ' ref42 ',
      );

      final json = payload.toJson();

      expect(json['email'], 'jane@example.com');
      expect(json['referral_code'], 'REF42');
    });

    test('omits optional fields when empty', () {
      const payload = SignupPayload(
        roleId: 2,
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        password: 'Password123',
        country: 'US',
        username: 'jane',
        categoryIds: <int>[],
        referralCode: '   ',
      );

      final json = payload.toJson();

      expect(json.containsKey('category_ids'), isFalse);
      expect(json.containsKey('phone_number'), isFalse);
      expect(json.containsKey('referral_code'), isFalse);
    });
  });
}
