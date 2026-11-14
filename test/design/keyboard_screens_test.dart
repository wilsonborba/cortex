import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../memory/memory_test.dart' as memory;
import 'final_layout_test.dart' show stressClient;

/// #69 keyboard check: Tab reaches many controls on every screen without an
/// error, and Esc closes the details panel.
void main() {
  Future<DetailsController> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Repeating spinners stop with Reduce Motion, so the screens settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final session = SessionController(
      service: SessionService(cookieReader: () => 'synthetic-session'),
    );
    await session.refresh();
    final prefs = Preferences();
    final details = DetailsController();
    final router = buildRouter(
      session: session,
      auth: memory.Auth(),
      details: details,
      api: CortexApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: stressClient(),
      ),
      emailLoader: () async => 'keyboard.reader@example.test',
      initialLocation: path,
    );
    addTearDown(router.dispose);
    addTearDown(session.dispose);
    addTearDown(prefs.dispose);
    await tester.pumpWidget(
      PreferencesScope(
        preferences: prefs,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: cortexTheme(Brightness.dark),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return details;
  }

  for (final path in [
    '/v1/home',
    '/v1/home/engineering',
    '/v1/chats',
    '/v1/settings',
    '/v1/settings/memory',
    '/v1/settings/personas',
    '/v1/usage',
    '/v1/usage/events',
  ]) {
    testWidgets('Tab reaches the controls of $path', (tester) async {
      await open(tester, path);
      final seen = <FocusNode>{};
      for (var i = 0; i < 25; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final node = FocusManager.instance.primaryFocus;
        if (node != null) seen.add(node);
      }
      expect(seen.length, greaterThanOrEqualTo(6), reason: path);
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      expect(tester.takeException(), isNull, reason: path);
    });
  }

  testWidgets('Esc closes the details panel', (tester) async {
    final details = await open(tester, '/v1/chats');
    details.show(const Text('synthetic details'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('details-panel')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('details-panel')), findsNothing);
  });
}
