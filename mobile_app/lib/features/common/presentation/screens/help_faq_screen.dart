// ??? ????????
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/app_header.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _expandedItems = {};

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I post a project?',
      'answer':
          'To post a project, navigate to the "My Projects" screen and tap the "Add Project" button. Fill in the project details including title, description, budget, and deadline. Once submitted, your project will be visible to freelancers who can apply.',
    },
    {
      'question': 'How do I apply to a project?',
      'answer':
          'Browse available projects on the "Explore" screen. Tap on a project you\'re interested in to view details, then tap "Send Offer" or "Apply". Include your proposed budget, timeline, and any relevant information about why you\'re a good fit.',
    },
    {
      'question': 'How do payments work?',
      'answer':
          'Payments are processed securely through our platform. Clients can pay for projects using supported payment methods. Funds are held in escrow until work is completed and approved. Freelancers receive payment after project delivery is accepted.',
    },
    {
      'question': 'How do I deliver work?',
      'answer':
          'Once your work is complete, go to the project details page and tap "Deliver Work". Upload your deliverables, add any notes, and submit. The client will be notified and can review your submission.',
    },
    {
      'question': 'How do I request changes / accept delivery?',
      'answer':
          'When a freelancer delivers work, you\'ll receive a notification. Review the delivery on the project page. You can either "Approve" to complete the project and release payment, or "Request Changes" if revisions are needed.',
    },
    {
      'question': 'How do I edit my profile?',
      'answer':
          'Go to your Profile screen and tap "Edit Profile". You can update your name, bio, profile picture, skills, and other information. Changes are saved automatically.',
    },
    {
      'question': 'How do subscriptions (Plans) work for freelancers?',
      'answer':
          'Freelancers use the free plan in the app. To get a verified account after you have used the free plan, open Subscription in your profile and tap "Verify account" to book a short interview with our team. Paid subscription tiers are not sold inside the mobile app.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedItems[index] = !(_expandedItems[index] ?? false);
    });
  }

  void _handleContactSupport() {
    context.push('/support');
  }

  List<Map<String, String>> get _filteredFaqs {
    if (_searchController.text.isEmpty) {
      return _faqs;
    }
    final query = _searchController.text.toLowerCase();
    return _faqs
        .where(
          (faq) =>
              faq['question']!.toLowerCase().contains(query) ||
              faq['answer']!.toLowerCase().contains(query),
        )
        .toList();
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/client/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredFaqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppContentLayout.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                // Header
                AppHeader(title: l10n.helpFaq, onBack: _handleBack),
                // Search Bar
                Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.searchHelp,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
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
                ),
              ),

                // FAQ List
                Expanded(
              child: filteredFaqs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.noResultsFound,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: filteredFaqs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final faqIndex = _faqs.indexOf(filteredFaqs[index]);
                        final isExpanded = _expandedItems[faqIndex] ?? false;
                        return _FaqCard(
                          question: filteredFaqs[index]['question']!,
                          answer: filteredFaqs[index]['answer']!,
                          isExpanded: isExpanded,
                          onTap: () => _toggleExpanded(faqIndex),
                        );
                      },
                    ),
                ),

                // Contact Support Button
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.md,
                    bottom:
                        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                  ),
                  child: PrimaryGradientButton(
                    onPressed: _handleContactSupport,
                    label: l10n.contactSupport,
                    isLoading: false,
                    height: 54,
                    borderRadius: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqCard({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
