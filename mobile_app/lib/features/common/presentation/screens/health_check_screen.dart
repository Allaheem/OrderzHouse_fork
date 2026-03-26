// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/health_check_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class HealthCheckScreen extends ConsumerStatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  ConsumerState<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends ConsumerState<HealthCheckScreen> {
  bool _isLoading = false;
  HealthCheckResult? _result;

  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await HealthCheckService.ping();

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Check')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Base URL display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API Configuration', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Base URL: ${AppConfig.baseUrl}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Environment: ${AppConfig.environment}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Health check result
            if (_result != null)
              Card(
                color: _result!.success
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _result!.success ? Icons.check_circle : Icons.error,
                            color: _result!.success ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _result!.success
                                ? 'API Reachable'
                                : 'API Unreachable',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: _result!.success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (_result!.endpoint != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Endpoint: ${_result!.endpoint}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                      if (_result!.statusCode != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Status Code: ${_result!.statusCode}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(_result!.message, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  const Icon(Icons.health_and_safety, size: 64),
                  const SizedBox(height: AppSpacing.lg),
                  Text('API Health Check', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Test connectivity to the API server',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            const Spacer(),
            PrimaryButton(
              label: _isLoading ? 'Checking...' : 'Check API Health',
              onPressed: _isLoading ? null : _checkHealth,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
