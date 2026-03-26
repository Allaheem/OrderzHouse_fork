// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bottom sheet showing change requests/notifications for a project
class ChangeRequestsBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final bool isLoading;

  const ChangeRequestsBottomSheet({
    super.key,
    required this.requests,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: const Color(0xFF111827),
                ),
              ],
            ),
          ),

          // Content
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            )
          else if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No change requests',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final message = request['message'] as String? ?? '';
                  final createdAt = request['created_at'] as String?;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
