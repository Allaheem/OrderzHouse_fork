// ??? ????????
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bullet list of premium benefits for subscription compliance (App Store 3.1.2).
class SubscriptionPlanBenefits extends StatelessWidget {
  const SubscriptionPlanBenefits({
    super.key,
    required this.planTitle,
    required this.bullets,
  });

  /// Short label shown above bullets (e.g. "Monthly subscription").
  final String planTitle;

  /// Benefit lines (one bullet each).
  final List<String> bullets;

  /// Default copy requested for ORDERZ_HOUSE premium plans.
  static const List<String> defaultPremiumBullets = <String>[
    'Full access to all premium features inside ORDERZ_HOUSE',
    'Ability to use all app services without restrictions',
    'Faster and priority experience inside the app',
    'Future premium features included automatically',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            planTitle,
            style: AppTextStyles.titleSmall.copyWith(
              color: const Color(0xFF0B0B0F),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'What you get',
            style: AppTextStyles.labelMedium.copyWith(
              color: const Color(0xFF8B8F97),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...bullets.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: const Color(0xFFFB923C).withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF0B0B0F),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
