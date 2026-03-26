// ??? ????????
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_text_styles.dart';
import '../models/payment.dart';

/// Reusable transaction tile widget
class TransactionTile extends StatelessWidget {
  final Payment payment;
  final bool isClient;

  const TransactionTile({
    super.key,
    required this.payment,
    this.isClient = true,
  });

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'paid' || s == 'success' || s == 'succeeded' || s == 'completed') {
      return Colors.green;
    }
    if (s == 'pending' || s == 'processing' || s == 'in_review') {
      return Colors.orange;
    }
    if (s == 'failed' ||
        s == 'canceled' ||
        s == 'cancelled' ||
        s == 'refunded') {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _getDisplayTitle() {
    if (isClient) {
      if (payment.projectTitle != null && payment.projectTitle!.isNotEmpty) {
        return payment.projectTitle!;
      }
      if (payment.purpose != null && payment.purpose!.isNotEmpty) {
        return payment.purpose!.toUpperCase();
      }
      return 'Payment';
    } else {
      // Freelancer
      if (payment.note != null && payment.note!.isNotEmpty) {
        return payment.note!;
      }
      if (payment.type != null && payment.type!.isNotEmpty) {
        return payment.type!.toUpperCase();
      }
      return 'Transaction';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(payment.status);
    final displayTitle = _getDisplayTitle();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.status.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(payment.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (payment.type != null && !isClient) ...[
                const SizedBox(height: 4),
                Text(
                  payment.type!.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: payment.type == 'credit' ? Colors.green : Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
