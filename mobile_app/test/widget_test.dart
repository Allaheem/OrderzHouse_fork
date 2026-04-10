import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default template test targeted a counter app; OrderzHouse uses GoRouter/Riverpod.
/// Replace with a routed smoke test when test harness loads .env/bootstrap is mocked.
void main() {
  testWidgets('Material smoke — Flutter test harness OK', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('ok'))),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
