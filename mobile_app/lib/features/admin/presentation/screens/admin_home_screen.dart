import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/home_header.dart';
import '../../data/admin_web_dashboard_shortcuts.dart';
import '../widgets/admin_webview_body.dart';

/// Home for staff (role_id = 1): full admin web app in-app + native explore/payments/profile.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  late Uri _adminUri;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _adminUri = _defaultAdminUri();
  }

  Uri _defaultAdminUri() {
    final o = AppConfig.adminWebOrigin;
    return Uri.parse('$o/admin');
  }

  void _setWebPath(String path) {
    final o = AppConfig.adminWebOrigin;
    final p = path.startsWith('/') ? path : '/$path';
    setState(() => _adminUri = Uri.parse('$o$p'));
  }

  void _openSectionPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.adminWebJumpToSection,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(l10n.adminWebReloadPage),
                onTap: () {
                  Navigator.pop(ctx);
                  _webController?.reload();
                },
              ),
              const Divider(height: 1),
              ...kAdminWebDashboardShortcuts.map(
                (s) => ListTile(
                  leading: Icon(s.icon, color: AppColors.gradientStart),
                  title: Text(s.titleForLocale(locale)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setWebPath(s.path);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeHeader(roleRoute: '/admin'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminMobileHomeTitle,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminFullDashboardCaption,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: () => _openSectionPicker(context),
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: l10n.adminWebJumpToSection,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AdminWebViewBody(
                    initialUri: _adminUri,
                    onControllerCreated: (c) => _webController = c,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: FilledButton.icon(
              onPressed: () => context.go('/admin/explore'),
              icon: const Icon(Icons.explore_outlined),
              label: Text(l10n.explore),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        items: [
          NavItem(
            icon: Icons.home_outlined,
            title: l10n.home,
            route: '/admin',
          ),
          NavItem(
            icon: Icons.explore_outlined,
            title: l10n.explore,
            route: '/admin/explore',
          ),
          NavItem(
            icon: Icons.payments_outlined,
            title: l10n.payments,
            route: '/admin/payments',
          ),
          NavItem(
            icon: Icons.person_outline,
            title: l10n.profile,
            route: '/admin/profile',
          ),
        ],
      ),
    );
  }
}
