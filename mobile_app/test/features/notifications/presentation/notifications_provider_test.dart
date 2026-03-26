import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/notification_model.dart';
import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:OrderzHouse/features/notifications/data/repositories/notifications_repository.dart';
import 'package:OrderzHouse/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(super.repository, super.ref, {required AuthState initial})
    : super(
        readAccessToken: () async => null,
        clearCache: () async {},
        clearLastRoute: () async {},
      ) {
    state = initial;
  }

  @override
  Future<void> restoreSession() async {}
}

void main() {
  late NotificationsRepository notificationsRepository;
  late AuthRepository authRepository;

  setUp(() {
    notificationsRepository = _MockNotificationsRepository();
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.getUserData(),
    ).thenAnswer((_) async => const ApiResponse<User>(success: false));
  });

  test('notificationsProvider returns empty list when logged out', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        notificationsRepositoryProvider.overrideWithValue(
          notificationsRepository,
        ),
        authStateProvider.overrideWith((ref) {
          return _TestAuthNotifier(
            authRepository,
            ref,
            initial: const AuthState(),
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final list = await container.read(notificationsProvider.future);
    expect(list, isEmpty);
    verifyNever(
      () => notificationsRepository.fetchNotifications(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    );
  });

  test('notificationsProvider returns data when logged in', () async {
    when(
      () => notificationsRepository.fetchNotifications(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        unreadOnly: any(named: 'unreadOnly'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse<List<AppNotification>>(
        success: true,
        data: <AppNotification>[
          AppNotification(
            id: 1,
            title: 'Title',
            body: 'Message',
            type: NotificationType.systemAnnouncement,
            isRead: false,
            createdAt: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: <Override>[
        notificationsRepositoryProvider.overrideWithValue(
          notificationsRepository,
        ),
        authStateProvider.overrideWith((ref) {
          return _TestAuthNotifier(
            authRepository,
            ref,
            initial: const AuthState(
              user: User(id: 1, username: 'u', email: 'u@x.com', roleId: 2),
            ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen<AsyncValue<List<AppNotification>>>(
      notificationsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    final list = await container.read(notificationsProvider.future);
    expect(list, hasLength(1));
  });
}
