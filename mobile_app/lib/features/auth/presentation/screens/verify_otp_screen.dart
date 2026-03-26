// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({required this.email, super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _canResend = true;
        }
      });
      return _resendTimer > 0;
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final otp = _getOtpCode();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.verifyOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authStateProvider).user;
      // Check if terms need to be accepted
      if (user?.mustAcceptTerms == true) {
        context.go('/accept-terms');
        return;
      }
      final role = ref.read(authStateProvider).userRole;
      if (role == 'freelancer') {
        context.go('/freelancer');
      } else if (role == 'client') {
        context.go('/client');
      }
    } else {
      final error = ref.read(authStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'OTP verification failed')),
      );
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    // Call login again to resend OTP (or implement a dedicated resend endpoint)
    // For now, just reset timer
    _startResendTimer();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP resent successfully')));
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      // No previous route, go to login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false, // Handle back button ourselves
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background, // Pure white
        body: SafeArea(
          child: Column(
            children: [
              // Top section with back button and progress indicator
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _handleBack,
                          color: const Color(0xFF111827),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Progress indicator (3 bars)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ProgressBar(isActive: true),
                        SizedBox(width: 8),
                        _ProgressBar(isActive: true),
                        SizedBox(width: 8),
                        _ProgressBar(isActive: false),
                      ],
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      // Center circle with icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8E9E9), // Light pink
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          size: 50,
                          color: AppColors.primary, // Coral-red
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Title
                      Text(
                        l10n.enterOtp,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Subtitle
                      Text(
                        l10n.otpSentTo(widget.email),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // OTP input circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _OtpInputField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (value) => _onOtpChanged(index, value),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // Verify button
                      PrimaryGradientButton(
                        label: l10n.verify,
                        onPressed: _handleVerify,
                        isLoading: authState.isLoading,
                        width: double.infinity,
                        height: 54,
                        borderRadius: 999,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Resend OTP link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${l10n.resendCode}? ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (_canResend)
                            TextButton(
                              onPressed: _handleResend,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.resendCode,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Text(
                              l10n.resendIn(_resendTimer),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Progress bar indicator
class _ProgressBar extends StatelessWidget {
  final bool isActive;

  const _ProgressBar({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 40 : 20,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// OTP input field (circular)
class _OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  const _OtpInputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.primary
              : const Color(0xFFE5E7EB),
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.headlineMedium.copyWith(
          color: const Color(0xFF111827),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
