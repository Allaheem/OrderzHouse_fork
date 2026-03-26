// ??? ????????
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';

/// Survey / offline subscription flow (same as web: opens external survey URL).
/// Route: /account-survey?planId=...
class AccountSurveyScreen extends StatelessWidget {
  final String? planId;

  const AccountSurveyScreen({super.key, this.planId});

  @override
  Widget build(BuildContext context) {
    final baseUrl = AppConfig.companySubscribeUrl;
    final uri = planId != null && planId!.isNotEmpty
        ? Uri.parse('$baseUrl?planId=$planId')
        : Uri.parse(baseUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe from Company'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'You will be redirected to complete the subscription survey with your company.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openSurvey(context, uri),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Survey'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSurvey(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open survey link. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
