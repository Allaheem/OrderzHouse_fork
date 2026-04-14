// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/projects_repository.dart';

class ProjectSuccessScreen extends ConsumerStatefulWidget {
  final int projectId;

  const ProjectSuccessScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectSuccessScreen> createState() =>
      _ProjectSuccessScreenState();
}

/// Default CliQ alias when not set from API/env.
const String _defaultCliqAlias = 'Batman0';

class _ProjectSuccessScreenState extends ConsumerState<ProjectSuccessScreen> {
  Map<String, dynamic>? _project;
  bool _loading = true;
  String? _error;
  bool _paymentSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final repo = ProjectsRepository();
      final response = await repo.getProjectSuccess(widget.projectId);
      if (!mounted) return;
      final data =
          response.success && response.data != null && response.data!.isNotEmpty
          ? response.data
          : null;
      if (data != null) {
        _project = data;
        _error = null;
      } else {
        _error = response.message ?? 'Failed to load project';
      }
    } catch (e) {
      if (mounted) _error = 'Failed to load project';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatBudget(Map<String, dynamic>? p) {
    if (p == null) return '—';
    final t = p['project_type'];
    if (t == 'fixed') return '${p['budget'] ?? '—'}';
    if (t == 'hourly') return '${p['hourly_rate'] ?? '—'}/hr';
    if (t == 'bidding') {
      final amount = p['accepted_offer_amount'];
      if (amount != null)
        return amount is num
            ? amount.toStringAsFixed(
                amount.truncateToDouble() == amount ? 0 : 2,
              )
            : amount.toString();
      return '${p['budget_min'] ?? '—'} - ${p['budget_max'] ?? '—'}';
    }
    return '—';
  }

  String _formatPaymentMethod(String? method) {
    if (method == null) return '—';
    switch (method) {
      case 'cliq':
        return 'CliQ';
      case 'cash':
        return 'Cash';
      case 'skipped':
        return 'Skipped';
      case 'stripe':
        return 'Stripe';
      default:
        return method.isNotEmpty
            ? '${method[0].toUpperCase()}${method.substring(1)}'
            : '—';
    }
  }

  Future<void> _openWhatsApp() async {
    if (_project == null) return;
    final p = _project!;
    final id = p['id'];
    final title = p['title'] as String? ?? '—';
    final budgetText = _formatBudget(p);
    final paymentMethod = _formatPaymentMethod(p['payment_method'] as String?);
    final approvalStatus = p['admin_approval_status'] as String?;
    final categoryInfo = p['category_name'] != null
        ? (p['sub_sub_category_name'] != null
              ? '${p['category_name']} / ${p['sub_sub_category_name']}'
              : p['category_name'] as String?)
        : null;
    String? durationText;
    if (p['duration_days'] != null && (p['duration_days'] as num) > 0) {
      durationText = '${p['duration_days']} days';
    } else if (p['duration_hours'] != null &&
        (p['duration_hours'] as num) > 0) {
      durationText = '${p['duration_hours']} hours';
    }
    final skills = p['preferred_skills'];
    final skillsJoined = skills is List
        ? skills.join(', ')
        : (skills?.toString() ?? '—');
    final desc = p['description'] as String?;
    final shortDescription = desc != null
        ? (desc.length > 200 ? '${desc.substring(0, 200)}...' : desc)
        : '—';

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final projectIdInt = id is int ? id : int.tryParse(id.toString()) ?? 0;
    final message = buildProjectSuccessWhatsAppMessage(
      projectId: projectIdInt,
      title: title,
      budgetText: budgetText,
      paymentMethod: paymentMethod,
      approvalStatus: approvalStatus,
      categoryInfo: categoryInfo,
      durationText: durationText,
      skillsJoined: skillsJoined,
      shortDescription: shortDescription,
      isArabic: isArabic,
    );
    final launched = await launchWhatsAppWithMessage(message);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.loading, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? l10n.error, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.go('/client'),
                  child: Text(l10n.back),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _project!;
    final paymentMethod = p['payment_method'] as String?;
    final adminStatus = p['admin_approval_status'] as String?;
    final status = (p['status'] as String? ?? '').toString().toLowerCase();
    final isBidding =
        (p['project_type'] as String? ?? '').toString().toLowerCase() ==
        'bidding';
    final showPaymentChooser =
        isBidding &&
        (status == 'pending_admin_approval' || adminStatus == 'pending') &&
        (paymentMethod == null || paymentMethod == 'skipped');
    final isCliq = paymentMethod == 'cliq';
    final cliqDisplay =
        p['cliq_alias'] as String? ??
        p['cliq_number'] as String? ??
        _defaultCliqAlias;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFB923C), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 32,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.projectCreated,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your project has been created and submitted for review.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (adminStatus == 'pending' || isCliq) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.amber.shade800,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          showPaymentChooser
                              ? 'Choose payment method (CliQ or Cash). After payment, admin will review your request.'
                              : 'Your project will be created but will remain hidden until admin approves your payment.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showPaymentChooser) ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your payment method to complete the project posting.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p['title'] ?? '—',
                              style: const TextStyle(color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Amount: ${_formatBudget(p)} JOD',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA580C),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _paymentSubmitting
                              ? null
                              : () async {
                                  setState(() => _paymentSubmitting = true);
                                  final repo = ProjectsRepository();
                                  final res = await repo
                                      .setProjectOfflinePayment(
                                        widget.projectId,
                                        'cliq',
                                      );
                                  if (!mounted) return;
                                  setState(() => _paymentSubmitting = false);
                                  if (res.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'CliQ selected. Waiting for admin approval.',
                                        ),
                                      ),
                                    );
                                    await _load(showLoading: false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          res.message ??
                                              'Failed to set payment method',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppColors.accentOrange,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_paymentSubmitting)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.phone_android,
                                  color: AppColors.accentOrange,
                                ),
                              const SizedBox(width: 10),
                              const Text('Pay via CliQ'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _paymentSubmitting
                              ? null
                              : () async {
                                  setState(() => _paymentSubmitting = true);
                                  final repo = ProjectsRepository();
                                  final res = await repo
                                      .setProjectOfflinePayment(
                                        widget.projectId,
                                        'cash',
                                      );
                                  if (!mounted) return;
                                  setState(() => _paymentSubmitting = false);
                                  if (res.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cash selected. Waiting for admin approval.',
                                        ),
                                      ),
                                    );
                                    await _load(showLoading: false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          res.message ??
                                              'Failed to set payment method',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppColors.accentOrange,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_paymentSubmitting)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.payments,
                                  color: AppColors.accentOrange,
                                ),
                              const SizedBox(width: 10),
                              const Text('Pay Cash'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.projectDetails,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _row('Project ID', '#${p['id']}'),
                      _row('Title', p['title'] ?? '—'),
                      _row(l10n.amountLabel, '${_formatBudget(p)} JOD'),
                      _row(
                        'Payment method',
                        _formatPaymentMethod(paymentMethod),
                      ),
                      if (isCliq) _row('CliQ transfer to', cliqDisplay),
                      if (p['category_name'] != null)
                        _row(
                          l10n.categoryLabel,
                          p['category_name'] as String? ?? '—',
                        ),
                      if (p['created_at'] != null)
                        _row('Created', _formatDate(p['created_at'])),
                    ],
                  ),
                ),
                if (isCliq) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer to: $cliqDisplay',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEA580C),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please send a screenshot of your CliQ payment on WhatsApp to confirm your payment.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.chat, size: 22),
                    label: const Text('Send on WhatsApp'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/client'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Go to My Projects'),
                  ),
                ),
              ],
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    try {
      final d = DateTime.tryParse(v.toString());
      return d != null
          ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
          : '—';
    } catch (_) {
      return '—';
    }
  }
}
