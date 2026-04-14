// ??? ????????
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// Reusable header matching Payments screen style
/// - White background
/// - Circular back button with shadow
/// - Centered title
/// - Optional right placeholder for symmetry
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showRightPlaceholder;

  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showRightPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    // One SafeArea for the status bar; do not also reserve [padding.top] inside a
    // fixed height (breaks when a parent SafeArea zeros out top padding — row gets ~40px).
    return SafeArea(
      bottom: false,
      child: Material(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button in circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColorLight,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    color: AppColors.textPrimary,
                    onPressed:
                        onBack ??
                        () {
                          // Safe back navigation
                          if (GoRouter.of(context).canPop()) {
                            context.pop();
                          } else {
                            // Fallback: navigate to profile
                            context.go('/client/profile');
                          }
                        },
                    padding: EdgeInsets.zero,
                  ),
                ),

                // Spacer to center title
                const Spacer(),

                // Centered title
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Spacer to balance
                const Spacer(),

                // Right placeholder to keep title centered
                if (showRightPlaceholder) const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
