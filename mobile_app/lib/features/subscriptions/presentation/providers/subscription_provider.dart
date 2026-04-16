// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

/// `true` if backend has `ECLICK_ENABLED=true` (see `GET /eclick/checkout-available`).
final eClickCheckoutAvailableProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.isEClickCheckoutAvailable();
});
