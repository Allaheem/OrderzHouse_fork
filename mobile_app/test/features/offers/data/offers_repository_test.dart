import 'package:OrderzHouse/features/offers/data/repositories/offers_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;
  late OffersRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = OffersRepository(dio: dio);
  });

  group('OffersRepository.sendOffer', () {
    test('returns success response on valid backend response', () async {
      when(
        () => dio.post('/offers/10/offers', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/offers/10/offers'),
          statusCode: 201,
          data: <String, dynamic>{'message': 'Offer created', 'id': 123},
        ),
      );

      final result = await repository.sendOffer(
        projectId: 10,
        bidAmount: 120.0,
        proposal: 'I can deliver this fast',
      );

      expect(result.success, isTrue);
      expect(result.message, 'Offer created');
      expect(result.data?['id'], 123);
    });

    test('maps backend error message when DioException occurs', () async {
      when(
        () => dio.post('/offers/11/offers', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/offers/11/offers'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/offers/11/offers'),
            statusCode: 400,
            data: <String, dynamic>{'message': 'Invalid bid amount'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.sendOffer(projectId: 11, bidAmount: 0);

      expect(result.success, isFalse);
      expect(result.message, 'Invalid bid amount');
      expect(result.error?['statusCode'], 400);
    });
  });

  group('OffersRepository.checkMyPendingOffer', () {
    test('returns false when backend payload misses field', () async {
      when(() => dio.get('/offers/my/22/pending')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/offers/my/22/pending'),
          statusCode: 200,
          data: <String, dynamic>{'success': true},
        ),
      );

      final result = await repository.checkMyPendingOffer(22);

      expect(result.success, isTrue);
      expect(result.data, isFalse);
    });

    test('returns false fallback on DioException', () async {
      when(() => dio.get('/offers/my/23/pending')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/offers/my/23/pending'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/offers/my/23/pending'),
            statusCode: 404,
            data: <String, dynamic>{'message': 'No pending offer'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.checkMyPendingOffer(23);

      expect(result.success, isTrue);
      expect(result.data, isFalse);
      expect(result.message, 'No pending offer');
    });
  });
}
