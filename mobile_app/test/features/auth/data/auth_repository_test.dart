import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDio extends Mock implements Dio {}

class _MockTokenStore extends Mock implements AuthTokenStore {}

void main() {
  late Dio dio;
  late AuthTokenStore tokenStore;
  late AuthRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(RequestOptions(path: '/users/login'));
  });

  setUp(() {
    dio = _MockDio();
    tokenStore = _MockTokenStore();
    repository = AuthRepository(dio: dio, tokenStore: tokenStore);
  });

  group('AuthRepository.login', () {
    test('returns user and saves tokens when token exists', () async {
      when(() => dio.post('/users/login', data: any(named: 'data'))).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/users/login'),
          statusCode: 200,
          data: <String, dynamic>{
            'token': 'access-token',
            'refreshToken': 'refresh-token',
            'message': 'ok',
            'userInfo': <String, dynamic>{
              'id': 1,
              'username': 'john',
              'email': 'john@example.com',
              'role_id': 2,
            },
          },
        ),
      );
      when(() => tokenStore.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => tokenStore.saveRefreshToken(any())).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'john@example.com',
        password: 'Password123',
      );

      expect(result.success, isTrue);
      expect(result.data, isA<User>());
      verify(() => tokenStore.saveAccessToken('access-token')).called(1);
      verify(() => tokenStore.saveRefreshToken('refresh-token')).called(1);
    });

    test('returns failure message when dio throws', () async {
      when(() => dio.post('/users/login', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/users/login'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/users/login'),
            statusCode: 401,
            data: <String, dynamic>{'message': 'Invalid credentials'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.login(
        email: 'john@example.com',
        password: 'wrong',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Invalid credentials');
      verifyNever(() => tokenStore.saveAccessToken(any()));
    });
  });

  group('AuthRepository.changePassword', () {
    test('returns auth required when token missing', () async {
      when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);

      final result = await repository.changePassword(
        currentPassword: 'oldPass123',
        newPassword: 'NewPass123',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Authentication required'));
      verifyNever(
        () => dio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });
  });

  group('AuthRepository.getEditableProfile', () {
    test('returns user map on success', () async {
      when(() => dio.get('/users/getUserdata')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/users/getUserdata'),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'user': <String, dynamic>{
              'first_name': 'John',
              'last_name': 'Doe',
              'phone_number': '0790000000',
            },
          },
        ),
      );

      final result = await repository.getEditableProfile();

      expect(result.success, isTrue);
      expect(result.data?['first_name'], 'John');
      expect(result.data?['phone_number'], '0790000000');
    });

    test('returns failure on malformed payload', () async {
      when(() => dio.get('/users/getUserdata')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/users/getUserdata'),
          statusCode: 200,
          data: <String, dynamic>{'success': true, 'user': 'invalid-shape'},
        ),
      );

      final result = await repository.getEditableProfile();

      expect(result.success, isFalse);
      expect(result.message, contains('Profile payload is missing'));
    });
  });

  group('AuthRepository.updateEditableProfile', () {
    test('returns auth required when access token is missing', () async {
      when(() => tokenStore.readAccessToken()).thenAnswer((_) async => null);

      final result = await repository.updateEditableProfile(
        fields: <String, String>{'first_name': 'John'},
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Authentication required'));
      verifyNever(
        () => dio.put(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('returns updated user on successful profile update', () async {
      when(
        () => tokenStore.readAccessToken(),
      ).thenAnswer((_) async => 'access-token');
      when(
        () => dio.put(
          '/users/edit',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/users/edit'),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'message': 'Updated',
            'user': <String, dynamic>{
              'first_name': 'Jane',
              'profile_pic_url': '/uploads/p.jpg',
            },
          },
        ),
      );

      final result = await repository.updateEditableProfile(
        fields: <String, String>{
          'first_name': 'Jane',
          'last_name': 'Doe',
          'username': 'jane',
          'phone_number': '0790000000',
          'country': 'Jordan',
        },
        existingProfilePicUrl: '/uploads/old.jpg',
      );

      expect(result.success, isTrue);
      expect(result.data?['first_name'], 'Jane');
      expect(result.data?['profile_pic_url'], '/uploads/p.jpg');
    });
  });
}
