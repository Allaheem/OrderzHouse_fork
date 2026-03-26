// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});
