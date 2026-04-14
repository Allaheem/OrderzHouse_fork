// ??? ????????
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../config/app_config.dart';
import '../models/project.dart';
import '../../l10n/app_localizations.dart';
import '../ui/screenutil_helpers.dart';

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
    final cardW = AppContentLayout.homeProjectCardWidth(context);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          final tightHeight = maxH.isFinite;

          final imageHeight = tightHeight
              ? (maxH * 0.42).clamp(64.0, 100.0)
              : 100.0;

          final imageSection = ClipRRect(
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
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _buildPlaceholder(imageHeight),
                  )
                : _buildPlaceholder(imageHeight),
          );

          return Container(
            width: cardW,
            height: tightHeight ? maxH : null,
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
            child: tightHeight
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: imageSection,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.sm,
                                  AppSpacing.md,
                                  0,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    project.title,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              child: _buildChipsRow(l10n),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: imageSection,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              project.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            _buildChipsRow(l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
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

  Widget _buildChipsRow(AppLocalizations l10n) {
    return SizedBox(
      height: 30,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildChip(project.budgetDisplay, AppColors.accentOrange),
              const SizedBox(width: AppSpacing.xs),
              _buildChip(_getTypeDisplay(l10n), AppColors.info),
              if (_isUrgent()) ...[
                const SizedBox(width: AppSpacing.xs),
                _buildChip(l10n.urgent, AppColors.error),
              ],
            ],
          ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
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
    return (project.durationDays ?? 99) < 5;
  }
}
