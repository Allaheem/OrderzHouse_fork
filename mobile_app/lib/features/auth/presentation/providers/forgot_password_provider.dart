// ??? ????????
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

// ==================== Forgot Password State ====================

class ForgotPasswordState {
  final bool isLoading;
  final String? error;
  final bool otpSent;

  const ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.otpSent = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? error,
    bool? otpSent,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final AuthRepository _repository;

  ForgotPasswordNotifier(this._repository) : super(const ForgotPasswordState());

  Future<bool> requestOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.requestPasswordResetOtp(email: email);

    if (response.success) {
      state = state.copyWith(isLoading: false, otpSent: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
      return false;
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordNotifier,
      ForgotPasswordState
    >((ref) => ForgotPasswordNotifier(AuthRepository()));

// ==================== Reset OTP State ====================

class ResetOtpState {
  final bool isLoading;
  final String? error;
  final bool isVerified;
  final int resendCooldown;
  final bool canResend;

  const ResetOtpState({
    this.isLoading = false,
    this.error,
    this.isVerified = false,
    this.resendCooldown = 0,
    this.canResend = true,
  });

  ResetOtpState copyWith({
    bool? isLoading,
    String? error,
    bool? isVerified,
    int? resendCooldown,
    bool? canResend,
  }) {
    return ResetOtpState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isVerified: isVerified ?? this.isVerified,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      canResend: canResend ?? this.canResend,
    );
  }
}

class ResetOtpNotifier extends StateNotifier<ResetOtpState> {
  final AuthRepository _repository;
  Timer? _timer;

  ResetOtpNotifier(this._repository) : super(const ResetOtpState());

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.verifyPasswordResetOtp(
      email: email,
      otp: otp,
    );

    if (response.success) {
      state = state.copyWith(isLoading: false, isVerified: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    if (!state.canResend) return false;

    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.resendPasswordResetOtp(email: email);

    if (response.success) {
      state = state.copyWith(isLoading: false);
      startCooldown();
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
      return false;
    }
  }

  void startCooldown() {
    _timer?.cancel();
    state = state.copyWith(resendCooldown: 30, canResend: false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCooldown > 0) {
        state = state.copyWith(resendCooldown: state.resendCooldown - 1);
      } else {
        state = state.copyWith(canResend: true);
        timer.cancel();
      }
    });
  }

  void reset() {
    _timer?.cancel();
    state = const ResetOtpState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final resetOtpProvider =
    StateNotifierProvider.autoDispose<ResetOtpNotifier, ResetOtpState>(
      (ref) => ResetOtpNotifier(AuthRepository()),
    );

// ==================== Reset Password State ====================

class ResetPasswordState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ResetPasswordState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ResetPasswordState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  final AuthRepository _repository;

  ResetPasswordNotifier(this._repository) : super(const ResetPasswordState());

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    if (response.success) {
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: response.message);
      return false;
    }
  }

  void reset() {
    state = const ResetPasswordState();
  }
}

final resetPasswordProvider =
    StateNotifierProvider.autoDispose<
      ResetPasswordNotifier,
      ResetPasswordState
    >((ref) => ResetPasswordNotifier(AuthRepository()));
