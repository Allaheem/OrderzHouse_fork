import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/core/models/user.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:OrderzHouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:OrderzHouse/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:OrderzHouse/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository authRepository;
  void Function(FlutterErrorDetails)? oldErrorHandler;

  setUp(() {
    oldErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) {
        return;
      }
      oldErrorHandler?.call(details);
    };

    authRepository = _MockAuthRepository();
    when(
      () => authRepository.getUserData(),
    ).thenAnswer((_) async => const ApiResponse<User>(success: false));
  });

  tearDown(() {
    FlutterError.onError = oldErrorHandler;
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(authRepository),
        authStateProvider.overrideWith((ref) {
          return AuthNotifier(
            authRepository,
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
          home: VerifyEmailScreen(email: 'user@example.com'),
        ),
      ),
    );
  }

  testWidgets('renders verify email screen content', (tester) async {
    tester.view.physicalSize = const Size(1800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('shows validation snackbar for empty otp', (tester) async {
    tester.view.physicalSize = const Size(1800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(find.text('Please enter the verification code'), findsOneWidget);
  });
}
