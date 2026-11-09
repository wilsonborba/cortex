import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cortex/app.dart';

void main() {
  testWidgets('the public shell shows login and the build', (tester) async {
    await tester.pumpWidget(const CortexApp());
    await tester.pumpAndSettle();
    expect(find.text('Cortex'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('2.0.0-dev'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      isNotNull,
    );
  });
}
