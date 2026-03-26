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
import '../providers/forgot_password_provider.dart';

class ResetPasswordOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({required this.email, super.key});

  @override
  ConsumerState<ResetPasswordOtpScreen> createState() =>
      _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState
    extends ConsumerState<ResetPasswordOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Start cooldown timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resetOtpProvider.notifier).startCooldown();
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

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final l10n = AppLocalizations.of(context)!;
    final otp = _getOtpCode();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterCompleteOtp),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notifier = ref.read(resetOtpProvider.notifier);
    final success = await notifier.verifyOtp(widget.email, otp);

    // ignore: use_build_context_synchronously
    if (!mounted) return;

    if (success) {
      // Navigate to reset password screen with email and otp
      context.push(
        '/reset-password?email=${Uri.encodeComponent(widget.email)}&otp=${Uri.encodeComponent(otp)}',
      );
    } else {
      final error = ref.read(resetOtpProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'OTP verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(resetOtpProvider);

    if (!state.canResend) return;

    final notifier = ref.read(resetOtpProvider.notifier);
    final success = await notifier.resendOtp(widget.email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.otpResentSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(resetOtpProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to resend OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/forgot-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetOtpProvider);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top section with back button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _handleBack,
                      color: const Color(0xFF111827),
                    ),
                    const Spacer(),
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
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      // Icon circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 50,
                          color: Color(0xFFFB923C),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Title
                      Text(
                        l10n.enterOtpCode,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Subtitle with email
                      Text(
                        l10n.otpSentTo(widget.email),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // OTP input fields
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
                        onPressed: state.isLoading ? null : _handleVerify,
                        isLoading: state.isLoading,
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
                            '${l10n.didntReceiveCode} ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (state.canResend)
                            TextButton(
                              onPressed: state.isLoading ? null : _handleResend,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.resendOtp,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: const Color(0xFFFB923C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Text(
                              l10n.resendIn(state.resendCooldown),
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
              ? const Color(0xFFFB923C)
              : const Color(0xFFE5E7EB),
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFFFB923C).withValues(alpha: 0.2),
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
