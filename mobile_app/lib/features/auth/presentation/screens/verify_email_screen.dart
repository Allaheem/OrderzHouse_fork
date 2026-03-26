// ??? ????????
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({required this.email, super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  int _resendCooldownSeconds = 30;
  Timer? _cooldownTimer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldownSeconds <= 1) {
          _resendCooldownSeconds = 0;
          timer.cancel();
        } else {
          _resendCooldownSeconds--;
        }
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code')),
      );
      return;
    }

    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.verifyOtpAndCompleteSignup(code);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authStateProvider).user;
      final home = user?.roleId == 3 ? '/freelancer' : '/client';
      context.go(home);
    } else {
      final error = ref.read(authStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Verification failed. Check the code and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.resendSignupOtp(widget.email);
    if (mounted) {
      setState(() => _isResending = false);
      if (success) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New code sent. Check your email (and spam folder).'),
          ),
        );
      } else {
        final error = ref.read(authStateProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to resend code. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('Verify Your Email', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a verification code to\n${widget.email}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Check your spam folder if you don\'t see it.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Enter OTP',
                controller: _otpController,
                keyboardType: TextInputType.number,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryGradientButton(
                label: 'Verify',
                onPressed: authState.isLoading ? null : _handleVerify,
                isLoading: authState.isLoading,
                width: double.infinity,
                height: 54,
                borderRadius: 999,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: (_resendCooldownSeconds > 0 || _isResending)
                    ? null
                    : _handleResend,
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _resendCooldownSeconds > 0
                            ? 'Resend code ($_resendCooldownSeconds s)'
                            : 'Resend code',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
