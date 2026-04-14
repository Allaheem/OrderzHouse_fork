// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/legal_content.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _expandAll(List<LegalSection> sections) {
    setState(() {
      for (final s in sections) {
        _expanded[s.id] = true;
      }
    });
  }

  void _collapseAll(List<LegalSection> sections) {
    setState(() {
      for (final s in sections) {
        _expanded[s.id] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final privacyLang =
        locale.languageCode.toLowerCase().startsWith('ar') ? 'ar' : 'en';
    final content = getPrivacyContent(privacyLang);
    final isRtl = locale.languageCode.toLowerCase().startsWith('ar');

    final filtered = _query.isEmpty
        ? content.sections
        : content.sections.where((s) {
            if (s.title.toLowerCase().contains(_query)) return true;
            if (s.body.toLowerCase().contains(_query)) return true;
            for (final b in s.bullets) {
              if (b.toLowerCase().contains(_query)) return true;
            }
            return false;
          }).toList();

    final scrollContent = CustomScrollView(
      slivers: [
        // App bar: back + title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  color: AppColors.accentOrange,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/client/profile');
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    l10n.privacyPolicy,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
        // Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.policySearchHint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        // Expand All / Collapse All
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _expandAll(filtered),
                  icon: const Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: AppColors.accentOrange,
                  ),
                  label: Text(
                    l10n.expandAll,
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _collapseAll(filtered),
                  icon: const Icon(
                    Icons.unfold_less_rounded,
                    size: 18,
                    color: AppColors.accentOrange,
                  ),
                  label: Text(
                    l10n.collapseAll,
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Data Lifecycle card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _LifecycleCard(content: content),
          ),
        ),
        // Accordion sections (ExpansionTile)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = filtered[index];
              final isExpanded = _expanded[section.id] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SectionExpansionTile(
                  section: section,
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (open) {
                    setState(() => _expanded[section.id] = open);
                  },
                ),
              );
            }, childCount: filtered.length),
          ),
        ),
        // Footer (exact web: "Last updated: Jan 2025 — We'll post updates here.")
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xl + 24,
            ),
            child: Center(
              child: Text(
                '${l10n.lastUpdated}: ${content.lastUpdated}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final boundedScroll = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppContentLayout.contentMaxWidth(context),
        ),
        child: scrollContent,
      ),
    );

    // English policy in an RTL app: force LTR so paragraphs read correctly.
    // Arabic policy: use normal layout so Arabic sections render RTL.
    final forceLtrForEnglishPolicy = isRtl && privacyLang == 'en';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: forceLtrForEnglishPolicy
            ? Directionality(
                textDirection: TextDirection.ltr,
                child: boundedScroll,
              )
            : boundedScroll,
      ),
    );
  }
}

class _LifecycleCard extends StatelessWidget {
  final PrivacyContent content;

  const _LifecycleCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.lifecycleTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content.lifecycleSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < content.lifecycleSteps.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.accentOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColorLight,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.lifecycleSteps[i].title,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        content.lifecycleSteps[i].desc,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionExpansionTile extends StatelessWidget {
  final LegalSection section;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const _SectionExpansionTile({
    required this.section,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
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
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColorLight,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.description_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          section.title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          if (section.body.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                bottom: section.bullets.isEmpty ? 0 : AppSpacing.md,
              ),
              child: Text(
                section.body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          if (section.bullets.isNotEmpty)
            ...section.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
