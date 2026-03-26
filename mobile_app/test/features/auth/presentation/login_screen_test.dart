import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:OrderzHouse/features/auth/presentation/screens/login_screen.dart';
import 'package:OrderzHouse/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  void Function(FlutterErrorDetails)? oldErrorHandler;

  setUp(() {
    oldErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final exception = details.exceptionAsString();
      if (exception.contains('A RenderFlex overflowed')) {
        return;
      }
      oldErrorHandler?.call(details);
    };

    repository = _MockAuthRepository();
    when(
      () => repository.getUserData(),
    ).thenAnswer((_) async => const ApiResponse<User>(success: false));
  });

  tearDown(() {
    FlutterError.onError = oldErrorHandler;
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(repository),
        authStateProvider.overrideWith((ref) {
          return AuthNotifier(
            repository,
            ref,
            readAccessToken: () async => null,
            clearCache: () async {},
            clearLastRoute: () async {},
          );
        }),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
  }

  testWidgets('renders login form fields', (tester) async {
    tester.view.physicalSize = const Size(1600, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets('shows validation errors on empty submit', (tester) async {
    tester.view.physicalSize = const Size(1600, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const ApiResponse<User>(success: false, message: 'Invalid'),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login').last);
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Field is required'), findsOneWidget);
  });

  testWidgets('shows snackbar on login failure', (tester) async {
    tester.view.physicalSize = const Size(1600, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'john@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
