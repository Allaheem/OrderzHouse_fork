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
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login failure flow shows backend error message', (tester) async {
    final repository = _MockAuthRepository();
    when(
      () => repository.getUserData(),
    ).thenAnswer((_) async => const ApiResponse<User>(success: false));
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

    await tester.pumpWidget(
      ProviderScope(
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'john@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'badPass123');
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
