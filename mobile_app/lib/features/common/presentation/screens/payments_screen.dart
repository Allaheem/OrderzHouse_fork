// ??? ????????
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/models/referral_info.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/payment.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../../referrals/presentation/providers/referrals_provider.dart';
import '../../../../l10n/app_localizations.dart';

// Provider for filter selection (All / Plans / Projects / Wallet)
final _selectedFilterProvider = StateProvider<String>((ref) => 'all');

// In-memory cache for payment history
final _paymentHistoryCacheProvider =
    StateProvider.family<Map<String, dynamic>?, String>((ref, type) => null);

// Provider for unified payment history with caching
final paymentHistoryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, type) async {
      final repository = ref.read(paymentsRepositoryProvider);
      final userId = ref.read(authStateProvider).userId;

      if (userId == null) {
        return {'balance': 0.0, 'currency': 'JOD', 'transactions': <Payment>[]};
      }

      final cacheKey = 'payment_history_${userId}_$type';

      // 1. Check in-memory cache first (instant)
      final cached = ref.read(_paymentHistoryCacheProvider(type));
      if (cached != null) {
        // Return cached immediately, continue fetching fresh
      }

      // 2. Try persistent cache (for transactions list)
      final persistentCache = await CacheService.getList<Payment>(
        '${cacheKey}_transactions',
        (json) => Payment.fromJson(json),
      );

      if (persistentCache != null) {
        final cachedData = {
          'balance': cached?['balance'] ?? 0.0,
          'currency': cached?['currency'] ?? 'JOD',
          'transactions': persistentCache,
        };
        ref.read(_paymentHistoryCacheProvider(type).notifier).state =
            cachedData;
        // Return cached immediately, continue fetching fresh
      }

      // 3. Fetch fresh data
      try {
        final response = await repository.getPaymentHistory(type: type);

        if (response.success && response.data != null) {
          // Save to both caches
          ref.read(_paymentHistoryCacheProvider(type).notifier).state =
              response.data!;
          final transactions = response.data!['transactions'] as List<Payment>?;
          if (transactions != null) {
            await CacheService.setList(
              '${cacheKey}_transactions',
              transactions,
              (payment) => payment.toJson(),
            );
          }
          return response.data!;
        }

        // If fetch fails, return cached data if available
        if (persistentCache != null) {
          return {
            'balance': cached?['balance'] ?? 0.0,
            'currency': cached?['currency'] ?? 'JOD',
            'transactions': persistentCache,
          };
        }
        if (cached != null) {
          return cached;
        }

        return {'balance': 0.0, 'currency': 'JOD', 'transactions': <Payment>[]};
      } catch (e) {
        // Return cached data on error if available
        if (persistentCache != null) {
          return {
            'balance': cached?['balance'] ?? 0.0,
            'currency': cached?['currency'] ?? 'JOD',
            'transactions': persistentCache,
          };
        }
        if (cached != null) {
          return cached;
        }
        return {'balance': 0.0, 'currency': 'JOD', 'transactions': <Payment>[]};
      }
    });

// Legacy provider for backward compatibility (still used for freelancer balance)
final freelancerBalanceProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(paymentsRepositoryProvider);
  final response = await repository.getFreelancerBalance();
  return response.data ?? 0.0;
});

