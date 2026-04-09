// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_button.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedSubjectKey = 'account';
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  Future<void> _copyEmail() async {
    final l10n = AppLocalizations.of(context)!;
    const email = 'info@battechno.com';
    await Clipboard.setData(const ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.copiedToClipboard),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openMailto() async {
    final l10n = AppLocalizations.of(context)!;
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@battechno.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      }
    }
  }

  Future<void> _handleSend() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final subjectLabel = _getSelectedLabel(l10n);
      final subject = Uri.encodeComponent(
        '[OrderzHouse] $subjectLabel',
      );
      final body = Uri.encodeComponent(_messageController.text.trim());
      final mailto = Uri.parse(
        'mailto:info@battechno.com?subject=$subject&body=$body',
      );

      if (await canLaunchUrl(mailto)) {
        await launchUrl(mailto);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageSent),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _messageController.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  List<Map<String, String>> _getSubjects(AppLocalizations l10n) {
    return [
      {'key': 'account', 'label': l10n.profile},
      {'key': 'payments', 'label': l10n.payments},
      {'key': 'projects', 'label': l10n.projects},
      {'key': 'bug', 'label': l10n.error},
      {'key': 'other', 'label': l10n.other},
    ];
  }

  String _getSelectedLabel(AppLocalizations l10n) {
    final subjects = _getSubjects(l10n);
    return subjects.firstWhere(
      (s) => s['key'] == _selectedSubjectKey,
      orElse: () => subjects.first,
    )['label']!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subjects = _getSubjects(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(title: l10n.support, onBack: _handleBack),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Support Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColorLight,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.howCanWeHelp,
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.supportSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Email Support Card
                      _EmailSupportCard(
                        onCopy: _copyEmail,
                        onOpenMailto: _openMailto,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // In-app Form Card
                      _InAppFormCard(
                        selectedSubject: _getSelectedLabel(l10n),
                        subjects: subjects,
                        messageController: _messageController,
                        onSubjectChanged: (value) {
                          setState(() => _selectedSubjectKey = value!);
                        },
                        l10n: l10n,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Send Button
                      PrimaryGradientButton(
                        onPressed: _isSending ? null : _handleSend,
                        label: l10n.submit,
                        isLoading: _isSending,
                        height: 54,
                        borderRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSupportCard extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onOpenMailto;

  const _EmailSupportCard({required this.onCopy, required this.onOpenMailto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onOpenMailto,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                color: AppColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'info@battechno.com',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              color: AppColors.textSecondary,
              onPressed: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}

class _InAppFormCard extends StatelessWidget {
  final String selectedSubject;
  final List<Map<String, String>> subjects;
  final TextEditingController messageController;
  final ValueChanged<String?> onSubjectChanged;
  final AppLocalizations l10n;

  const _InAppFormCard({
    required this.selectedSubject,
    required this.subjects,
    required this.messageController,
    required this.onSubjectChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sendMessage,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Subject dropdown
          DropdownButtonFormField<String>(
            initialValue: subjects.firstWhere(
              (s) => s['label'] == selectedSubject,
              orElse: () => subjects.first,
            )['key'],
            decoration: InputDecoration(
              labelText: l10n.category,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentOrange,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            items: subjects.map((subject) {
              return DropdownMenuItem(
                value: subject['key'],
                child: Text(subject['label']!),
              );
            }).toList(),
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          // Message field
          TextFormField(
            controller: messageController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.yourMessage,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              hintText: l10n.describeYourProject,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentOrange,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.fieldRequired;
              }
              if (value.trim().length < 10) {
                return l10n.minLength(10);
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
