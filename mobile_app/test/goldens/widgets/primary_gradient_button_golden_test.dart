import 'package:OrderzHouse/core/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
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

    await tester.pumpWidgetBuilder(
      builder.build(),
      surfaceSize: const Size(300, 200),
    );
    await screenMatchesGolden(
      tester,
      'goldens/widgets/primary_gradient_button',
    );
  });
}
