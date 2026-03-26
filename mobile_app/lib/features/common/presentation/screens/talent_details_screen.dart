// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

class TalentDetailsScreen extends StatelessWidget {
  final int freelancerId;

  const TalentDetailsScreen({required this.freelancerId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Freelancer Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Freelancer Name', style: AppTextStyles.headlineLarge),
                  const Text('Rating: 4.5 ⭐'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Freelancer description placeholder...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
