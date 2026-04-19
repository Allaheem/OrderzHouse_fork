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
    final double textScale = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.6)
        .scale(1.0);

    final bool fullWidth = width != null;
    // Full-width: never force a fixed outer height — SizedBox(height: …)+Ink clips text on iPad / large text scale.
    // Pad grows slightly with accessibility / dynamic type so label + line height always fits.
    final verticalPad = fullWidth
        ? (14.0 * textScale)
        : (((height - 24) / 2).clamp(6.0, 14.0) * textScale);

    final buttonWidget = Material(
      color: Colors.transparent,
      // Default Material clips to the shape; rounded rect can cut off label baselines on iPad / large text.
      clipBehavior: Clip.none,
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
              vertical: verticalPad,
              horizontal: fullWidth ? AppSpacing.md : AppSpacing.xl,
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
      // Pill: minimum touch height; intrinsic height can exceed [height] so label
      // is not clipped (e.g. large text / iPad) when used in Rows without [width].
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: buttonWidget,
      );
    }

    // Full width: width only — height is intrinsic (padding + label); avoids vertical clip.
    return SizedBox(width: width, child: buttonWidget);
  }
}

// Alias for backward compatibility
typedef GradientButton = PrimaryGradientButton;
