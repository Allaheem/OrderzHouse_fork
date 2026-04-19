// ??? ????????
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/project.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/widgets/project_card_description_excerpt.dart';
import '../../../../l10n/app_localizations.dart';

/// Custom project card for Client MyProjects screen
/// Clean list view - actions moved to Project Details
class ClientProjectCard extends StatelessWidget {
  final Project project;
  final Map<String, dynamic>?
  projectData; // Raw JSON data for additional fields
  final VoidCallback onTap;

  const ClientProjectCard({
    super.key,
    required this.project,
    this.projectData,
    required this.onTap,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: ClipRRect(
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ProjectCardDescriptionExcerpt(
                          description: project.description,
                          emptyHint: l10n.projectCardOpenForFullDescription,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          project.status.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                            fontSize: AppFont.f11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
