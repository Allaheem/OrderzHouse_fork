import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../ui/screenutil_helpers.dart';
import '../utils/text_direction_utils.dart';

/// Short excerpt for project grid cards — readable size, RTL-aware, max 2 lines.
class ProjectCardDescriptionExcerpt extends StatelessWidget {
  const ProjectCardDescriptionExcerpt({
    super.key,
    required this.description,
    required this.emptyHint,
  });

  final String description;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      return Text(
        emptyHint,
        style: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFF9CA3AF),
          fontSize: AppFont.f12,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Directionality(
      textDirection: textDirectionForString(trimmed),
      child: Text(
        trimmed,
        style: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFF374151),
          fontSize: AppFont.f13,
          height: 1.45,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
      ),
    );
  }
}
