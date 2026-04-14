// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

/// `true` if backend has `PAYPAL_ENABLED=true` (see `GET /paypal/checkout-available`).
final paypalCheckoutAvailableProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.isPayPalCheckoutAvailable();
});
