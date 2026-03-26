// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/plan.dart';
import '../../data/repositories/plans_repository.dart';

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository();
});

final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) async {
  final repository = ref.read(plansRepositoryProvider);
  final response = await repository.fetchPlans();

  if (response.success && response.data != null) {
    return response.data!;
  }

  throw Exception(response.message ?? 'Failed to fetch plans');
});
