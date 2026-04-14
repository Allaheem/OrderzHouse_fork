// ??? ????????
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../../plans/presentation/providers/plans_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../subscriptions/presentation/widgets/payment_method_chooser_sheet.dart';
import '../../../../core/models/plan.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int _selectedTab = 0; // 0 = Plans, 1 = FAQ (UI only)

  StreamSubscription<List<PurchaseDetails>>? _iosPurchaseSub;
  Plan? _pendingApplePlan;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
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
    }
  }

  @override
  void dispose() {
    _pendingApplePlan = null;
    _iosPurchaseSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

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
                  const Text(
                    'Plans',
                    style: TextStyle(
                      color: Color(0xFF0B0B0F), // Near-black primary
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
          ),

          // B) Pill Segmented Control (centered, under header)
          _buildPillSegmentedControl(),

          // C) Section Header Row
          _buildSectionHeader(),

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
                if (plans.isEmpty) {
                  return EmptyState(
                    icon: Icons.subscriptions_outlined,
                    title: 'No active subscriptions',
                    message: 'Subscribe to a plan to access premium features',
                    action: PrimaryButton(
                      label: 'View Plans',
                      onPressed: () {
                        ref.invalidate(plansProvider);
                      },
                    ),
                  );
                }

                return _buildPlansContent(plans);
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
  Widget _buildSectionHeader() {
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
            'Plans',
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
  Widget _buildPlansContent(List<Plan> plans) {
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
                      _buildPlanRow(plan),
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
        ],
      ),
    );
  }

  Future<void> _handlePlanSelection(Plan plan) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to subscribe'),
          backgroundColor: Colors.red,
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

    final appleConfigured =
        Platform.isIOS && (plan.appleProductId?.trim().isNotEmpty ?? false);

    showPaymentMethodChooserSheet(
      context: context,
      showAppleOptions: Platform.isIOS,
      applePayConfiguredForSelectedPlan: appleConfigured,
      selectedPlanName: plan.name,
      onPayWithApple:
          appleConfigured ? () => _startApplePurchase(plan) : null,
      onRestoreApplePurchases: Platform.isIOS ? _restoreApplePurchases : null,
      onSubscribeFromCompany: () => _openCompanySubscribeUrl(),
    );
  }

  Future<void> _restoreApplePurchases() async {
    if (!Platform.isIOS) return;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startApplePurchase(Plan plan) async {
    final pid = plan.appleProductId?.trim();
    if (pid == null || pid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This plan is missing an App Store product ID. Use Subscribe from Company or pick another plan.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
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

    final response = await iap.queryProductDetails({pid});
    if (response.error != null ||
        response.productDetails.isEmpty ||
        response.notFoundIDs.isNotEmpty) {
      setState(() => _pendingApplePlan = null);
      if (!mounted) return;
      final msg = response.error?.message ?? 'Product not found in App Store.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
    } catch (e) {
      setState(() => _pendingApplePlan = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase error: $e'), backgroundColor: Colors.red),
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
                  'Missing receipt data from the store. Try again or use Subscribe from Company.',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildPlanRow(Plan plan) {
    final durationLabel = plan.planType == 'monthly'
        ? '${plan.duration} Month'
        : plan.planType == 'yearly'
        ? '${plan.duration} Year'
        : plan.planType;

    return InkWell(
      onTap: () => _handlePlanSelection(plan),
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
