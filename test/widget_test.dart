// Smoke tests: the app boots into the landing page, guest mode reaches the
// chat screen, and no session/guest flag routes to the landing page.
//
// `pumpAndSettle` is intentionally avoided past the first frame: both the
// loading spinner and the landing page's chromatic particle background are
// perpetual animations, they never "settle".

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cortex/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the landing page when no session or guest flag exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CortexApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Sign in with Asodya'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('continuing as guest reaches the chat screen and prompt dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CortexApp());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Continue as Guest'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Message Cortex...'), findsOneWidget);
    expect(find.textContaining('Tier 0'), findsWidgets);
  });
}
