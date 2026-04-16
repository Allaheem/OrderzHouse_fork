// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/repositories/auth_repository.dart';

// Provider for change password repository
final changePasswordRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final Map<String, String?> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _currentPasswordFocusNode.addListener(() => setState(() {}));
    _newPasswordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  String? _validateCurrentPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.passwordRequired;
    }
    return null;
  }

  String? _validateNewPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired;
    }
    if (value != _newPasswordController.text) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }

  bool _validateForm(AppLocalizations l10n) {
    _validationErrors.clear();
    final currentError = _validateCurrentPassword(
      _currentPasswordController.text,
      l10n,
    );
    if (currentError != null) {
      _validationErrors['currentPassword'] = currentError;
    }
    final newError = _validateNewPassword(_newPasswordController.text, l10n);
    if (newError != null) {
      _validationErrors['newPassword'] = newError;
    }
    final confirmError = _validateConfirmPassword(
      _confirmPasswordController.text,
      l10n,
    );
    if (confirmError != null) {
      _validationErrors['confirmPassword'] = confirmError;
    }
    setState(() {});
    return _validationErrors.isEmpty;
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validateForm(l10n)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fieldRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(changePasswordRepositoryProvider);
      final response = await repository.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordChanged),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _handleBack();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleCancel() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      // Show confirmation if there's input
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.warning),
          content: Text(l10n.confirmDeleteAccount),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleBack();
              },
              child: Text(
                l10n.confirm,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    } else {
      _handleBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  AppHeader(title: l10n.changePassword, onBack: _handleBack),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // Current Password
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            focusNode: _currentPasswordFocusNode,
                            label: l10n.currentPassword,
                            obscureText: _obscureCurrentPassword,
                            errorText: _validationErrors['currentPassword'],
                            onVisibilityToggle: () {
                              setState(() {
                                _obscureCurrentPassword =
                                    !_obscureCurrentPassword;
                              });
                            },
                            onChanged: () {
                              setState(() {
                                _validationErrors.remove('currentPassword');
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // New Password
                          _buildPasswordField(
                            controller: _newPasswordController,
                            focusNode: _newPasswordFocusNode,
                            label: l10n.newPassword,
                            obscureText: _obscureNewPassword,
                            errorText: _validationErrors['newPassword'],
                            onVisibilityToggle: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            onChanged: () {
                              setState(() {
                                _validationErrors.remove('newPassword');
                                if (_confirmPasswordController.text.isEmpty) {
                                  _validationErrors.remove('confirmPassword');
                                }
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Confirm New Password
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            label: l10n.confirmNewPassword,
                            obscureText: _obscureConfirmPassword,
                            errorText: _validationErrors['confirmPassword'],
                            onVisibilityToggle: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            onChanged: () {
                              setState(() {
                                _validationErrors.remove('confirmPassword');
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Buttons
                  Container(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.md,
                      bottom:
                          AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColorLight,
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleCancel,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                side: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                l10n.cancel,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: AppSpacing.md),

                          // Save Button
                          Expanded(
                            child: PrimaryGradientButton(
                              onPressed: _isLoading ? null : _handleSave,
                              label: l10n.save,
                              isLoading: _isLoading,
                              height: 52,
                              borderRadius: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required VoidCallback onChanged,
    String? errorText,
  }) {
    final isFocused = focusNode.hasFocus;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorText != null
              ? AppColors.error.withOpacity(0.3)
              : (isFocused ? AppColors.accentOrange : AppColors.border),
          width: errorText != null ? 2 : (isFocused ? 2 : 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) => onChanged(),
        cursorColor: AppColors.accentOrange,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.iconGray,
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.iconGray,
              size: 22,
            ),
            onPressed: onVisibilityToggle,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          errorText: errorText,
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
