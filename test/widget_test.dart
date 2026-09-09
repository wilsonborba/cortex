import 'package:flutter_test/flutter_test.dart';

import 'package:cortex/app.dart';

void main() {
  testWidgets('shows the landing page with [ Get Started ] when no session exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CortexApp(sessionCookieReader: () => null));
    await tester.pump();
    await tester.pump();

    expect(find.text('[ Get Started ]'), findsOneWidget);
    expect(find.text('CORTEX'), findsWidgets);
  });

  testWidgets('authenticated session reaches the chat screen and prompt dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CortexApp(sessionCookieReader: () => 'fake-csrf-token'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Message Cortex (Tier 0)...'), findsOneWidget);
    expect(find.textContaining('TIER 0'), findsWidgets);
  });
}
