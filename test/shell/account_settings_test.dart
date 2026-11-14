import 'dart:convert';
import 'package:cortex/dal/local/ui_preferences.dart';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeAuth extends AuthService {
  FakeAuth() : super(AuthApiAdapter());
  @override
  Future<void> signIn({String? returnPath}) async {}
}

class Store extends UiPreferenceStore {
  final values = <String, String>{};
  bool unavailable = false;
  @override
  String? read(String key) {
    if (unavailable) throw StateError('Unavailable test storage');
    return values[key];
  }

  @override
  void write(String key, String value) {
    if (unavailable) throw StateError('Unavailable test storage');
    values[key] = value;
  }
}

Future<(GoRouter, Preferences)> show(
  WidgetTester tester,
  double width, {
  String? email,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final preferences = Preferences(store: Store());
  final session = SessionController(
    service: SessionService(
      cookieReader: () => signedIn ? 'synthetic-session' : null,
    ),
  );
  await session.refresh();
  final router = buildRouter(
    session: session,
    auth: FakeAuth(),
    emailLoader: () async => email,
    initialLocation: '/v1/chats',
    screen: (_, _) => const Text('Synthetic screen'),
  );
  await tester.pumpWidget(
    PreferencesScope(
      preferences: preferences,
      child: ListenableBuilder(
        listenable: preferences,
        builder: (_, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          locale: preferences.locale,
          theme: cortexTheme(
            preferences.theme == ThemeMode.light
                ? Brightness.light
                : Brightness.dark,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  // The sign in page spinner repeats: pump frames there instead of settling.
  if (signedIn) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
  addTearDown(router.dispose);
  addTearDown(session.dispose);
  addTearDown(preferences.dispose);
  return (router, preferences);
}

void main() {
  test(
    'preferences survive reload and handle corrupt or unavailable storage',
    () {
      final store = Store();
      final first = Preferences(store: store)
        ..theme = ThemeMode.dark
        ..locale = const Locale('pt', 'BR')
        ..collapsed = true;
      final second = Preferences(store: store);
      expect(second.theme, ThemeMode.dark);
      expect(second.locale, const Locale('pt', 'BR'));
      expect(second.collapsed, isTrue);
      store.values['cortex.ui.theme'] = 'invalid';
      store.values['cortex.ui.locale'] = 'invalid';
      final corrupt = Preferences(store: store);
      expect(corrupt.theme, ThemeMode.system);
      expect(corrupt.locale, isNull);
      store.unavailable = true;
      final blocked = Preferences(store: store)..theme = ThemeMode.light;
      expect(blocked.locale, isNull);
      for (final prefs in [first, second, corrupt, blocked]) {
        prefs.dispose();
      }
    },
  );
  test(
    'gateway adapter reads email only and handles failed requests',
    () async {
      final adapter = AuthApiAdapter(
        apiForAppsBaseUrl: 'https://gateway.test',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/user/info/v1/');
          return http.Response(
            jsonEncode({
              'data': {
                'email': 'reader@example.test',
                'full_name': 'Synthetic ignored value',
              },
            }),
            200,
          );
        }),
      );
      expect(await adapter.currentEmail(), 'reader@example.test');
      final failed = AuthApiAdapter(
        httpClient: MockClient((_) async => http.Response('{}', 503)),
      );
      expect(await failed.currentEmail(), isNull);
    },
  );
  for (final width in [390.0, 800.0, 1300.0]) {
    testWidgets('account footer and long email at $width', (tester) async {
      await show(
        tester,
        width,
        email: 'synthetic.long.account.for.layout.review@example.test',
      );
      if (width < 600) {
        await tester.tap(find.byKey(const Key('drawer-button')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('account-button')), findsOneWidget);
      // The sidebar row shows the email; the rail shows it in the menu.
      final rail = width >= 600 && width <= 1000;
      expect(
        find.byKey(const Key('account-email')),
        rail ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('account-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-email')), findsOneWidget);
      expect(find.byKey(const Key('theme-switch')), findsOneWidget);
      expect(find.byKey(const Key('language-switch')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('theme-switch')), findsNothing);
      expect(
        find.byKey(const Key('account-email')),
        rail ? findsNothing : findsOneWidget,
      );
    });
  }
  testWidgets('account fallback, live preferences, settings and browser Back', (
    tester,
  ) async {
    final (router, preferences) = await show(tester, 1300);
    expect(find.text('Account'), findsOneWidget);
    final trigger = tester.widget<TextButton>(
      find.byKey(const Key('account-button')),
    );
    trigger.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Light'));
    await tester.pumpAndSettle();
    expect(preferences.theme, ThemeMode.light);
    // The switches keep the menu open; the language switch sets the locale.
    expect(find.byKey(const Key('theme-switch')), findsOneWidget);
    await tester.tap(find.text('PT'));
    await tester.pumpAndSettle();
    expect(preferences.locale, const Locale('pt', 'BR'));
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(preferences.locale, const Locale('en'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(trigger.focusNode!.hasFocus, isTrue);
    router.push('/v1/settings');
    await tester.pumpAndSettle();
    expect(
      find.text('These choices are saved in this browser.'),
      findsOneWidget,
    );
    // No app style back arrow; browser Back returns to the chat.
    expect(find.byType(BackButton), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/v1/chats');
  });
  testWidgets('settings requires an authenticated session', (tester) async {
    final (router, _) = await show(tester, 1300, signedIn: false);
    router.go('/v1/settings');
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routeInformationProvider.value.uri.path, '/v1/login');
  });
}
