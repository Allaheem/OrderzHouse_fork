// ??? ????????
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/safe_url_launch.dart';

/// Apple auto-renewable subscription disclaimer + legal links (App Store 3.1.2).
class SubscriptionLegalSection extends StatelessWidget {
  const SubscriptionLegalSection({
    super.key,
    required this.showAppleDisclaimer,
    this.padding = const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
  });

  /// When true, shows the mandatory Apple billing / renewal copy (iOS subscriptions).
  final bool showAppleDisclaimer;

  final EdgeInsets padding;

  static const String appleAutoRenewDisclaimer =
      'Payment will be charged to your Apple ID account at confirmation of purchase. '
      'Subscription automatically renews unless canceled at least 24 hours before the end of the current period. '
      'You can manage or cancel your subscription in your App Store account settings.';

  static final Uri privacyPolicyUri = Uri.parse('https://yourdomain.com/privacy');
  static final Uri termsOfUseUri = Uri.parse('https://yourdomain.com/terms');

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchTrustedHttpUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open link. Please try again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTextStyles.labelMedium.copyWith(
      color: const Color(0xFFFB923C),
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFFB923C),
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showAppleDisclaimer) ...[
            Text(
              appleAutoRenewDisclaimer,
              textAlign: TextAlign.left,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              GestureDetector(
                onTap: () => _open(context, privacyPolicyUri),
                child: Text('Privacy Policy', style: linkStyle),
              ),
              Text(' · ', style: linkStyle.copyWith(decoration: TextDecoration.none)),
              GestureDetector(
                onTap: () => _open(context, termsOfUseUri),
                child: Text('Terms of Use', style: linkStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
