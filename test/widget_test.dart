import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cortex/app.dart';
import 'package:cortex/core/settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the landing page with [ Get Started ] when no session exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CortexApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('[ Get Started ]'), findsOneWidget);
    expect(find.text('CORTEX'), findsWidgets);
  });

  testWidgets('authenticated session reaches the chat screen and prompt dock', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppSettings.sessionActiveStorageKey: true,
    });

    await tester.pumpWidget(const CortexApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Message Cortex (Tier 0)...'), findsOneWidget);
    expect(find.textContaining('TIER 0'), findsWidgets);
  });
}
