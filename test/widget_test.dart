// Basic smoke test: the app boots and renders the prompt dock.

import 'package:flutter_test/flutter_test.dart';

import 'package:cortex/app.dart';

void main() {
  testWidgets('Cortex app boots and shows the prompt dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CortexApp());
    await tester.pumpAndSettle();

    expect(find.text('Message Cortex...'), findsOneWidget);
    expect(find.textContaining('Tier 0'), findsWidgets);
  });
}
