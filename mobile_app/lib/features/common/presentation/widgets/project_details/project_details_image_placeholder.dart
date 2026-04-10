import 'package:flutter/material.dart';
import 'package:OrderzHouse/core/theme/app_colors.dart';

class ProjectDetailsImagePlaceholder extends StatelessWidget {
  const ProjectDetailsImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.work_outline_rounded, color: Colors.white, size: 64),
      ),
    );
  }
}
