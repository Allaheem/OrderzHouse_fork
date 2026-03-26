// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

/// Primary gradient button with vertical gradient from orange to red
/// Matches Tailwind: bg-gradient-to-b from-orange-400 to-red-500
/// Uses Material + Ink + InkWell to preserve ripple effects
class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bool enabled = isEnabled && !isLoading && onPressed != null;
    final double radius = borderRadius ?? AppRadius.lg;

    final buttonWidget = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled ? AppGradients.primaryButtonGradient : null,
          color: enabled ? null : AppColors.textTertiary,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: height < 48 ? 8 : 14,
              horizontal: width == null ? AppSpacing.xl : AppSpacing.md,
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 20,
                          color: enabled ? Colors.white : Colors.grey.shade700,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: enabled ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (width == null) {
      // For pill buttons (no fixed width), return intrinsic size
      return SizedBox(height: height, child: buttonWidget);
    }

    // For full-width buttons, wrap in SizedBox
    return SizedBox(width: width, height: height, child: buttonWidget);
  }
}

// Alias for backward compatibility
typedef GradientButton = PrimaryGradientButton;
