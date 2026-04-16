// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/project.dart';
import '../../../../core/widgets/gradient_button.dart';

/// Bottom sheet showing offers for a bidding project (client).
/// [offersNotifier] is updated by the parent when accept/reject succeeds so the list rebuilds.
class OffersBottomSheet extends StatelessWidget {
  final Project project;
  final ValueNotifier<List<Map<String, dynamic>>> offersNotifier;
  final bool isLoading;
  final bool isSubmitting;
  final VoidCallback onClose;
  final Future<void> Function(int offerId, String action)
  onAction; // action: 'accept' or 'reject'

  const OffersBottomSheet({
    super.key,
    required this.project,
    required this.offersNotifier,
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
                    'Offers — ${project.title}',
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

          // Content – listen to offersNotifier so UI updates when accept/reject succeeds
          Flexible(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: offersNotifier,
              builder: (context, offers, _) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  );
                }
                if (offers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No offers submitted for this project yet.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: offers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final offerId =
                        offer['id'] ??
                        offer['offer_id'] ??
                        offer['offerId'] ??
                        0;
                    final userId =
                        offer['user_id'] ??
                        offer['freelancer_id'] ??
                        offer['freelancerId'] ??
                        offerId;
                    final bidAmountRaw =
                        offer['bid_amount'] ??
                        offer['bidAmount'] ??
                        offer['amount'];
                    final bidAmount = bidAmountRaw != null
                        ? (bidAmountRaw is num
                              ? bidAmountRaw.toDouble()
                              : double.tryParse(bidAmountRaw.toString()))
                        : null;
                    final proposal =
                        offer['proposal'] ?? offer['message'] ?? '';
                    final status =
                        (offer['status'] ?? offer['offer_status'] ?? 'pending')
                            .toString()
                            .toLowerCase();

                    final isPending =
                        status == 'pending' ||
                        status == 'pending_client_approval';
                    final isAccepted =
                        status == 'accepted' || status == 'approved';
                    final isRejected =
                        status == 'rejected' || status == 'declined';

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAccepted
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
                                child: Text(
                                  '#$userId',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: const Color(0xFF111827),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isAccepted
                                      ? Colors.green.shade50
                                      : isRejected
                                      ? Colors.red.shade50
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isAccepted
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
                          if (bidAmount != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Bid: ${bidAmount.toStringAsFixed(0)} JOD',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                                                    offerId,
                                                    'reject',
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Offer rejected',
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
                                                      const SnackBar(
                                                        content: Text(
                                                          'Failed to reject offer. Please try again.',
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                    offerId,
                                                    'accept',
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Offer accepted ✅',
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
                                                      const SnackBar(
                                                        content: Text(
                                                          'Failed to accept offer. Please try again.',
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
