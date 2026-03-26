import 'package:OrderzHouse/core/models/category.dart';
import 'package:OrderzHouse/features/categories/data/repositories/categories_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;
  late CategoriesRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = CategoriesRepository(dio: dio);
  });

  group('CategoriesRepository.fetchExploreCategories', () {
    test('returns parsed categories on success payload', () async {
      when(() => dio.get('/category')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/category'),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'name': 'Design'},
              <String, dynamic>{'id': 2, 'name': 'Development'},
            ],
          },
        ),
      );

      final result = await repository.fetchExploreCategories();

      expect(result.success, isTrue);
      expect(result.data, hasLength(2));
      expect(result.data?.first, isA<Category>());
    });

    test('skips malformed category items and keeps valid ones', () async {
      when(() => dio.get('/category')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/category'),
          statusCode: 200,
          data: <String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{'id': 1, 'name': 'Valid'},
              <String, dynamic>{'id': 'bad', 'name': 55},
            ],
          },
        ),
      );

      final result = await repository.fetchExploreCategories();

      expect(result.success, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data?.first.id, 1);
    });

    test(
      'returns fallback error message when error body is not a map',
      () async {
        when(() => dio.get('/category')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/category'),
            response: Response<String>(
              requestOptions: RequestOptions(path: '/category'),
              statusCode: 500,
              data: 'Internal Server Error',
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.fetchExploreCategories();

        expect(result.success, isFalse);
        expect(result.message, isNotEmpty);
        expect(result.data, isEmpty);
      },
    );
  });
}
