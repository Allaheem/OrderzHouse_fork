import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/offers_repository.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepository();
});
