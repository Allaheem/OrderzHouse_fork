// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

String _paymentChooserBlurb({
  required bool showAppleOptions,
  required bool showPayPalOption,
  required bool applePayConfiguredForSelectedPlan,
}) {
  if (!showAppleOptions && !showPayPalOption) {
    return 'Complete the company subscription form. Your request will be reviewed.';
  }
  final parts = <String>[
    'Use the company form (reviewed by admin).',
  ];
  if (showPayPalOption) {
    parts.add('You can pay with PayPal.');
  }
  if (showAppleOptions) {
    parts.add(
      applePayConfiguredForSelectedPlan
          ? 'On iOS you can use the App Store for this plan.'
          : 'On iOS, App Store appears when this plan has an App Store product ID.',
    );
  }
  return parts.join(' ');
}

/// Bottom sheet: Subscribe from Company (existing) and optionally App Store (iOS).
///
/// [applePayConfiguredForSelectedPlan] must be true for the Apple button to appear
/// (plan has `apple_product_id` from the API / admin).
void showPaymentMethodChooserSheet({
  required BuildContext context,
  required VoidCallback onSubscribeFromCompany,
  VoidCallback? onPayWithApple,
  VoidCallback? onPayWithPayPal,
  VoidCallback? onRestoreApplePurchases,
  bool showAppleOptions = false,
  bool applePayConfiguredForSelectedPlan = false,
  bool showPayPalOption = false,
  String? selectedPlanName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final bottomInset = MediaQuery.paddingOf(context).bottom;
      final planLabel = (selectedPlanName ?? 'This plan').trim();
      final appleCallback = onPayWithApple;
      final showAppleButton = showAppleOptions &&
          applePayConfiguredForSelectedPlan &&
          appleCallback != null;
      final paypalCallback = onPayWithPayPal;
      final showPayPalButton =
          showPayPalOption && paypalCallback != null;

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Choose payment method',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _paymentChooserBlurb(
                      showAppleOptions: showAppleOptions,
                      showPayPalOption: showPayPalOption,
                      applePayConfiguredForSelectedPlan:
                          applePayConfiguredForSelectedPlan,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSubscribeFromCompany();
                      },
                      icon: const Icon(Icons.business_rounded, size: 22),
                      label: const Text('Subscribe from Company'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (showPayPalButton) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          paypalCallback();
                        },
                        icon: const Icon(Icons.payment_rounded, size: 22),
                        label: const Text('Pay with PayPal'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0070BA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showAppleOptions && !applePayConfiguredForSelectedPlan) ...[
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDBA74)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Colors.orange.shade800, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'App Store is not set up for “$planLabel” yet. '
                                'An admin must add the Apple product ID in the dashboard (Finance → Plans). '
                                'Until then, use Subscribe from Company.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onRestoreApplePurchases != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRestoreApplePurchases();
                        },
                        icon: const Icon(Icons.restore_rounded, size: 20),
                        label: const Text('Restore App Store purchases'),
                      ),
                    ],
                  ],
                  if (showAppleButton) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          appleCallback();
                        },
                        icon: const Icon(Icons.apple_rounded, size: 24),
                        label: const Text('Pay with App Store'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0B0B0F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (onRestoreApplePurchases != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRestoreApplePurchases();
                        },
                        icon: const Icon(Icons.restore_rounded, size: 20),
                        label: const Text('Restore App Store purchases'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '* Annual account verification fee: 25 JD (where applicable).',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
