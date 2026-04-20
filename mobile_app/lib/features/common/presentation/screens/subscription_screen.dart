// ??? ????????
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/safe_url_launch.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/token_refresh_coordinator.dart';
import '../../../plans/presentation/providers/plans_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscriptions/data/repositories/subscription_repository.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../subscriptions/presentation/screens/eclick_checkout_webview_screen.dart';
import '../../../subscriptions/presentation/widgets/payment_method_chooser_sheet.dart';
import '../../../../core/models/plan.dart';
import '../../../../l10n/app_localizations.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int _selectedTab = 0; // 0 = Plans, 1 = FAQ (UI only)

  // App Store Connect product ids (fallback if backend plan lacks apple_product_id)
  static const String _appleMonthlyProductId = 'com.orderzhouse.plan.onemonth';
  static const String _appleYearlyProductId = 'com.orderzhouse.plan.oneyear';

  /// One-shot: refresh access token before subscription/eClick calls if JWT is near expiry.
  bool _didProactiveTokenRefresh = false;

  StreamSubscription<List<PurchaseDetails>>? _iosPurchaseSub;
  bool _iosPurchaseListenerAttached = false;
  Plan? _pendingApplePlan;

  /// Freelancer free-plan activation in flight (`POST /plans/subscribe`).
  int? _activatingFreelancerPlanId;

  /// Xcode sets these when the app runs on the **iOS Simulator** (not on a physical device).
  bool _isRunningOnIosSimulator() {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final e = Platform.environment;
      return e['SIMULATOR_DEVICE_NAME'] != null ||
          e['SIMULATOR_UDID'] != null;
    } catch (_) {
      return false;
    }
  }

  void _showIosSimulatorIapUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'App Store billing does not work on the iOS Simulator '
          '(StoreKit channel fails). Use a real iPhone/iPad, or add a '
          'StoreKit Configuration in Xcode for simulator testing.',
          style: TextStyle(height: 1.35),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 8),
      ),
    );
  }

  /// StoreKit is flaky on **iOS Simulator** (Pigeon `channel-error`). Attach only when user
  /// taps Apple Pay / Restore — avoids crashes on screen open and matches real-device flow.
  void _attachIosPurchaseListenerIfNeeded() {
    if (!Platform.isIOS || _iosPurchaseListenerAttached) return;
    if (_isRunningOnIosSimulator()) {
      return;
    }
    runZonedGuarded(
      () {
        _iosPurchaseSub = InAppPurchase.instance.purchaseStream.listen(
          _onIosPurchaseUpdated,
          onError: (Object e, StackTrace st) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Purchase stream error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
        _iosPurchaseListenerAttached = true;
      },
      (Object error, StackTrace stack) {
        if (!mounted) return;
        _showStoreKitBridgeErrorSnack(error);
      },
    );
  }

  void _showStoreKitBridgeErrorSnack(Object e) {
    if (!mounted) return;
    final raw = e is PlatformException ? (e.message ?? e.code) : '$e';
    final lower = raw.toLowerCase();
    final isChannel = lower.contains('channel');
    final isPlatformResponseFail =
        lower.contains('failed to get response from platform');
    final msg = (isChannel || isPlatformResponseFail)
        ? 'App Store billing is currently unavailable on this device/session. '
            'On real devices, sign out/in App Store Sandbox account and retry. '
            'If it still fails, verify the product ID is approved in App Store Connect.'
        : '$e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  void dispose() {
    _pendingApplePlan = null;
    _iosPurchaseSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didProactiveTokenRefresh) return;
    _didProactiveTokenRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        TokenRefreshCoordinator.refreshIfExpiringSoon(DioClient.instance),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(plansProvider);
    final authState = ref.watch(authStateProvider);
    final eClickCheckoutAsync = ref.watch(eClickCheckoutAvailableProvider);
    final eClickEnabledOnServer = eClickCheckoutAsync.valueOrNull == true;
    final user = authState.user;
    final isFreelancer = user?.roleId == 3;
    final isIos = !kIsWeb && Platform.isIOS;

    return AppScaffold(
      body: Column(
        children: [
          // Custom Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button in circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: const Color(0xFF0B0B0F), // Near-black primary
                      onPressed: () {
                        // Safe back navigation
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // Fallback: navigate to home/profile based on role
                          final userRoleId = user?.roleId ?? 0;
                          if (userRoleId == 2) {
                            context.go('/client');
                          } else if (userRoleId == 3) {
                            context.go('/freelancer');
                          } else {
                            context.go('/client');
                          }
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    isFreelancer ? l10n.freePlan : 'Plans',
                    style: const TextStyle(
                      color: Color(0xFF0B0B0F), // Near-black primary
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  // iOS: show Restore Purchases entry point (required by App Review)
                  if (isIos && !isFreelancer)
                    IconButton(
                      tooltip: 'Restore purchases',
                      icon: const Icon(Icons.restore_rounded),
                      color: const Color(0xFF0B0B0F),
                      onPressed: _restoreApplePurchases,
                    )
                  else
                    const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
          ),

          // B) Pill Segmented Control (centered, under header)
          _buildPillSegmentedControl(),

          // C) Section Header Row
          _buildSectionHeader(isFreelancer ? l10n.freePlan : 'Plans'),

          // D) Main Content (Big Container with Plans)
          Expanded(
            child: plansAsync.when(
              loading: () => const Center(child: LoadingShimmer()),
              error: (err, stack) => Center(
                child: ErrorState(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(plansProvider),
                ),
              ),
              data: (plans) {
                bool isAllowedDisplayPlan(Plan p) {
                  if (p.price <= 0) return true; // keep free plan(s)
                  final t = p.planType.toLowerCase().trim();
                  if (t == 'monthly' && p.duration == 1) return true;
                  if (t == 'yearly' && p.duration == 1) return true;
                  return false; // hide multi-year tiers (e.g. 2 years)
                }

                // iOS: show monthly/yearly (1) plans to freelancers too; purchase still uses Apple IAP only.
                // Non‑iOS freelancers: keep free-only behavior.
                final baseList = (isFreelancer && !isIos)
                    ? plans.where((p) => p.price <= 0).toList()
                    : plans;
                final displayPlans =
                    baseList.where(isAllowedDisplayPlan).toList();

                if (displayPlans.isEmpty) {
                  return EmptyState(
                    icon: Icons.subscriptions_outlined,
                    title: isFreelancer
                        ? l10n.freelancerPlansEmpty
                        : 'No active subscriptions',
                    message: isFreelancer
                        ? null
                        : 'Subscribe to a plan to access premium features',
                    action: PrimaryButton(
                      label: 'View Plans',
                      onPressed: () {
                        ref.invalidate(plansProvider);
                      },
                    ),
                  );
                }

                return _buildPlansContent(
                  displayPlans,
                  eClickEnabledOnServer: eClickEnabledOnServer,
                  freelancerFreeOnly: isFreelancer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // B) Pill Segmented Control (centered, compact)
  Widget _buildPillSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPill(
            label: 'Plans',
            icon: Icons.credit_card_rounded,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildPill(
            label: 'FAQ',
            icon: Icons.help_outline_rounded,
            isSelected: _selectedTab == 1,
            onTap: () {
              // Navigate to FAQ screen
              context.push('/help-faq');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B0B0F) // Near-black primary
              : Colors.white, // White background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0B0B0F)
                : const Color(0xFFE6E6E6), // Light gray border
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Subtle top-right soft white highlight (iOS gloss effect)
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.1,
                        colors: [
                          Colors.white.withOpacity(
                            0.12,
                          ), // Subtle white highlight
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
            // Content
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF0B0B0F), // Near-black for inactive
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF0B0B0F), // Near-black for inactive
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // C) Section Header Row (title on left, chip on right)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: const Color(0xFF0B0B0F), // Near-black primary
              fontWeight: FontWeight.w600,
            ),
          ),
          // Small rounded chip with icon + number (balance pill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE6E6E6), // Light gray border
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 14,
                  color: Color(0xFFFB923C), // Accent color for icon
                ),
                const SizedBox(width: 5),
                Text(
                  '0', // Placeholder number
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF0B0B0F), // Near-black primary
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // D) Big Rounded Container with Plan Rows
  Widget _buildPlansContent(
    List<Plan> plans, {
    required bool eClickEnabledOnServer,
    required bool freelancerFreeOnly,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Big Rounded Container with White/Subtle Background
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9), // Very light gray OR white
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), // Subtle shadow
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Plan Rows
                ...plans.asMap().entries.map((entry) {
                  final index = entry.key;
                  final plan = entry.value;
                  final isLast = index == plans.length - 1;

                  return Column(
                    children: [
                      _buildPlanRow(
                        plan,
                        eClickEnabledOnServer: eClickEnabledOnServer,
                        freelancerFreeOnly: freelancerFreeOnly,
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Divider(
                          color: const Color(
                            0xFFE6E6E6,
                          ).withValues(alpha: 0.5), // Light gray divider
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          // Required subscription info links (App Review: Privacy + Terms/EULA)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              children: [
                Text(
                  'By subscribing, you agree to our Terms of Use (EULA) and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF8B8F97),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/privacy-policy'),
                      child: const Text('Privacy Policy'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      child: const Text('Terms of Use (EULA)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlanSelection(
    Plan plan, {
    required bool eClickEnabledOnServer,
  }) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final token = await SecureStore.readAccessToken();

    if (user == null || token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final role = user.roleId;
    if (role != 2 && role != 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plans are available for clients and freelancers.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // iOS policy: subscriptions must use Apple IAP only (no external methods)
    if (!kIsWeb && Platform.isIOS) {
      final resolvedPid = _resolveAppleProductId(plan);
      if (resolvedPid == null || resolvedPid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This subscription is not configured for App Store purchase. Please contact support.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      // Ensure plan has a product id for StoreKit flow
      final effectivePlan = plan.appleProductId == resolvedPid
          ? plan
          : plan.copyWith(appleProductId: resolvedPid);
      await _startApplePurchase(effectivePlan);
      return;
    }

    // Freelancers: paid tiers and in-app purchases were removed (App Store policy).
    // Verification is booked outside the app via [AppConfig.freelancerVerificationBookingUrl].
    if (role == 3) {
      if (!mounted) return;
      if (plan.price > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Paid freelancer plans are not available in the app. '
              'Use Verify account to book a verification interview.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final repo = ref.read(subscriptionRepositoryProvider);
    final subStatus = await repo.fetchSubscriptionStatus();
    if (!mounted) return;
    if (!subStatus.success) {
      final authMsg = (subStatus.errorMessage ?? '').toLowerCase();
      final isAuthFailure = authMsg.contains('session expired') ||
          authMsg.contains('unauthorized') ||
          authMsg.contains('invalid token') ||
          authMsg.contains('expired');
      if (isAuthFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subStatus.errorMessage ??
                'Could not verify subscription status. Check your connection; '
                'the server will still validate if you continue.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    } else if (subStatus.blocksNewPlanPurchase) {
      await _showAlreadySubscribedDialog(subStatus);
      return;
    }

    final appleConfigured =
        Platform.isIOS && (plan.appleProductId?.trim().isNotEmpty ?? false);

    // Never force eClick in release builds from local flags.
    // In production, only show when backend confirms availability.
    final allowForcedEClickInDebug =
        !kReleaseMode && AppConfig.enableEClickCheckout;
    final showEClick = !AppConfig.hideEClickCheckout &&
        (role == 2 || role == 3) &&
        (eClickEnabledOnServer ||
            AppConfig.showEClickButtonForLocalDev ||
            allowForcedEClickInDebug);

    showPaymentMethodChooserSheet(
      context: context,
      showAppleOptions: Platform.isIOS,
      applePayConfiguredForSelectedPlan: appleConfigured,
      showEClickOption: showEClick,
      selectedPlanName: plan.name,
      onPayWithApple:
          appleConfigured ? () => _startApplePurchase(plan) : null,
      onPayWithEClick: showEClick ? () => _startEClickCheckout(plan) : null,
      onRestoreApplePurchases: Platform.isIOS ? _restoreApplePurchases : null,
      onSubscribeFromCompany: () => _openCompanySubscribeUrl(),
    );
  }

  String? _resolveAppleProductId(Plan plan) {
    final pid = plan.appleProductId?.trim();
    if (pid != null && pid.isNotEmpty) return pid;
    final t = plan.planType.toLowerCase().trim();
    if (t == 'monthly') return _appleMonthlyProductId;
    if (t == 'yearly') return _appleYearlyProductId;
    return null;
  }

  Future<void> _showAlreadySubscribedDialog(SubscriptionStatusSnapshot s) async {
    if (!mounted) return;
    final isPending = s.overallStatus == 'pending_start';
    final title = isPending
        ? 'Subscription pending'
        : 'You already have an active subscription';
    final lines = <String>[
      s.statusMessage.trim(),
      if (s.planName != null && s.planName!.isNotEmpty)
        'Current plan: ${s.planName!}',
      if (s.subscriptionRowStatus != null &&
          s.subscriptionRowStatus!.isNotEmpty)
        'Status: ${s.subscriptionRowStatus!}',
      if (s.endDateRaw != null && s.endDateRaw!.isNotEmpty)
        'End date: ${s.endDateRaw!}',
      if (s.remainingDays > 0)
        'About ${s.remainingDays} day(s) left on the current period (estimate).',
    ];
    final body = lines.where((e) => e.isNotEmpty).join('\n\n');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            '$body\n\nYou can subscribe to a different plan after your current subscription ends.',
            style: const TextStyle(height: 1.35),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startEClickCheckout(Plan plan) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final available = await repo.isEClickCheckoutAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'eClick checkout is not enabled on the server yet. Please use Subscribe from Company for now.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final created = await repo.createEClickPlanCheckoutSession(planId: plan.id);
    if (!mounted) return;
    if (!created.success ||
        created.orderId == null ||
        created.approvalUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(created.approvalUrl!);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid eClick link from server.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final returnHost = Uri.tryParse(AppConfig.adminWebOrigin)?.host.toLowerCase();
    final allowedReturnHosts = <String>{
      if (returnHost != null && returnHost.isNotEmpty) returnHost,
      'orderzhouse.com',
      'www.orderzhouse.com',
    };

    final approvalResult = await Navigator.of(context).push<EClickCheckoutResult>(
      MaterialPageRoute(
        builder: (_) => EClickCheckoutWebViewScreen(
          approvalUrl: uri,
          allowedReturnHosts: allowedReturnHosts,
        ),
      ),
    );
    if (!mounted) return;
    if (approvalResult == null || approvalResult == EClickCheckoutResult.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('eClick checkout was cancelled.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (approvalResult == EClickCheckoutResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load eClick checkout page.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _completeEClickCapture(created.orderId!);
  }

  Future<void> _completeEClickCapture(String orderId) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.captureEClickPlanOrder(orderId: orderId);
    if (!mounted) return;
    if (result.success) {
      await ref.read(authStateProvider.notifier).refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.idempotent
                ? 'Your subscription is already active.'
                : result.message,
          ),
          backgroundColor: AppColors.accentOrange,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _restoreApplePurchases() async {
    if (!Platform.isIOS) return;
    if (_isRunningOnIosSimulator()) {
      _showIosSimulatorIapUnavailable();
      return;
    }
    try {
      _attachIosPurchaseListenerIfNeeded();
    } catch (e) {
      _showStoreKitBridgeErrorSnack(e);
      return;
    }
    try {
      await InAppPurchase.instance.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If you have an active subscription, it will sync shortly.',
          ),
          backgroundColor: AppColors.accentOrange,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showStoreKitBridgeErrorSnack(e);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startApplePurchase(Plan plan) async {
    final pid = _resolveAppleProductId(plan);
    if (pid == null || pid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This subscription is not configured for App Store purchase. Please contact support.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_isRunningOnIosSimulator()) {
      _showIosSimulatorIapUnavailable();
      return;
    }

    try {
      _attachIosPurchaseListenerIfNeeded();
    } catch (e) {
      _showStoreKitBridgeErrorSnack(e);
      return;
    }

    final iap = InAppPurchase.instance;
    final bool storeCanPay;
    try {
      storeCanPay = await iap.isAvailable();
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showStoreKitBridgeErrorSnack(e);
      return;
    }
    if (!storeCanPay) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App Store purchases are not available on this device.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _pendingApplePlan = plan);

    late final ProductDetailsResponse response;
    try {
      response = await iap.queryProductDetails({pid});
    } on PlatformException catch (e) {
      setState(() => _pendingApplePlan = null);
      if (!mounted) return;
      _showStoreKitBridgeErrorSnack(e);
      return;
    }
    if (response.error != null ||
        response.productDetails.isEmpty ||
        response.notFoundIDs.isNotEmpty) {
      setState(() => _pendingApplePlan = null);
      if (!mounted) return;
      final err = response.error;
      final notFound = response.notFoundIDs;
      final String msg;
      if (err != null) {
        final code = err.code.trim().isEmpty ? '' : ' (${err.code})';
        msg = '${err.message}$code';
      } else if (notFound.isNotEmpty) {
        msg =
            'App Store returned no product for: ${notFound.join(", ")}. '
            'In App Store Connect, the subscription product ID must match exactly, '
            'be Cleared for Sale, and belong to this app’s bundle ID. Sandbox: sign in under Settings → App Store → Sandbox.';
      } else {
        msg =
            'No product details for "$pid". Check the plan’s apple_product_id in the admin/API matches App Store Connect.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(height: 1.35)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }

    final param = PurchaseParam(productDetails: response.productDetails.first);
    try {
      final started = await iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        setState(() => _pendingApplePlan = null);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start purchase. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() => _pendingApplePlan = null);
      if (!mounted) return;
      _showStoreKitBridgeErrorSnack(e);
    } catch (_) {
      setState(() => _pendingApplePlan = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start purchase. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onIosPurchaseUpdated(List<PurchaseDetails> purchases) async {
    final iap = InAppPurchase.instance;
    for (final d in purchases) {
      final pending = _pendingApplePlan;
      if (pending != null && d.productID != pending.appleProductId) {
        continue;
      }

      if (d.status == PurchaseStatus.pending) {
        continue;
      }

      if (d.status == PurchaseStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(d.error?.message ?? 'Purchase failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (pending != null) {
          setState(() => _pendingApplePlan = null);
        }
        await iap.completePurchase(d);
        continue;
      }

      if (d.status == PurchaseStatus.canceled) {
        if (pending != null) {
          setState(() => _pendingApplePlan = null);
        }
        await iap.completePurchase(d);
        continue;
      }

      if (d.status == PurchaseStatus.purchased ||
          d.status == PurchaseStatus.restored) {
        final receipt = d.verificationData.serverVerificationData;
        if (receipt.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Missing receipt data from the store. Please try again.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          if (pending != null) {
            setState(() => _pendingApplePlan = null);
          }
          await iap.completePurchase(d);
          continue;
        }

        final repo = ref.read(subscriptionRepositoryProvider);
        final result = await repo.verifyAppleReceipt(
          receiptDataBase64: receipt,
          planId: pending?.id,
        );

        if (result.success) {
          await ref.read(authStateProvider.notifier).refreshUser();
          if (pending != null) {
            setState(() => _pendingApplePlan = null);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.idempotent
                      ? 'Your subscription is already active.'
                      : 'Payment successful! Subscription activated.',
                ),
                backgroundColor: AppColors.accentOrange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
        await iap.completePurchase(d);
      }
    }
  }

  Future<void> _openCompanySubscribeUrl() async {
    final uri = Uri.parse(AppConfig.companySubscribeUrl);
    try {
      final launched = await launchTrustedHttpUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete the company subscription form. Your request will be reviewed.',
            ),
            backgroundColor: AppColors.accentOrange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFreelancerVerificationBooking() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(AppConfig.freelancerVerificationBookingUrl);
    if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification booking URL is not configured.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final launched = await launchTrustedHttpUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.freelancerVerificationBookingOpened),
            backgroundColor: AppColors.accentOrange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateFreelancerFreePlan(Plan plan) async {
    if (plan.price > 0) return;
    final l10n = AppLocalizations.of(context)!;
    final token = await SecureStore.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _activatingFreelancerPlanId = plan.id);
    try {
      await TokenRefreshCoordinator.refreshIfExpiringSoon(DioClient.instance);
      final repo = ref.read(subscriptionRepositoryProvider);
      final result = await repo.subscribeFreelancerFreePlan(planId: plan.id);
      if (!mounted) return;
      if (result.success) {
        await ref.read(authStateProvider.notifier).refreshUser();
        ref.invalidate(plansProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.freelancerFreePlanActivated),
            backgroundColor: AppColors.accentOrange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty
                  ? result.message
                  : l10n.freelancerFreePlanActivationFailed,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.freelancerFreePlanActivationFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _activatingFreelancerPlanId = null);
      }
    }
  }

  Widget _buildPlanRow(
    Plan plan, {
    required bool eClickEnabledOnServer,
    required bool freelancerFreeOnly,
  }) {
    final durationLabel = plan.planType == 'monthly'
        ? '${plan.duration} Month'
        : plan.planType == 'yearly'
        ? '${plan.duration} Year'
        : plan.planType;

    final l10n = AppLocalizations.of(context)!;
    final appleConfigured =
        Platform.isIOS && (plan.appleProductId?.trim().isNotEmpty ?? false);

    final card = Opacity(
      opacity: 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE6E6E6), // Light gray border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // Subtle shadow
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Name + Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: const Color(0xFF0B0B0F), // Near-black primary
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (plan.description != null &&
                      plan.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF8B8F97), // Gray secondary
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Right Side: Price + Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${plan.price}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: const Color(
                          0xFF0B0B0F,
                        ), // Near-black primary (bold)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'JD',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF8B8F97), // Gray for currency
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Badge (Duration/Plan Type) - accent color with low opacity
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFB923C,
                    ).withOpacity(0.15), // Accent color with 15% opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    durationLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFFFB923C), // Accent color for text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!freelancerFreeOnly && appleConfigured) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0B0F).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'In-App Purchase',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF0B0B0F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (freelancerFreeOnly) {
      final activating = _activatingFreelancerPlanId == plan.id;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: activating ? null : () => _activateFreelancerFreePlan(plan),
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  card,
                  if (activating)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.65),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.freelancerTapFreePlanToActivate,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF8B8F97),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: l10n.freelancerVerifyAccount,
            onPressed: _openFreelancerVerificationBooking,
            isEnabled: !activating,
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _handlePlanSelection(
        plan,
        eClickEnabledOnServer: eClickEnabledOnServer,
      ),
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}
