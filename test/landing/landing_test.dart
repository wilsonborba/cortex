import 'dart:io';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/screens/landing/demo.dart';
import 'package:cortex/presentation/frontend/screens/landing/diagrams.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeAuth extends AuthService {
  FakeAuth() : super(AuthApiAdapter());
  final returns = <String?>[];
  @override
  Future<void> signIn({String? returnPath}) async => returns.add(returnPath);
}

Future<(GoRouter, FakeAuth)> pump(
  WidgetTester tester,
  String location, {
  Size size = const Size(1300, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(
    service: SessionService(cookieReader: () => null),
  );
  final auth = FakeAuth();
  final router = buildRouter(
    session: session,
    auth: auth,
    initialLocation: location,
  );
  await tester.pumpWidget(
    PreferencesScope(
      preferences: Preferences(),
      child: MaterialApp.router(
        routerConfig: router,
        theme: cortexTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await frames(tester);
  return (router, auth);
}

/// Demo and diagram timers never settle, so pump short frames.
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String path(GoRouter r) => r.routerDelegate.currentConfiguration.uri.toString();

Widget demo({bool still = false}) => MaterialApp(
  theme: cortexTheme(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: const Scaffold(
      body: SingleChildScrollView(
        child: ChatDemo(stepDelay: Duration(milliseconds: 100)),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'expanded header: logo, 5 section links, language, theme, Log in',
    (tester) async {
      final (_, auth) = await pump(tester, '/v1/home');
      final header = find.byKey(const Key('landing-header'));
      expect(tester.getSize(header).height, lessThanOrEqualTo(64));
      for (final name in [
        'product',
        'howItWorks',
        'memory',
        'engineering',
        'faq',
      ]) {
        expect(find.byKey(Key('link-$name')), findsOneWidget);
      }
      expect(find.byTooltip('Language'), findsOneWidget);
      expect(find.byTooltip('Theme'), findsOneWidget);
      expect(
        find.descendant(of: header, matching: find.text('Log in')),
        findsOneWidget,
      );
      // Start a chat is the only primary and opens the SSO.
      await tester.tap(find.byKey(const Key('start-chat')));
      expect(auth.returns, ['/v1/chats']);
    },
  );

  testWidgets(
    'medium keeps language and theme with a section menu; compact has logo, Log in and a menu',
    (tester) async {
      await pump(tester, '/v1/home', size: const Size(800, 900));
      expect(find.byKey(const Key('link-faq')), findsNothing);
      expect(find.byKey(const Key('section-menu')), findsOneWidget);
      expect(find.byTooltip('Theme'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final (router, _) = await pump(
        tester,
        '/v1/home',
        size: const Size(390, 800),
      );
      expect(find.byKey(const Key('link-faq')), findsNothing);
      expect(find.text('Log in'), findsWidgets);
      await tester.tap(find.byKey(const Key('section-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FAQ').last);
      await tester.pumpAndSettle();
      expect(path(router), '/v1/home/faq');
    },
  );

  testWidgets('each section link updates the path and shows the section', (
    tester,
  ) async {
    final (router, _) = await pump(tester, '/v1/home');
    for (final (link, target, title) in [
      ('howItWorks', '/v1/home/how-it-works', 'How one request works'),
      ('memory', '/v1/home/memory', 'Memory with Hippocampus'),
      ('engineering', '/v1/home/engineering', 'Engineering'),
      ('faq', '/v1/home/faq', 'FAQ'),
      ('product', '/v1/home', 'AI chat workspace'),
    ]) {
      await tester.tap(find.byKey(Key('link-$link')));
      await frames(tester);
      expect(path(router), target);
      final y = tester.getTopLeft(find.text(title).last).dy;
      expect(y, inInclusiveRange(0, 900), reason: link);
    }
  });

  testWidgets('a section path opens the page at that section', (tester) async {
    await pump(tester, '/v1/home/faq');
    expect(
      tester.getTopLeft(find.text('Do I need an account?')).dy,
      inInclusiveRange(0, 900),
    );
  });

  testWidgets('the demo replays each of the 4 prompts', (tester) async {
    await tester.pumpWidget(demo());
    for (final kind in DemoKind.values) {
      await tester.tap(find.byKey(Key('demo-${kind.name}')));
      await tester.pump();
      expect(
        find.byKey(const Key('demo-answer')),
        findsNothing,
        reason: '${kind.name} replays from the start',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const Key('demo-answer')),
        findsOneWidget,
        reason: kind.name,
      );
    }
    expect(find.text('Example'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('with Reduce Motion the demo shows the end state at once', (
    tester,
  ) async {
    await tester.pumpWidget(demo(still: true));
    for (final kind in DemoKind.values) {
      await tester.tap(find.byKey(Key('demo-${kind.name}')));
      await tester.pump();
      expect(
        find.byKey(const Key('demo-answer')),
        findsOneWidget,
        reason: kind.name,
      );
    }
  });

  testWidgets(
    'pipeline: active stage moves, Pause/Play; static with Reduce Motion',
    (tester) async {
      Widget pipeline(bool still) => MaterialApp(
        theme: cortexTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: const Scaffold(
            body: PipelineDiagram(interval: Duration(milliseconds: 100)),
          ),
        ),
      );
      await tester.pumpWidget(pipeline(false));
      expect(find.text('Pause'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pipeline-toggle')));
      await tester.pump();
      expect(find.text('Play'), findsOneWidget);
      await tester.pumpWidget(pipeline(true));
      await tester.pump();
      expect(find.byKey(const Key('pipeline-toggle')), findsNothing);
      expect(find.text('1. Accept'), findsOneWidget);
      expect(find.text('6. Save'), findsOneWidget);
    },
  );

  test('CREDITS.md exists and lists the image sources', () {
    final credits = File(
      'lib/presentation/frontend/assets/CREDITS.md',
    ).readAsStringSync();
    expect(credits, contains('No image was downloaded'));
  });
}
