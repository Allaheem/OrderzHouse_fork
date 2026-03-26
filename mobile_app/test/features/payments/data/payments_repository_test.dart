import 'package:OrderzHouse/features/payments/data/repositories/payments_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;
  late PaymentsRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = PaymentsRepository(dio: dio);
  });

  group('PaymentsRepository.getPaymentHistory', () {
    test('parses history and computes balance fallbacks', () async {
      when(
        () => dio.get(
          '/payments/history',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/payments/history'),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'availableToWithdraw': 77.5,
            'currency': 'JOD',
            'transactions': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'amount': 50,
                'type': 'credit',
                'status': 'completed',
                'description': 'Payout',
                'created_at': '2026-03-20T10:00:00.000Z',
              },
            ],
          },
        ),
      );

      final result = await repository.getPaymentHistory(type: 'all');

      expect(result.success, isTrue);
      expect(result.data?['balance'], 77.5);
      expect(result.data?['currency'], 'JOD');
      expect((result.data?['transactions'] as List).length, 1);
    });

    test('maps 404 to endpoint unavailable message', () async {
      when(
        () => dio.get(
          '/payments/history',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/payments/history'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/payments/history'),
            statusCode: 404,
            data: <String, dynamic>{'message': 'Not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.getPaymentHistory(type: 'all');

      expect(result.success, isFalse);
      expect(result.message, contains('endpoint is not available'));
    });
  });

  group('PaymentsRepository.getFreelancerBalance', () {
    test('returns backend message on bad response', () async {
      when(() => dio.get('/payments/freelancer/wallet')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/payments/freelancer/wallet'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/payments/freelancer/wallet'),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Wallet service down'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.getFreelancerBalance();

      expect(result.success, isFalse);
      expect(result.message, 'Wallet service down');
    });
  });
}
