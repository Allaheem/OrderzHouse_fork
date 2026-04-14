// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/ui/screenutil_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/storage/app_prefs.dart';

// Notification preferences providers
final masterNotificationsEnabledProvider = StateProvider<bool>((ref) => true);
final projectUpdatesEnabledProvider = StateProvider<bool>((ref) => true);
final messagesEnabledProvider = StateProvider<bool>((ref) => true);
final paymentsEnabledProvider = StateProvider<bool>((ref) => true);
final promotionsEnabledProvider = StateProvider<bool>((ref) => false);

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreferences());
  }

  Future<void> _loadPreferences() async {
    if (_prefsLoaded) return;
    try {
      final master = await AppPrefs.getNotificationsMaster();
      final projects = await AppPrefs.getNotificationsProjects();
      final messages = await AppPrefs.getNotificationsMessages();
      final payments = await AppPrefs.getNotificationsPayments();
      final offers = await AppPrefs.getNotificationsOffers();
      if (mounted) {
        ref.read(masterNotificationsEnabledProvider.notifier).state = master;
        ref.read(projectUpdatesEnabledProvider.notifier).state = projects;
        ref.read(messagesEnabledProvider.notifier).state = messages;
        ref.read(paymentsEnabledProvider.notifier).state = payments;
        ref.read(promotionsEnabledProvider.notifier).state = offers;
        _prefsLoaded = true;
      }
    } catch (_) {}
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  Future<void> _savePreferences(WidgetRef ref) async {
    try {
      await AppPrefs.setNotificationsMaster(
        ref.read(masterNotificationsEnabledProvider),
      );
      await AppPrefs.setNotificationsProjects(
        ref.read(projectUpdatesEnabledProvider),
      );
      await AppPrefs.setNotificationsMessages(
        ref.read(messagesEnabledProvider),
      );
      await AppPrefs.setNotificationsPayments(
        ref.read(paymentsEnabledProvider),
      );
      await AppPrefs.setNotificationsOffers(
        ref.read(promotionsEnabledProvider),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterEnabled = ref.watch(masterNotificationsEnabledProvider);
    final projectUpdates = ref.watch(projectUpdatesEnabledProvider);
    final messages = ref.watch(messagesEnabledProvider);
    final payments = ref.watch(paymentsEnabledProvider);
    final l10n = AppLocalizations.of(context)!;

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
                AppHeader(
                  title: l10n.notifications,
                  onBack: () => _handleBack(context),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Master Toggle Card
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.enableNotifications,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.notificationsSubtitle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: masterEnabled,
                            onChanged: (value) {
                              ref
                                      .read(
                                        masterNotificationsEnabledProvider
                                            .notifier,
                                      )
                                      .state =
                                  value;
                              _savePreferences(ref);
                            },
                            activeThumbColor: AppColors.accentOrange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Category toggles (only show if master enabled)
                    if (masterEnabled) ...[
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
                          children: [
                            _NotificationCategoryTile(
                              title: l10n.projects,
                              subtitle: l10n.noProjectsMessage,
                              value: projectUpdates,
                              onChanged: (value) {
                                ref
                                        .read(
                                          projectUpdatesEnabledProvider
                                              .notifier,
                                        )
                                        .state =
                                    value;
                                _savePreferences(ref);
                              },
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _NotificationCategoryTile(
                              title: l10n.messages,
                              subtitle: l10n.noNotificationsMessage,
                              value: messages,
                              onChanged: (value) {
                                ref
                                        .read(messagesEnabledProvider.notifier)
                                        .state =
                                    value;
                                _savePreferences(ref);
                              },
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            _NotificationCategoryTile(
                              title: l10n.payments,
                              subtitle: l10n.transactionHistory,
                              value: payments,
                              onChanged: (value) {
                                ref
                                        .read(paymentsEnabledProvider.notifier)
                                        .state =
                                    value;
                                _savePreferences(ref);
                              },
                            ),
                            // العروض / Invite friends — مخفي حسب الطلب
                            // const Divider(height: 1, color: AppColors.borderLight),
                            // _NotificationCategoryTile(
                            //   title: l10n.offers,
                            //   subtitle: l10n.inviteFriends,
                            //   value: promotions,
                            //   onChanged: (value) {
                            //     ref.read(promotionsEnabledProvider.notifier).state = value;
                            //     _savePreferences(ref);
                            //   },
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ],
                    ),
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

class _NotificationCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationCategoryTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentOrange,
          ),
        ],
      ),
    );
  }
}
