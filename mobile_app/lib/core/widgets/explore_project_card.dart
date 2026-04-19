// ??? ????????
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/project.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/screenutil_helpers.dart';
import '../../core/widgets/project_card_description_excerpt.dart';
import '../../l10n/app_localizations.dart';

/// Explore Project Card — readable typography, RTL-aware excerpt, bounded text (no grid overflow).
class ExploreProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const ExploreProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const double imageHeight = 120.0;
    const double cardRadius = 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(cardRadius),
                      topRight: Radius.circular(cardRadius),
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
                            placeholder: (context, url) => Container(
                              height: imageHeight,
                              width: double.infinity,
                              color: const Color(0xFFE5E7EB),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: imageHeight,
                              width: double.infinity,
                              color: const Color(0xFFE5E7EB),
                              child: const Center(
                                child: Icon(
                                  Icons.work_outline_rounded,
                                  color: Color(0xFF6B7280),
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: imageHeight,
                            width: double.infinity,
                            color: const Color(0xFFE5E7EB),
                            child: const Center(
                              child: Icon(
                                Icons.work_outline_rounded,
                                color: Color(0xFF6B7280),
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isFavorite
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF111827),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: AppFont.f15,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        project.budgetDisplay,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontSize: AppFont.f13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProjectCardDescriptionExcerpt(
                    description: project.description,
                    emptyHint: l10n.projectCardOpenForFullDescription,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
