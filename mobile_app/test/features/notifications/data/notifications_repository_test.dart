import 'package:OrderzHouse/core/network/api_client.dart';
import 'package:OrderzHouse/features/notifications/data/repositories/notifications_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late ApiClient apiClient;
  late NotificationsRepository repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = NotificationsRepository(api: apiClient);
  });

  group('NotificationsRepository.fetchNotifications', () {
    test('parses notifications from nested data.notifications', () async {
      when(
        () => apiClient.getNotifications(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/notifications'),
          statusCode: 200,
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'notifications': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 10,
                  'type': 'project_update',
                  'title': 'Update',
                  'message': 'Project updated',
                  'isRead': false,
                  'createdAt': '2025-03-20T10:00:00.000Z',
                },
              ],
            },
          },
        ),
      );

      final result = await repository.fetchNotifications();

      expect(result.success, isTrue);
      expect(result.data, hasLength(1));
    });

    test('returns safe fallback message for non-map error body', () async {
      when(
        () => apiClient.getNotifications(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/notifications'),
          response: Response<String>(
            requestOptions: RequestOptions(path: '/notifications'),
            statusCode: 500,
            data: 'Server error',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.fetchNotifications();

      expect(result.success, isFalse);
      expect(result.message, 'Failed to fetch notifications');
    });
  });

  group('NotificationsRepository.fetchUnreadCount', () {
    test('returns zero when count missing in successful payload', () async {
      when(
        () => apiClient.getNotificationsCount(
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/notifications/count'),
          statusCode: 200,
          data: <String, dynamic>{'success': true},
        ),
      );

      final result = await repository.fetchUnreadCount();

      expect(result.success, isTrue);
      expect(result.data, 0);
    });
  });
}
