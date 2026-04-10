import 'package:OrderzHouse/core/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('PrimaryGradientButton renders default state', (tester) async {
    final builder = GoldenBuilder.column()
      ..addScenario(
        'default',
        const Center(
          child: PrimaryGradientButton(
            onPressed: null,
            label: 'Continue',
            isEnabled: true,
          ),
        ),
      )
      ..addScenario(
        'loading',
        const Center(
          child: PrimaryGradientButton(
            onPressed: null,
            label: 'Continue',
            isLoading: true,
          ),
        ),
      );

    const surface = Size(320, 420);
    await tester.pumpWidgetBuilder(
      ScreenUtilInit(
        designSize: surface,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => builder.build(),
      ),
      surfaceSize: surface,
    );
    await screenMatchesGolden(
      tester,
      'widgets/primary_gradient_button',
      // CircularProgressIndicator never settles; avoid pumpAndSettle timeout.
      customPump: (tester) async {
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
