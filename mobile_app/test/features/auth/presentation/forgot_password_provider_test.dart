import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/forgot_password_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  group('ForgotPasswordNotifier', () {
    test('initial state is idle with otpSent=false', () {
      final notifier = ForgotPasswordNotifier(repository);
      addTearDown(notifier.dispose);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.otpSent, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('requestOtp sets otpSent=true on success', () async {
      when(
        () => repository.requestPasswordResetOtp(email: any(named: 'email')),
      ).thenAnswer(
        (_) async =>
            const ApiResponse<void>(success: true, message: 'OTP sent'),
      );

      final notifier = ForgotPasswordNotifier(repository);
      addTearDown(notifier.dispose);

      final ok = await notifier.requestOtp('user@example.com');

      expect(ok, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.otpSent, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('requestOtp sets error on failure', () async {
      when(
        () => repository.requestPasswordResetOtp(email: any(named: 'email')),
      ).thenAnswer(
        (_) async =>
            const ApiResponse<void>(success: false, message: 'User not found'),
      );

      final notifier = ForgotPasswordNotifier(repository);
      addTearDown(notifier.dispose);

      final ok = await notifier.requestOtp('missing@example.com');

      expect(ok, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.otpSent, isFalse);
      expect(notifier.state.error, 'User not found');
    });
  });

  group('ResetOtpNotifier', () {
    test('verifyOtp sets isVerified=true on success', () async {
      when(
        () => repository.verifyPasswordResetOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer(
        (_) async =>
            const ApiResponse<String?>(success: true, data: 'reset-token'),
      );

      final notifier = ResetOtpNotifier(repository);
      addTearDown(notifier.dispose);

      final ok = await notifier.verifyOtp('user@example.com', '123456');

      expect(ok, isTrue);
      expect(notifier.state.isVerified, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('resendOtp starts cooldown and blocks immediate retry', () async {
      when(
        () => repository.resendPasswordResetOtp(email: any(named: 'email')),
      ).thenAnswer((_) async => const ApiResponse<void>(success: true));

      final notifier = ResetOtpNotifier(repository);
      addTearDown(notifier.dispose);

      final first = await notifier.resendOtp('user@example.com');
      final second = await notifier.resendOtp('user@example.com');

      expect(first, isTrue);
      expect(second, isFalse);
      expect(notifier.state.canResend, isFalse);
      expect(notifier.state.resendCooldown, greaterThan(0));
    });
  });
}
