import 'package:OrderzHouse/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('returns error for empty email', () {
      expect(Validators.email(''), 'Email is required');
    });

    test('returns error for invalid email', () {
      expect(Validators.email('invalid-email'), 'Please enter a valid email');
    });

    test('returns null for valid email', () {
      expect(Validators.email('john@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for short password', () {
      expect(
        Validators.password('Aa1'),
        'Password must be at least 8 characters',
      );
    });

    test('returns error when missing uppercase', () {
      expect(
        Validators.password('password123'),
        'Password must contain at least one uppercase letter',
      );
    });

    test('returns null for strong password', () {
      expect(Validators.password('StrongPass123'), isNull);
    });
  });
}
