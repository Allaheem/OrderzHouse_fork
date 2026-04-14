// ??? ????????
import 'dart:convert';
import 'dart:typed_data';

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
import '../../../auth/presentation/providers/auth_provider.dart';

class SecurityCenterScreen extends ConsumerStatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  ConsumerState<SecurityCenterScreen> createState() =>
      _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends ConsumerState<SecurityCenterScreen> {
  bool _busy = false;

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  Future<void> _refreshUser() async {
    await ref.read(authStateProvider.notifier).refreshUser();
  }

  Future<void> _onDisable2FA(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.disableTwoFactor),
        content: Text(l10n.warning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    final res = await repo.disableTwoFactor();
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.success) {
      await _refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? l10n.success)),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? l10n.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Uint8List? _decodeQrPng(String? dataUrl) {
    if (dataUrl == null || !dataUrl.contains('base64,')) return null;
    final idx = dataUrl.indexOf('base64,');
    if (idx < 0) return null;
    try {
      return base64Decode(dataUrl.substring(idx + 7));
    } catch (_) {
      return null;
    }
  }

  Future<void> _onEnable2FA(AppLocalizations l10n) async {
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    final gen = await repo.generateTwoFactor();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!gen.success || gen.data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(gen.message ?? 'Failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final qrUrl = gen.data!['qrCodeUrl'] as String?;
    final png = _decodeQrPng(qrUrl);
    if (png == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.error}: could not show QR. Try again or use another network.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    final codeController = TextEditingController();

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enableTwoFactor),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.twoFactorAuthSubtitle,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Image.memory(png, width: 200, height: 200),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: l10n.verifyOtp,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              final r = await repo.verifyTwoFactor(token: code);
              if (!ctx.mounted) return;
              if (r.success) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(r.message ?? l10n.error),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    codeController.dispose();

    if (verified == true && mounted) {
      await _refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.success)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).user;
    final twoFactorOn = user?.isTwoFactorEnabled ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                AppHeader(
                  title: l10n.security,
                  onBack: () => _handleBack(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _TwoFactorCard(
                          enabled: twoFactorOn,
                          busy: _busy,
                          onEnable: () => _onEnable2FA(l10n),
                          onDisable: () => _onDisable2FA(l10n),
                          l10n: l10n,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChangePasswordCard(
                          onTap: () => context.push('/change-password'),
                          l10n: l10n,
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
    );
  }
}

class _TwoFactorCard extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final AppLocalizations l10n;

  const _TwoFactorCard({
    required this.enabled,
    required this.busy,
    required this.onEnable,
    required this.onDisable,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.accentOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.twoFactorAuth,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: enabled
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.textTertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        enabled ? l10n.active : l10n.notAvailable,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: enabled
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            enabled ? l10n.securitySubtitle : l10n.twoFactorAuthSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryGradientButton(
            onPressed: busy
                ? () {}
                : (enabled ? onDisable : onEnable),
            label: enabled ? l10n.disableTwoFactor : l10n.enableTwoFactor,
            height: 48,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordCard extends StatelessWidget {
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _ChangePasswordCard({required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.changePassword,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.changePasswordSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
