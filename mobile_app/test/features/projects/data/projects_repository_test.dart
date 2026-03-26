import 'package:OrderzHouse/core/models/project.dart';
import 'package:OrderzHouse/core/network/api_client.dart';
import 'package:OrderzHouse/features/projects/data/repositories/projects_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late Dio dio;
  late ApiClient apiClient;
  late ProjectsRepository repository;

  setUp(() {
    dio = _MockDio();
    apiClient = _MockApiClient();
    repository = ProjectsRepository(
      dio: dio,
      apiClient: apiClient,
      currentUserRoleReader: () => 2,
    );
  });

  group('ProjectsRepository.getMyProjectsRaw', () {
    test('parses rows list shape', () async {
      when(
        () => dio.get(
          '/projects/myprojects',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/projects/myprojects'),
          statusCode: 200,
          data: <String, dynamic>{
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'title': 'P1'},
              <String, dynamic>{'id': 2, 'title': 'P2'},
            ],
          },
        ),
      );

      final result = await repository.getMyProjectsRaw();

      expect(result.success, isTrue);
      expect(result.data, hasLength(2));
    });

    test('returns failure safely when backend error body is non-map', () async {
      when(
        () => dio.get(
          '/projects/myprojects',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/projects/myprojects'),
          response: Response<String>(
            requestOptions: RequestOptions(path: '/projects/myprojects'),
            statusCode: 500,
            data: 'Server exploded',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.getMyProjectsRaw();

      expect(result.success, isFalse);
      expect(result.message, isNotEmpty);
    });
  });

  group('ProjectsRepository.getMyProjects', () {
    test('parses valid projects and skips malformed item', () async {
      when(
        () => apiClient.getMyProjects(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          statusKey: any(named: 'statusKey'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/projects/myprojects'),
          statusCode: 200,
          data: <String, dynamic>{
            'projects': <dynamic>[
              <String, dynamic>{
                'id': 1,
                'user_id': 3,
                'title': 'Project A',
                'description': 'Desc',
                'project_type': 'fixed',
                'status': 'open',
                'budget': 500,
                'created_at': '2025-01-01T00:00:00.000Z',
              },
              <String, dynamic>{'id': 'bad', 'title': 100},
            ],
          },
        ),
      );

      final result = await repository.getMyProjects();

      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data, hasLength(1));
      expect(result.data?.first, isA<Project>());
    });
  });

  group('ProjectsRepository.downloadFile', () {
    test('returns success when dio download succeeds', () async {
      when(
        () => dio.download(
          'https://cdn.example.com/file.pdf',
          'C:/tmp/file.pdf',
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: 'https://cdn.example.com/file.pdf',
          ),
          statusCode: 200,
        ),
      );

      final result = await repository.downloadFile(
        url: 'https://cdn.example.com/file.pdf',
        savePath: 'C:/tmp/file.pdf',
      );

      expect(result.success, isTrue);
    });

    test('maps dio error message when download fails', () async {
      when(
        () => dio.download(
          'https://cdn.example.com/file.pdf',
          'C:/tmp/file.pdf',
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: 'https://cdn.example.com/file.pdf',
          ),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: 'https://cdn.example.com/file.pdf',
            ),
            statusCode: 401,
            data: <String, dynamic>{'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.downloadFile(
        url: 'https://cdn.example.com/file.pdf',
        savePath: 'C:/tmp/file.pdf',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Unauthorized');
    });
  });
}
