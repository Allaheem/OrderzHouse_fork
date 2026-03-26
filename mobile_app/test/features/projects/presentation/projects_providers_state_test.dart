import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/project.dart';
import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:OrderzHouse/features/projects/data/repositories/projects_repository.dart';
import 'package:OrderzHouse/features/projects/domain/usecases/get_explore_projects.dart';
import 'package:OrderzHouse/features/projects/presentation/providers/projects_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProjectsRepository extends Mock implements ProjectsRepository {}

class _MockGetExploreProjects extends Mock implements GetExploreProjects {}

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

Project _project(int id) {
  return Project(
    id: id,
    userId: 2,
    title: 'P$id',
    description: 'Desc',
    projectType: 'fixed',
    status: 'open',
    createdAt: DateTime(2025, 1, id),
  );
}

void main() {
  late ProjectsRepository projectsRepository;
  late GetExploreProjects getExploreProjects;
  late AuthRepository authRepository;

  setUp(() {
    projectsRepository = _MockProjectsRepository();
    getExploreProjects = _MockGetExploreProjects();
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.getUserData(),
    ).thenAnswer((_) async => const ApiResponse<User>(success: false));
  });

  test('myProjectsProvider returns empty when logged out', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        projectsRepositoryProvider.overrideWithValue(projectsRepository),
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

    final result = await container.read(myProjectsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => projectsRepository.getMyProjects());
  });

  test('myProjectsProvider returns repository data when logged in', () async {
    when(() => projectsRepository.getMyProjects()).thenAnswer(
      (_) async => ApiResponse<List<Project>>(
        success: true,
        data: <Project>[_project(1), _project(2)],
      ),
    );

    final container = ProviderContainer(
      overrides: <Override>[
        projectsRepositoryProvider.overrideWithValue(projectsRepository),
        authStateProvider.overrideWith((ref) {
          return _TestAuthNotifier(
            authRepository,
            ref,
            initial: const AuthState(
              user: User(id: 2, username: 'u', email: 'u@x.com', roleId: 2),
            ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(myProjectsProvider.future);

    expect(result, hasLength(2));
    verify(() => projectsRepository.getMyProjects()).called(1);
  });

  test(
    'exploreProjectsStateProvider resolves to empty when logged out',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          getExploreProjectsProvider.overrideWithValue(getExploreProjects),
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

      final notifier = container.read(exploreProjectsStateProvider.notifier);
      await notifier.load();
      final state = container.read(exploreProjectsStateProvider);
      expect(state.valueOrNull, isEmpty);
      verifyNever(
        () => getExploreProjects.call(
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          subCategoryId: any(named: 'subCategoryId'),
          subSubCategoryId: any(named: 'subSubCategoryId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          userRoleId: any(named: 'userRoleId'),
          sortBy: any(named: 'sortBy'),
        ),
      );
    },
  );

  test('exploreProjectsStateProvider sets data on success', () async {
    when(
      () => getExploreProjects.call(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
        subCategoryId: any(named: 'subCategoryId'),
        subSubCategoryId: any(named: 'subSubCategoryId'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        userRoleId: any(named: 'userRoleId'),
        sortBy: any(named: 'sortBy'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse<List<Project>>(
        success: true,
        data: <Project>[_project(3)],
      ),
    );

    final container = ProviderContainer(
      overrides: <Override>[
        getExploreProjectsProvider.overrideWithValue(getExploreProjects),
        authStateProvider.overrideWith((ref) {
          return _TestAuthNotifier(
            authRepository,
            ref,
            initial: const AuthState(
              user: User(id: 5, username: 'u', email: 'u@x.com', roleId: 3),
            ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(exploreProjectsStateProvider.notifier);
    await notifier.load();
    final state = container.read(exploreProjectsStateProvider);

    expect(state.valueOrNull, isNotNull);
    expect(state.valueOrNull, hasLength(1));
    expect(state.valueOrNull?.first.id, 3);
  });

  test(
    'exploreProjectsStateProvider emits error when fetch fails and no cache',
    () async {
      when(
        () => getExploreProjects.call(
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
          subCategoryId: any(named: 'subCategoryId'),
          subSubCategoryId: any(named: 'subSubCategoryId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          userRoleId: any(named: 'userRoleId'),
          sortBy: any(named: 'sortBy'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponse<List<Project>>(
          success: false,
          message: 'Failed remote',
        ),
      );

      final container = ProviderContainer(
        overrides: <Override>[
          getExploreProjectsProvider.overrideWithValue(getExploreProjects),
          authStateProvider.overrideWith((ref) {
            return _TestAuthNotifier(
              authRepository,
              ref,
              initial: const AuthState(
                user: User(id: 8, username: 'u', email: 'u@x.com', roleId: 2),
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(exploreProjectsStateProvider.notifier);
      await notifier.load();

      final state = container.read(exploreProjectsStateProvider);
      expect(state.hasError, isTrue);
    },
  );

  test(
    'workspaceItemsProvider returns active subset from myProjects',
    () async {
      final projects = <Project>[
        _project(1).copyWith(status: 'active', createdAt: DateTime(2025, 1, 3)),
        _project(
          2,
        ).copyWith(status: 'completed', createdAt: DateTime(2025, 1, 2)),
        _project(
          3,
        ).copyWith(status: 'in_progress', createdAt: DateTime(2025, 1, 1)),
      ];

      final container = ProviderContainer(
        overrides: <Override>[
          myProjectsProvider.overrideWith((ref) async => projects),
          authStateProvider.overrideWith((ref) {
            return _TestAuthNotifier(
              authRepository,
              ref,
              initial: const AuthState(
                user: User(id: 14, username: 'u', email: 'u@x.com', roleId: 2),
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myProjectsProvider.future);
      final items = container.read(workspaceItemsProvider);
      expect(items.valueOrNull, hasLength(2));
      expect(items.valueOrNull?.map((p) => p.id), containsAll(<int>[1, 3]));
    },
  );

  test(
    'workspaceItemsProvider uses workspaceInProgressProjectsProvider for client actionRequired',
    () async {
      final inProgress = <Project>[_project(10), _project(11)];
      final container = ProviderContainer(
        overrides: <Override>[
          workspaceInProgressProjectsProvider.overrideWith(
            (ref) async => inProgress,
          ),
          authStateProvider.overrideWith((ref) {
            return _TestAuthNotifier(
              authRepository,
              ref,
              initial: const AuthState(
                user: User(id: 15, username: 'u', email: 'u@x.com', roleId: 2),
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(workspaceTabProvider.notifier).state =
          WorkspaceTab.actionRequired;

      final _ = await container.read(
        workspaceInProgressProjectsProvider.future,
      );
      final items = container.read(workspaceItemsProvider);
      expect(items.valueOrNull, hasLength(2));
    },
  );

  test(
    'workspaceItemsProvider filters freelancer actionRequired statuses',
    () async {
      final projects = <Project>[
        _project(1).copyWith(status: 'pending_review'),
        _project(2).copyWith(status: 'changes_requested'),
        _project(3).copyWith(status: 'active'),
      ];

      final container = ProviderContainer(
        overrides: <Override>[
          myProjectsProvider.overrideWith((ref) async => projects),
          authStateProvider.overrideWith((ref) {
            return _TestAuthNotifier(
              authRepository,
              ref,
              initial: const AuthState(
                user: User(id: 16, username: 'u', email: 'u@x.com', roleId: 3),
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(workspaceTabProvider.notifier).state =
          WorkspaceTab.actionRequired;
      await container.read(myProjectsProvider.future);
      final items = container.read(workspaceItemsProvider);
      expect(items.valueOrNull, hasLength(2));
      expect(
        items.valueOrNull?.map((p) => p.status),
        containsAll(<String>['pending_review', 'changes_requested']),
      );
    },
  );

  test(
    'profileStatsProvider computes total active and completed counts',
    () async {
      final projects = <Project>[
        _project(1).copyWith(status: 'active'),
        _project(2).copyWith(status: 'in_progress'),
        _project(3).copyWith(status: 'completed'),
        _project(4).copyWith(status: 'done'),
      ];

      final container = ProviderContainer(
        overrides: <Override>[
          myProjectsProvider.overrideWith((ref) async => projects),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myProjectsProvider.future);
      final statsAsync = container.read(profileStatsProvider);
      final stats = statsAsync.valueOrNull;
      expect(stats, isNotNull);
      expect(stats?.total, 4);
      expect(stats?.active, 2);
      expect(stats?.completed, 2);
    },
  );
}
