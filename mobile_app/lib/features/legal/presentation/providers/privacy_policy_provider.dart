// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../data/models/policy_document.dart';
import '../../data/policy_repository.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return PolicyRepository();
});

/// Loads the privacy policy document for the current locale.
final privacyPolicyProvider = FutureProvider<PolicyDocument>((ref) async {
  final locale = ref.watch(localeProvider);
  final repo = ref.read(policyRepositoryProvider);
  return repo.loadPrivacyPolicy(locale.languageCode);
});
