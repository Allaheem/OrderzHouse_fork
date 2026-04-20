// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

/// Current user's subscription status snapshot (`GET /subscriptions/status`).
/// Auto-dispose so reopening Plans refreshes status.
final subscriptionStatusProvider =
    FutureProvider.autoDispose<SubscriptionStatusSnapshot>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchSubscriptionStatus();
});

/// `true` if backend exposes eClick checkout (see `GET /eclick/checkout-available`).
/// Auto-dispose so reopening Plans refetches after you change Render env / redeploy.
final eClickCheckoutAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.isEClickCheckoutAvailable();
});
