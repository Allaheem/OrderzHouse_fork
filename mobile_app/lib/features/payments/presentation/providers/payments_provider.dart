import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});
