import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/models/signup_payload.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  late _MockAuthRepository repository;

  User testUser() =>
      const User(id: 1, username: 'john', email: 'john@example.com', roleId: 2);

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.getUserData()).thenAnswer(
      (_) async =>
          const ApiResponse<User>(success: false, message: 'No session'),
    );
  });

  StateNotifierProvider<AuthNotifier, AuthState> buildProvider({
    Future<String?> Function()? readAccessToken,
    Future<void> Function()? clearCache,
    Future<void> Function()? clearLastRoute,
    Future<User?> Function()? readCachedUser,
    Future<void> Function(User user)? writeCachedUser,
    Future<void> Function()? clearCachedUser,
  }) {
    return StateNotifierProvider<AuthNotifier, AuthState>((ref) {
      return AuthNotifier(
        repository,
        ref,
        readAccessToken: readAccessToken ?? () async => null,
        clearCache: clearCache ?? () async {},
        clearLastRoute: clearLastRoute ?? () async {},
        readCachedUser: readCachedUser ?? () async => null,
        writeCachedUser: writeCachedUser ?? (_) async {},
        clearCachedUser: clearCachedUser ?? () async {},
      );
    });
  }

  test('restoreSession emits unauthenticated when token is missing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = buildProvider(readAccessToken: () async => null);

    container.read(provider.notifier);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(provider);
    expect(state.isChecking, isFalse);
    expect(state.isAuthenticated, isFalse);
  });

  test('login emits authenticated user on success', () async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse<User>(success: true, data: testUser()),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = buildProvider();

    final notifier = container.read(provider.notifier);
    final success = await notifier.login('john@example.com', 'Password123');

    expect(success, isTrue);
    expect(container.read(provider).user?.email, 'john@example.com');
  });

  test('login emits error on failure', () async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const ApiResponse<User>(
        success: false,
        message: 'Invalid credentials',
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = buildProvider();

    final notifier = container.read(provider.notifier);
    final success = await notifier.login('john@example.com', 'bad');

    expect(success, isFalse);
    expect(container.read(provider).error, 'Invalid credentials');
  });

  test('verifyOtpAndCompleteSignup handles missing pending payload', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = buildProvider();

    final notifier = container.read(provider.notifier);
    await Future<void>.delayed(Duration.zero);
    final success = await notifier.verifyOtpAndCompleteSignup('123456');

    expect(success, isFalse);
    expect(container.read(provider).error, contains('Session expired'));
  });

  test('logout clears state and pending payload', () async {
    when(() => repository.logout()).thenAnswer((_) async {});
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse<User>(success: true, data: testUser()),
    );

    var cacheCleared = false;
    var routeCleared = false;

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = buildProvider(
      clearCache: () async => cacheCleared = true,
      clearLastRoute: () async => routeCleared = true,
    );

    final notifier = container.read(provider.notifier);
    await notifier.login('john@example.com', 'Password123');
    await notifier.logout();

    expect(container.read(provider).isAuthenticated, isFalse);
    expect(cacheCleared, isTrue);
    expect(routeCleared, isTrue);
  });

  test('startSignup handles success and message state', () async {
    when(() => repository.requestSignupOtp(any())).thenAnswer(
      (_) async => const ApiResponse<void>(success: true, message: 'OTP sent'),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = buildProvider();
    final notifier = container.read(provider.notifier);

    const payload = SignupPayload(
      roleId: 2,
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@example.com',
      password: 'Password123',
      phoneNumber: '+1234',
      country: 'US',
      username: 'jane',
    );

    final success = await notifier.startSignup(payload);

    expect(success, isTrue);
    expect(container.read(provider).error, 'OTP sent');
  });
}
