// ??? ????????
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../config/app_config.dart';
import '../models/project.dart';
import '../../l10n/app_localizations.dart';

/// Premium horizontal project card for home dashboard
class HomeProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const HomeProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Debug log for price display (temporary)
    _debugPriceDisplay();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child:
                  project.coverPic != null &&
                      project.coverPic!.isNotEmpty &&
                      AppConfig.baseUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: project.coverPic!.startsWith('http')
                          ? project.coverPic!
                          : '${AppConfig.baseUrl}${project.coverPic}',
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    project.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Budget + Type chips row
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildChip(project.budgetDisplay, AppColors.accentOrange),
                      _buildChip(_getTypeDisplay(l10n), AppColors.info),
                      if (_isUrgent()) _buildChip(l10n.urgent, AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.work_outline_rounded,
          color: AppColors.iconGray,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Removed _getBudgetDisplay() - now using project.budgetDisplay extension
  // Debug log for price display (temporary - remove after verification)
  void _debugPriceDisplay() {
    print(
      '🔍 [HomeProjectCard] Project ID: ${project.id}, Title: ${project.title}',
    );
    print(
      '   Raw fields: budget=${project.budget}, budgetMin=${project.budgetMin}, budgetMax=${project.budgetMax}, hourlyRate=${project.hourlyRate}',
    );
    print('   Project type: ${project.projectType}');
    print('   Final display text: ${project.budgetDisplay}');
  }

  String _getTypeDisplay(AppLocalizations l10n) {
    switch (project.projectType.toLowerCase()) {
      case 'fixed':
        return l10n.fixed;
      case 'hourly':
        return l10n.hourly;
      case 'bidding':
        return l10n.bidding;
      default:
        return project.projectType;
    }
  }

  bool _isUrgent() {
    // Check if project is urgent based on duration or deadline
    // For now, simple heuristic: if durationDays < 5, it's urgent
    return (project.durationDays ?? 99) < 5;
  }
}