// Derived provider for balance from payment history (reuses paymentHistoryProvider cache)
final balanceFromHistoryProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final historyData = await ref.watch(paymentHistoryProvider('all').future);
    return {
      'balance': (historyData['balance'] as num?)?.toDouble() ?? 0.0,
      'currency': historyData['currency'] as String? ?? 'JOD',
    };
  } catch (e) {
    // Fallback on error
    return {'balance': 0.0, 'currency': 'JOD'};
  }
});

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _scrollController = ScrollController();
  final _referAndEarnKey = GlobalKey();
  bool _showReferAndEarn = false;

  @override
  void initState() {
    super.initState();
    // عند فتح صفحة المدفوعات نحدّث الرصيد والمعاملات (خاصة بعد إتمام مشروع)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).user;
      if (user?.roleId == 3) {
        ref.invalidate(paymentHistoryProvider('all'));
        ref.invalidate(balanceFromHistoryProvider);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToReferAndEarn() {
    final context = _referAndEarnKey.currentContext;
    if (context != null && _scrollController.hasClients) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final roleId = user?.roleId ?? 0;
    final isClient = roleId == 2;
    final isFreelancer = roleId == 3;

    // Fetch unified payment history (all transactions)
    final historyAsync = ref.watch(paymentHistoryProvider('all'));
    final selectedFilter = ref.watch(_selectedFilterProvider);

    // Use filter-specific history if filter is not 'all'
    final filteredHistoryAsync = selectedFilter == 'all'
        ? historyAsync
        : ref.watch(paymentHistoryProvider(selectedFilter));

    return AppScaffold(
      body: filteredHistoryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(paymentHistoryProvider(selectedFilter));
            if (selectedFilter != 'all') {
              ref.invalidate(paymentHistoryProvider('all'));
            }
          },
        ),
        data: (historyData) {
          final transactions = (historyData['transactions'] as List<dynamic>)
              .cast<Payment>()
              .toList();
          final balance = (historyData['balance'] as num?)?.toDouble() ?? 0.0;

          return _buildContent(
            context,
            ref,
            transactions,
            balance,
            isClient,
            isFreelancer,
            roleId,
            user?.email ?? '',
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Payment> transactions,
    double displayBalance,
    bool isClient,
    bool isFreelancer,
    int roleId,
    String userEmail,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        final filter = ref.read(_selectedFilterProvider);
        ref.invalidate(paymentHistoryProvider(filter));
        if (filter != 'all') {
          ref.invalidate(paymentHistoryProvider('all'));
        }
        if (isFreelancer) {
          ref.invalidate(freelancerBalanceProvider);
        }
      },
      color: const Color(0xFF6D5FFD),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                        color: AppColors.primary, // Coral-red
                        onPressed: () {
                          // Safe back navigation
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            // Fallback: navigate to explore/home based on role
                            final user = ref.read(authStateProvider).user;
                            final userRoleId = user?.roleId ?? 0;
                            if (userRoleId == 2) {
                              context.go('/client/explore');
                            } else if (userRoleId == 3) {
                              context.go('/freelancer/home');
                            } else {
                              context.go('/client/explore');
                            }
                          }
                        },
                      ),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      l10n.payments,
                      style: const TextStyle(
                        color: Color(0xFF111827),
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

            const SizedBox(height: 24),

            // Top Balance Section (Hero)
            _buildBalanceHero(context, displayBalance, isClient),

            const SizedBox(height: 24),

            // Filter chips (optional)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFilterChips(context, ref, isFreelancer),
            ),

            const SizedBox(height: 16),

            // Recent Activity Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRecentActivitySection(
                context,
                transactions,
                isClient,
              ),
            ),

            const SizedBox(height: 24),

            // Refer & Earn Card (hidden by default)
            if (_showReferAndEarn)
              Padding(
                key: _referAndEarnKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildReferAndEarnCard(context, ref),
              ),

            if (_showReferAndEarn) const SizedBox(height: 24),

            // Toggle button for Refer & Earn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showReferAndEarn = !_showReferAndEarn;
                  });
                  // Auto-scroll to Refer & Earn when showing
                  if (_showReferAndEarn) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToReferAndEarn();
                    });
                  }
                },
                icon: Icon(
                  _showReferAndEarn
                      ? Icons.expand_less
                      : Icons.card_giftcard_rounded,
                  size: 18,
                ),
                label: Text(
                  l10n.referAndEarn,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHero(
    BuildContext context,
    double balance,
    bool isClient,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final formattedBalance = numberFormat.format(balance);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Label
          Text(
            isClient ? l10n.totalEarnings : l10n.availableBalance,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Large amount
          Text(
            '$formattedBalance JOD',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // Trend/Update text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.today,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferAndEarnCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final referralsAsync = ref.watch(myReferralsProvider);

    return referralsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  l10n.failedToLoad,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(myReferralsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            );
          },
        ),
      ),
      data: (referralInfo) {
        // Use the cleaned ReferralInfo model
        final hasValidCode = referralInfo.hasValidCode;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Subtitle
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB923C).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFFFB923C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.referAndEarn,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.inviteFriends,
                          style: TextStyle(
                            color: const Color(
                              0xFF111827,
                            ).withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Code box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.yourReferralCode,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasValidCode ? referralInfo.code : '—',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasValidCode)
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: referralInfo.code),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.codeCopied),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Share button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasValidCode
                      ? () => _handleShareInvite(context, referralInfo)
                      : null,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(l10n.shareInvite),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasValidCode
                        ? const Color(0xFFFB923C)
                        : const Color(0xFF9CA3AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      l10n.invited,
                      referralInfo.invited.toString(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      l10n.successful,
                      referralInfo.successful.toString(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      l10n.earned,
                      '${referralInfo.earned.toStringAsFixed(1)} ${referralInfo.currency}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rules text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.referralBannerText,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handle share invite action
  Future<void> _handleShareInvite(
    BuildContext context,
    ReferralInfo referralInfo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!referralInfo.hasValidCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.referralCodeNotAvailable),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Build share message
      String message = l10n.shareMessage(referralInfo.code);

      // Append link if available
      if (referralInfo.link != null && referralInfo.link!.isNotEmpty) {
        message += '\n\n${referralInfo.link}';
      }

      // Use Share.share to trigger native share sheet
      await Share.share(message);
    } catch (e) {
      // Fallback to copying code if share fails
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: referralInfo.code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Referral code copied: ${referralInfo.code}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    bool isFreelancer,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFilter = ref.watch(_selectedFilterProvider);

    final filters = isFreelancer
        ? ['all', 'plan', 'project', 'wallet']
        : ['all', 'plan', 'project'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          final label = filter == 'all'
              ? l10n.all
              : filter == 'plan'
              ? l10n.subscriptions
              : filter == 'project'
              ? l10n.projects
              : l10n.balance;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(_selectedFilterProvider.notifier).state = filter;
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    List<Payment> transactions,
    bool isClient,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.transactionHistory,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to details if exists, otherwise no-op
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.viewDetails)));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.viewDetails,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Transactions list
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                l10n.noTransactions,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
            ),
          )
        else
          ...transactions.map(
            (payment) => _buildTransactionCard(payment, isClient),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(Payment payment, bool isClient) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    // Determine if income (for freelancers: wallet credit or escrow released)
    final source = payment.source ?? payment.purpose ?? '';
    final statusLower = payment.status.toLowerCase();
    final isIncome = isClient
        ? false // Client always pays (expense)
        : (payment.type?.toLowerCase() == 'credit' ||
              statusLower == 'released' ||
              source == 'wallet');

    final amountColor = isIncome ? Colors.green : Colors.red;
    final amountPrefix = isIncome ? '+' : '-';

    // Get enriched display name/title (use new enriched fields if available)
    final String displayName =
        payment.title ?? payment.projectTitle ?? payment.note ?? 'Transaction';

    // Get description/subtitle
    String subtitle =
        payment.description ??
        (payment.source == 'plan'
            ? 'Plan Subscription'
            : payment.source == 'project'
            ? 'Project Payment'
            : payment.source == 'wallet'
            ? 'Wallet Transaction'
            : '');

    // Add status to subtitle if available
    if (payment.status != 'paid' && payment.status.isNotEmpty) {
      final statusLabel = payment.status == 'held'
          ? 'Held'
          : payment.status == 'released'
          ? 'Released'
          : payment.status == 'refunded'
          ? 'Refunded'
          : payment.status == 'failed'
          ? 'Failed'
          : payment.status;
      subtitle = subtitle.isNotEmpty ? '$subtitle • $statusLabel' : statusLabel;
    }

    // Get initials for avatar (use title or source icon)
    String initials = 'T';
    if (displayName.isNotEmpty) {
      final words = displayName.split(' ');
      if (words.length >= 2) {
        initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words[0].isNotEmpty) {
        initials = words[0][0].toUpperCase();
      }
    }

    // Format date + time
    final dateTimeStr =
        '${dateFormat.format(payment.createdAt)} • ${timeFormat.format(payment.createdAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateTimeStr,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (payment.source != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.source!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
