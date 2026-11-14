import 'package:cortex/presentation/frontend/screens/landing/landing_page.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
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
  var signOuts = 0;
  @override
  Future<void> signIn({String? returnPath}) async => returns.add(returnPath);
  @override
  Future<void> signOut() async => signOuts++;
}

Future<(GoRouter, FakeAuth)> pump(
  WidgetTester tester,
  String location, {
  Size size = const Size(1300, 900),
  Locale locale = const Locale('en'),
  double scale = 1,
  bool signedIn = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(
    service: SessionService(cookieReader: () => signedIn ? 'csrf' : null),
  );
  await session.refresh();
  final auth = FakeAuth();
  final router = buildRouter(
    session: session,
    auth: auth,
    initialLocation: location,
    emailLoader: () async => signedIn ? 'ana@example.com' : null,
    // Signed in tests open the app: a plain screen instead of live data.
    screen: signedIn ? (_, title) => Text('screen $title') : null,
  );
  await tester.pumpWidget(
    PreferencesScope(
      preferences: Preferences(),
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: scale > 1,
          ),
          child: child!,
        ),
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
      expect(find.byKey(const Key('language-switch')), findsOneWidget);
      expect(find.byKey(const Key('theme-switch')), findsOneWidget);
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
      expect(find.byKey(const Key('theme-switch')), findsOneWidget);
      expect(tester.takeException(), isNull);
      final (router, _) = await pump(
        tester,
        '/v1/home',
        size: const Size(390, 800),
      );
      expect(find.byKey(const Key('link-faq')), findsNothing);
      expect(find.text('Log in'), findsWidgets);
      // Compact: language and theme live in the menu (#72).
      expect(find.byKey(const Key('theme-switch')), findsNothing);
      await tester.tap(find.byKey(const Key('section-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('language-switch')), findsOneWidget);
      expect(find.byKey(const Key('theme-switch')), findsOneWidget);
      await tester.tap(find.text('FAQ').last);
      await tester.pumpAndSettle();
      expect(path(router), '/v1/home/faq');
    },
  );

  group('with a session (#75)', () {
    testWidgets('expanded header shows the account avatar, not Log in', (
      tester,
    ) async {
      final (router, auth) = await pump(tester, '/v1/home', signedIn: true);
      final header = find.byKey(const Key('landing-header'));
      expect(
        find.descendant(of: header, matching: find.text('Log in')),
        findsNothing,
      );
      expect(find.byKey(const Key('landing-account')), findsOneWidget);
      // The avatar shows the first letter of the email.
      expect(
        find.descendant(
          of: find.byKey(const Key('landing-account')),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
      // Start a chat opens the chats with no new login.
      await tester.tap(find.byKey(const Key('start-chat')));
      await frames(tester);
      expect(path(router), '/v1/chats');
      expect(auth.returns, isEmpty);
    });

    testWidgets('the account menu shows the email and logs out', (
      tester,
    ) async {
      final (_, auth) = await pump(tester, '/v1/home', signedIn: true);
      await tester.tap(find.byKey(const Key('landing-account')));
      await tester.pumpAndSettle();
      expect(find.text('ana@example.com'), findsOneWidget);
      await tester.tap(find.byKey(const Key('landing-log-out')));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      expect(auth.returns, isEmpty);
    });

    testWidgets('compact: avatar instead of Log in on every public page', (
      tester,
    ) async {
      for (final page in [
        '/v1/home',
        '/v1/home/how-it-works',
        '/v1/home/memory',
        '/v1/home/engineering',
        '/v1/home/faq',
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, page, size: const Size(390, 800), signedIn: true);
        expect(find.text('Log in'), findsNothing, reason: page);
        expect(
          find.byKey(const Key('landing-account')),
          findsOneWidget,
          reason: page,
        );
        expect(tester.takeException(), isNull, reason: page);
      }
    });

    testWidgets('the final card opens the chats', (tester) async {
      final (router, auth) = await pump(tester, '/v1/home', signedIn: true);
      final card = find.byKey(const Key('landing-final-action'));
      final button = find.descendant(
        of: card,
        matching: find.text('Start a chat'),
      );
      await tester.ensureVisible(button);
      await frames(tester);
      await tester.tap(button);
      await frames(tester);
      expect(path(router), '/v1/chats');
      expect(auth.returns, isEmpty);
    });
  });

  testWidgets('without a session Log in and Start a chat open the login', (
    tester,
  ) async {
    final (_, auth) = await pump(tester, '/v1/home');
    expect(find.byKey(const Key('landing-account')), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('landing-header')),
        matching: find.text('Log in'),
      ),
    );
    await tester.tap(find.byKey(const Key('start-chat')));
    expect(auth.returns, ['/v1/chats', '/v1/chats']);
  });

  testWidgets('each page link changes the path and shows only that subject', (
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
      for (final other in [
        'How one request works',
        'Memory with Hippocampus',
        'Engineering',
        'AI chat workspace',
      ]) {
        if (other != title) {
          // Engineering also labels the shared navigation link.
          final matches = find.text(other);
          expect(
            matches,
            other == 'Engineering' ? findsOneWidget : findsNothing,
          );
        }
      }
      final y = tester.getTopLeft(find.text(title).last).dy;
      expect(y, inInclusiveRange(0, 900), reason: link);
    }
  });

  testWidgets('a direct FAQ path opens only the FAQ subject', (tester) async {
    await pump(tester, '/v1/home/faq');
    expect(
      tester.getTopLeft(find.text('Do I need an account?')).dy,
      inInclusiveRange(0, 900),
    );
  });

  testWidgets('public routes isolate their subjects in EN, PT-BR and TH', (
    tester,
  ) async {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      final l = await AppLocalizations.delegate.load(locale);
      final subjects = {
        '/v1/home': [l.heroTitle, l.whatTitle],
        '/v1/home/how-it-works': [l.pipelineTitle, l.webTitle, l.liveTitle],
        '/v1/home/memory': [l.memoryTitle],
        '/v1/home/engineering': [l.engTitle, l.researchTitle, l.securityTitle],
        '/v1/home/faq': [l.faq],
      };
      for (final route in subjects.entries) {
        await tester.pumpWidget(const SizedBox());
        await pump(
          tester,
          route.key,
          locale: locale,
          size: const Size(390, 800),
        );
        final body = find.descendant(
          of: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.header == true,
          ),
          matching: find.byType(Text),
        );
        final text = tester.widgetList<Text>(body).map((w) => w.data).toList();
        for (final subject in subjects.entries) {
          for (final heading in subject.value) {
            expect(
              text.contains(heading),
              subject.key == route.key,
              reason: '$locale ${route.key}: $heading',
            );
          }
        }
        expect(tester.takeException(), isNull);
      }
    }
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

  testWidgets('demo geometry stays still during replay and prompt changes', (
    tester,
  ) async {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      for (final width in [390.0, 1300.0]) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, '/v1/home', locale: locale, size: Size(width, 900));
        final card = find.byKey(const Key('chat-demo'));
        final original = tester.getSize(card);
        for (final kind in DemoKind.values) {
          await tester.ensureVisible(find.byKey(Key('demo-${kind.name}')));
          await tester.tap(find.byKey(Key('demo-${kind.name}')));
          for (var frame = 0; frame < 9; frame++) {
            await tester.pump(const Duration(milliseconds: 400));
            expect(
              tester.getSize(card),
              original,
              reason: '$locale $width $kind',
            );
          }
        }
        expect(tester.takeException(), isNull);
      }
    }
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

  testWidgets('static thinking example roles use EN, PT-BR and TH', (
    tester,
  ) async {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        '/v1/home',
        locale: locale,
        size: const Size(1300, 900),
      );
      final l = await AppLocalizations.delegate.load(locale);
      for (final role in [l.rolePlan, l.roleWork, l.roleCheck]) {
        expect(find.text('${l.stepThinking}: $role'), findsOneWidget);
      }
      if (locale.languageCode != 'en') {
        for (final role in ['plan', 'work', 'check']) {
          expect(find.text('${l.stepThinking}: $role'), findsNothing);
        }
      }
    }
  });

  testWidgets('landing header fits three locales and widths at 200 percent', (
    tester,
  ) async {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      for (final width in [390.0, 800.0, 1300.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const SizedBox());
        var selected = false;
        await tester.pumpWidget(
          PreferencesScope(
            preferences: Preferences(),
            child: MaterialApp(
              locale: locale,
              theme: cortexTheme(Brightness.dark),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: LandingHeader(
                  size: SizeClass.of(width),
                  onSignIn: () {},
                  onSection: (_) => selected = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale $width');
        expect(
          tester.getSize(find.byKey(const Key('landing-header'))).height,
          64,
        );
        final l = await AppLocalizations.delegate.load(locale);
        expect(find.text(l.logIn), findsOneWidget);
        if (width > 1000) {
          final last = find.byKey(const Key('link-faq'));
          await tester.ensureVisible(last);
          await tester.tap(last);
          await tester.pumpAndSettle();
          expect(selected, isTrue);
        } else {
          expect(find.byKey(const Key('section-menu')), findsOneWidget);
        }
      }
    }
    tester.view.reset();
  });

  testWidgets(
    'full landing final action fits and works at 200 percent in all locales',
    (tester) async {
      for (final locale in [
        const Locale('en'),
        const Locale('pt', 'BR'),
        const Locale('th'),
      ]) {
        for (final width in [390.0, 800.0, 1300.0]) {
          await tester.pumpWidget(const SizedBox());
          final (_, auth) = await pump(
            tester,
            '/v1/home',
            locale: locale,
            size: Size(width, 900),
            scale: 2,
          );
          expect(tester.takeException(), isNull, reason: '$locale $width');
          final l = await AppLocalizations.delegate.load(locale);
          final button = find.descendant(
            of: find.byKey(const Key('landing-final-action')),
            matching: find.text(l.startChat),
          );
          await tester.ensureVisible(button);
          await tester.tap(button);
          await frames(tester);
          expect(auth.returns, ['/v1/chats']);
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale $width final action',
          );
        }
      }
    },
  );

  test('CREDITS.md exists and lists the image sources', () {
    final credits = File(
      'lib/presentation/frontend/assets/CREDITS.md',
    ).readAsStringSync();
    expect(credits, contains('No image was downloaded'));
  });
}
