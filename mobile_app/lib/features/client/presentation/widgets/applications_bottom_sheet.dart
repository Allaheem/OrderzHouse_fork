// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/project.dart';
import '../../../../core/widgets/gradient_button.dart';

/// Bottom sheet showing applications for a project (client - fixed/hourly)
class ApplicationsBottomSheet extends StatelessWidget {
  final Project project;
  final List<Map<String, dynamic>> applications;
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onClose;
  final Future<void> Function(int assignmentId, int projectId, String action)
  onAction; // action: 'accept' or 'reject'

  const ApplicationsBottomSheet({
    super.key,
    required this.project,
    required this.applications,
    required this.isLoading,
    required this.isSubmitting,
    required this.onClose,
    required this.onAction,
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
                Expanded(
                  child: Text(
                    'Freelancer applications — ${project.title}',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                  color: const Color(0xFF111827),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  )
                : applications.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No applications yet.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: applications.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final app = applications[index];
                      final freelancerName =
                          app['freelancer_name'] ??
                          app['freelancerName'] ??
                          app['name'] ??
                          'Freelancer';
                      final freelancerIdRaw =
                          app['freelancer_id'] ?? app['freelancerId'];
                      final freelancerId = freelancerIdRaw is int
                          ? freelancerIdRaw
                          : (freelancerIdRaw is num
                                ? freelancerIdRaw.toInt()
                                : int.tryParse(
                                    freelancerIdRaw?.toString() ?? '',
                                  ));
                      final proposal =
                          app['proposal'] ??
                          app['message'] ??
                          app['cover_letter'] ??
                          '';
                      final status = app['status'] ?? 'pending';
                      final assignmentId =
                          app['assignment_id'] ??
                          app['assignmentId'] ??
                          app['id'] ??
                          0;

                      final isPending =
                          status == 'pending' ||
                          status == 'pending_client_approval';
                      final isActive =
                          status == 'active' || status == 'accepted';
                      final isRejected =
                          status == 'rejected' || status == 'not_chosen';

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade200
                                : isRejected
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          freelancerName,
                                          style: AppTextStyles.titleMedium
                                              .copyWith(
                                                color: const Color(0xFF111827),
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (freelancerId != null &&
                                          freelancerId > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '#$freelancerId',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                color: const Color(0xFF6B7280),
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.shade50
                                        : isRejected
                                        ? Colors.red.shade50
                                        : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: isActive
                                          ? Colors.green.shade700
                                          : isRejected
                                          ? Colors.red.shade700
                                          : Colors.amber.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (proposal.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                proposal,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (isPending) ...[
                              const SizedBox(height: AppSpacing.md),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: OutlinedButton(
                                          onPressed: isSubmitting
                                              ? null
                                              : () async {
                                                  try {
                                                    await onAction(
                                                      assignmentId,
                                                      project.id,
                                                      'reject',
                                                    );
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Application rejected',
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed: $e',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF111827,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE5E7EB),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: GradientButton(
                                          onPressed: isSubmitting
                                              ? null
                                              : () async {
                                                  try {
                                                    await onAction(
                                                      assignmentId,
                                                      project.id,
                                                      'accept',
                                                    );
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Application accepted ✅',
                                                          ),
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed: $e',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                          label: 'Accept',
                                          isLoading: isSubmitting,
                                          height: 44,
                                          borderRadius: 8,
                                        ),
                                      ),
                                    ),
                                  ],
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
}
