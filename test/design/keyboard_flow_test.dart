import 'dart:convert';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/widgets/common/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../chat/chat_test.dart' as chat;
import '../memory/memory_test.dart' as memory;
import '../shell/account_settings_test.dart' show Store;

class _Auth extends AuthService {
  _Auth(this.exit) : super(AuthApiAdapter());
  final Future<void> Function() exit;
  @override
  Future<void> signOut() => exit();
  @override
  Future<void> signIn({String? returnPath}) async {}
}

class _Client extends http.BaseClient {
  _Client(this.chats, this.memories);
  final http.Client chats, memories;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      request.url.path.contains('/memory-graph')
      ? memories.send(request)
      : chats.send(request);
}

bool inside(Element parent, BuildContext? child) {
  if (child == null) return false;
  if (identical(parent, child)) return true;
  var result = false;
  (child as Element).visitAncestorElements((ancestor) {
    if (identical(ancestor, parent)) {
      result = true;
      return false;
    }
    return true;
  });
  return result;
}

Future<void> seek(
  WidgetTester tester,
  Finder target, {
  FocusNode? exact,
  LogicalKeyboardKey direction = LogicalKeyboardKey.tab,
}) async {
  for (var i = 0; i < 100; i++) {
    if (exact != null
        ? identical(FocusManager.instance.primaryFocus, exact)
        : inside(
            tester.element(target),
            FocusManager.instance.primaryFocus?.context,
          )) {
      return;
    }
    await tester.sendKeyEvent(direction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('Keyboard could not reach $target');
}

Future<void> activate(
  WidgetTester tester,
  Finder target, {
  LogicalKeyboardKey direction = LogicalKeyboardKey.tab,
}) async {
  await seek(tester, target, direction: direction);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets(
    'keyboard completes chat, memory and settings flow without pointer input',
    (tester) async {
      tester.view.physicalSize = const Size(1300, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var signed = true, loggedOut = false;
      String? copied;
      final session = SessionController(
        service: SessionService(
          cookieReader: () => signed ? 'synthetic-session' : null,
        ),
      );
      await session.refresh();
      final fake = chat.Api()
        ..keepOpen = true
        ..streamFor = (_) => chat.stream(
          done: false,
          middle: [
            chat.sse(4, 'token', {'text': 'Partial synthetic answer.'}),
          ],
        );
      // The running chat shows a repeating spinner in the sidebar; Reduce
      // Motion makes it static so the keyboard flow can settle.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final prefs = Preferences(store: Store());
      final router = buildRouter(
        session: session,
        auth: _Auth(() async {
          loggedOut = true;
          signed = false;
          await session.refresh();
        }),
        api: CortexApi(
          baseUrl: 'https://api.test/apps/cortex/v1',
          client: _Client(fake.client, memory.Api().client),
        ),
        emailLoader: () async => 'keyboard.reader@example.test',
        initialLocation: '/v1/settings/memory',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await tester.pumpWidget(
        PreferencesScope(
          preferences: prefs,
          child: ListenableBuilder(
            listenable: prefs,
            builder: (context, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: cortexTheme(
                prefs.theme == ThemeMode.light
                    ? Brightness.light
                    : Brightness.dark,
              ),
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await activate(tester, find.widgetWithText(AppButton, 'New chat'));
      await seek(tester, find.byKey(const Key('composer-text')));
      await tester.enterText(
        find.byKey(const Key('composer-text')),
        'Synthetic keyboard question',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('stop')), findsOneWidget);
      await activate(tester, find.byKey(const Key('stop')));
      expect(
        fake.requests.any((r) => r.$1 == 'PATCH' && r.$3.contains('cancel')),
        isTrue,
      );
      fake.page = {
        'chat': {'session_id': chat.sid, 'title': 'Synthetic keyboard chat'},
        'inputs': [
          {
            'input_id': 'i-new',
            'text': 'Synthetic keyboard question',
            'created_at': '2030-01-01T12:00:00Z',
          },
        ],
        'outputs': [
          {
            'input_id': 'i-new',
            'output_id': chat.oid,
            'status': 'cancelled',
            'text': 'Partial synthetic answer.',
          },
        ],
      };
      fake.open.add(
        utf8.encode(
          chat.sse(88, 'stage', {
                'stage': 'answer',
                'status': 'cancelled',
                'time_ms': 1,
              }) +
              chat.sse(90, 'done', {
                'session_id': chat.sid,
                'output_id': chat.oid,
                'tokens': {},
                'total_ms': 10,
              }),
        ),
      );
      await tester.pumpAndSettle();
      await activate(
        tester,
        find.widgetWithIcon(IconButton, AppIcons.copy).last,
      );
      expect(copied, 'Partial synthetic answer.');
      // Memory and theme are in Settings (#62): open it from the account menu.
      await activate(tester, find.byKey(const Key('account-button')));
      await activate(
        tester,
        find.widgetWithText(MenuItemButton, 'Settings'),
        direction: LogicalKeyboardKey.arrowDown,
      );
      await tester.pumpAndSettle();
      await activate(tester, find.byTooltip('Light'));
      await tester.pumpAndSettle();
      expect(prefs.theme, ThemeMode.light);
      await activate(
        tester,
        find.byKey(const Key('settings-tab-/v1/settings/memory')),
        direction: LogicalKeyboardKey.tab,
      );
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/v1/settings/memory',
      );
      // A memory row opens with the keyboard (#65).
      await activate(
        tester,
        find.byKey(const Key('memory-${memory.memoryId}')),
      );
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/v1/settings/memory/${memory.memoryId}',
      );
      await activate(tester, find.byKey(const Key('account-button')));
      await activate(
        tester,
        find.widgetWithText(MenuItemButton, 'Log out'),
        direction: LogicalKeyboardKey.arrowDown,
      );
      expect(loggedOut, isTrue);
      expect(session.signedIn, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      prefs.dispose();
      session.dispose();
      await fake.open.close();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    },
  );
}
