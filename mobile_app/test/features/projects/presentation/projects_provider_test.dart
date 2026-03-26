import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/project.dart';
import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:OrderzHouse/features/projects/data/repositories/projects_repository.dart';
import 'package:OrderzHouse/features/projects/presentation/providers/projects_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProjectsRepository extends Mock implements ProjectsRepository {}

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
  late ProjectsRepository projectsRepository;
  late AuthRepository authRepository;

  setUp(() {
    projectsRepository = _MockProjectsRepository();
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.getUserData(),
    ).thenAnswer((_) async => const ApiResponse<User>(success: false));
  });

  test('projectByIdProvider returns project when found in raw list', () async {
    when(
      () => projectsRepository.getMyProjectsRaw(limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => const ApiResponse<List<Map<String, dynamic>>>(
        success: true,
        data: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 22,
            'user_id': 2,
            'title': 'Project 22',
            'description': 'D',
            'project_type': 'fixed',
            'status': 'open',
            'created_at': '2025-01-01T00:00:00.000Z',
          },
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: <Override>[
        projectsRepositoryProvider.overrideWithValue(projectsRepository),
      ],
    );
    addTearDown(container.dispose);

    final project = await container.read(projectByIdProvider(22).future);
    expect(project, isNotNull);
    expect(project?.id, 22);
  });

  test('latestProjectsProvider returns empty for logged out user', () async {
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

    final result = await container.read(latestProjectsProvider.future);
    expect(result, isEmpty);
    verifyNever(
      () => projectsRepository.fetchExploreProjects(
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
  });

  test('latestProjectsProvider returns top two projects on success', () async {
    when(
      () => projectsRepository.fetchExploreProjects(
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
        data: <Project>[
          Project(
            id: 1,
            userId: 2,
            title: 'P1',
            description: 'D',
            projectType: 'fixed',
            status: 'open',
            createdAt: DateTime(2025, 1, 3),
          ),
          Project(
            id: 2,
            userId: 2,
            title: 'P2',
            description: 'D',
            projectType: 'fixed',
            status: 'open',
            createdAt: DateTime(2025, 1, 2),
          ),
          Project(
            id: 3,
            userId: 2,
            title: 'P3',
            description: 'D',
            projectType: 'fixed',
            status: 'open',
            createdAt: DateTime(2025, 1, 1),
          ),
        ],
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
              user: User(id: 9, username: 'u', email: 'u@x.com', roleId: 2),
            ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(latestProjectsProvider.future);
    expect(result, hasLength(2));
    expect(result.first.id, 1);
    expect(result[1].id, 2);
  });
}
