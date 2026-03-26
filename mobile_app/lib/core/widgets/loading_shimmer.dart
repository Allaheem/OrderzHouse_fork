// ??? ????????
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({this.width, this.height, this.borderRadius, super.key});

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 20,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class LoadingCardShimmer extends StatelessWidget {
  const LoadingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(width: 200, height: 20),
            SizedBox(height: AppSpacing.sm),
            LoadingShimmer(width: 150, height: 16),
            SizedBox(height: AppSpacing.md),
            LoadingShimmer(height: 16),
            SizedBox(height: AppSpacing.xs),
            LoadingShimmer(height: 16),
          ],
        ),
      ),
    );
  }
}
