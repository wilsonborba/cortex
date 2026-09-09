// Tests AppErrorView's conditional "contact support" button: shown only
// when a session cookie is present, omitted otherwise (no forced login flow
// from an error screen). The cookie itself can't be set from a VM widget
// test (no real browser cookie jar), so these tests exercise the
// "not logged in" (no cookie ever set) path directly, and rely on
// `readCsrfToken` returning null in this environment to make that
// deterministic - the same assumption `session_service_test`-style tests in
// this repo already lean on for VM tests.

import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/components/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('shows the generic friendly title/message', (tester) async {
    await tester.pumpWidget(_wrap(const AppErrorView(technicalSummary: 'boom')));
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.text('We hit an unexpected problem. You can let us know so we can look into it.'),
      findsOneWidget,
    );
  });

  testWidgets('omits the "contact support" button when no session cookie is present', (tester) async {
    // VM widget tests have no browser cookie jar: `readCsrfToken()` always
    // returns null here, i.e. "not logged in".
    await tester.pumpWidget(_wrap(const AppErrorView(technicalSummary: 'boom')));
    await tester.pump();

    expect(find.text('Contact support'), findsNothing);
    expect(find.byIcon(Icons.support_agent_outlined), findsNothing);
  });

  testWidgets('fromFlutterError builds a technical summary from the exception and library', (tester) async {
    final details = FlutterErrorDetails(
      exception: StateError('bad state'),
      library: 'test library',
    );
    final view = AppErrorView.fromFlutterError(details);

    expect(view.technicalSummary, contains('bad state'));
    expect(view.technicalSummary, contains('test library'));
  });

  test('summarizeError includes the route when provided', () {
    final summary = AppErrorView.summarizeError('network down', route: 'chat_send');

    expect(summary, contains('network down'));
    expect(summary, contains('chat_send'));
  });
}
