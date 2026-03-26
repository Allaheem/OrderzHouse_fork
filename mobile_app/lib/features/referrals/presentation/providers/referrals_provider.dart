// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/referrals_repository.dart';
import '../../../../core/models/referral_info.dart';

// Provider for referrals repository
final referralsRepositoryProvider = Provider<ReferralsRepository>((ref) {
  return ReferralsRepository();
});

// Provider for referrals data
// Using FutureProvider (not autoDispose) to prevent repeated calls on rebuild
final myReferralsProvider = FutureProvider<ReferralInfo>((ref) async {
  final repository = ref.read(referralsRepositoryProvider);
  final response = await repository.getMyReferrals();

  if (response.success && response.data != null) {
    return response.data!;
  }

  // Throw a clear error message for the UI to handle
  throw Exception(response.message ?? 'Failed to fetch referrals');
});
