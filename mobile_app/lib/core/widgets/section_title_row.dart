// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

/// Premium section title row with optional "See All" button
class SectionTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllTap;

  const SectionTitleRow({super.key, required this.title, this.onSeeAllTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Row(
                children: [
                  Text(
                    l10n.seeAll,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accentOrange,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
