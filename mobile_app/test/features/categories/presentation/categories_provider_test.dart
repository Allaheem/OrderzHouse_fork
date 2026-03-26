import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/category.dart';
import 'package:OrderzHouse/features/categories/data/repositories/categories_repository.dart';
import 'package:OrderzHouse/features/categories/presentation/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoriesRepository extends Mock implements CategoriesRepository {}

void main() {
  late CategoriesRepository repository;

  setUp(() {
    repository = _MockCategoriesRepository();
  });

  test('returns categories when repository succeeds', () async {
    when(() => repository.fetchExploreCategories()).thenAnswer(
      (_) async => const ApiResponse<List<Category>>(
        success: true,
        data: <Category>[
          Category(id: 1, name: 'Design'),
          Category(id: 2, name: 'Dev'),
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: <Override>[
        categoriesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(exploreCategoriesProvider.future);

    expect(result, hasLength(2));
  });

  test('throws when repository fails and no cache exists', () async {
    when(() => repository.fetchExploreCategories()).thenAnswer(
      (_) async => const ApiResponse<List<Category>>(
        success: false,
        message: 'Network failed',
        data: <Category>[],
      ),
    );

    final container = ProviderContainer(
      overrides: <Override>[
        categoriesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(exploreCategoriesProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
