import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cortex/app.dart';

void main() {
  testWidgets('the public landing shows login and the build version', (
    tester,
  ) async {
    await tester.pumpWidget(const CortexApp(initialLocation: '/v1/home'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Cortex'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Version 2.0.0-dev'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      isNotNull,
    );
  });
}
