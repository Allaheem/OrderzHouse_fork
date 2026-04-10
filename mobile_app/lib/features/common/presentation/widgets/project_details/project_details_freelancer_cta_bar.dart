import 'package:flutter/material.dart';
import 'package:OrderzHouse/core/theme/app_colors.dart';
import 'package:OrderzHouse/core/theme/app_gradients.dart';

class ProjectDetailsFreelancerCtaBar extends StatelessWidget {
  const ProjectDetailsFreelancerCtaBar({
    super.key,
    required this.label,
    required this.isBidding,
    this.requestLoading = false,
    required this.hasApplied,
    required this.isLoading,
    required this.isCheckingApplied,
    required this.onSendOffer,
    required this.onApply,
  });

  final String label;
  final bool isBidding;
  final bool requestLoading;
  final bool hasApplied;
  final bool isLoading;
  final bool isCheckingApplied;
  final VoidCallback onSendOffer;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        requestLoading || hasApplied || isLoading || isCheckingApplied;
    final showSpinner = requestLoading || isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : AppGradients.primaryButton,
          color: isDisabled ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    if (isBidding) {
                      onSendOffer();
                    } else {
                      onApply();
                    }
                  },
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: showSpinner
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey.shade700 : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
