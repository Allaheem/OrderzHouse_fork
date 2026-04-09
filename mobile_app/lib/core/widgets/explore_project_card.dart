// ??? ????????
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/project.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';

/// Explore Project Card - Matches reference design exactly
/// - Top image with rounded corners
/// - Star icon overlay in white circle (top-left)
/// - Title on left, PRICE on right (same row)
/// - Description (1-2 lines)
/// - White card, soft shadow, rounded corners
/// - NO overflow (all text properly constrained)
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
    const double imageHeight = 120.0; // Reduced from 140 to make card shorter
    const double cardRadius =
        16.0; // Rounded corners matching screenshot (16-20px range)

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with star overlay
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  // Image
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
                              color: const Color(0xFFE5E7EB), // Light gray
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
                              color: const Color(
                                0xFFE5E7EB,
                              ), // Light gray placeholder
                              child: const Center(
                                child: Icon(
                                  Icons.work_outline_rounded,
                                  color: Color(0xFF6B7280), // Gray icon
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: imageHeight,
                            width: double.infinity,
                            color: const Color(
                              0xFFE5E7EB,
                            ), // Light gray placeholder
                            child: const Center(
                              child: Icon(
                                Icons.work_outline_rounded,
                                color: Color(0xFF6B7280), // Gray icon
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                  // Favorite/Star icon overlay (top-left, white circle)
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

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title and Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (left, flexible)
                      Expanded(
                        child: Text(
                          project.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price (right)
                      Text(
                        project.budgetDisplay,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: const Color(
                            0xFF111827,
                          ), // Near-black, matching screenshot
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Description (1-2 lines)
                  Text(
                    project.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
