import 'package:OrderzHouse/core/network/dio_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioExceptions.getMessage', () {
    test('maps bad response 401 to auth message', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/users/login'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/users/login'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final message = DioExceptions.getMessage(exception);
      expect(message, 'Authentication failed. Please login again.');
    });

    test('maps timeout to timeout message', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/ping'),
        type: DioExceptionType.connectionTimeout,
      );

      final message = DioExceptions.getMessage(exception);
      expect(message, contains('Connection timeout'));
    });
  });
}
