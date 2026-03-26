// ??? ????????
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/search_result.dart';
import '../../data/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});

/// Search query state provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Search results provider (only fetches when query length >= 2)
final searchResultsProvider = FutureProvider.autoDispose<SearchResult>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);

  // Don't search if query is too short
  if (query.trim().length < 2) {
    return SearchResult.empty();
  }

  final repository = ref.read(searchRepositoryProvider);
  final response = await repository.search(query.trim());

  if (response.success && response.data != null) {
    return response.data!;
  }

  // Return empty result on error (don't throw)
  return SearchResult.empty();
});
