import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'dart:convert';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/chat_list_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_list.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_screen.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const a = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e01';
const b = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e02';
const c = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e03';
final now = DateTime.utc(2026, 11, 10, 12);

/// Chat list double: the API order is pinned first, then recent.
class Api {
  final requests = <(String, String, String)>[];
  int deleteFailures = 0;
  List<Map<String, dynamic>> chats = [
    {
      'session_id': a,
      'title': 'Zeta pinned',
      'is_pinned': true,
      'updated_at': '2026-11-08T12:00:00Z',
    },
    {
      'session_id': b,
      'title': 'Beta recent',
      'is_pinned': false,
      'updated_at': '2026-11-10T11:58:00Z',
    },
    {
      'session_id': c,
      'title': 'Alpha old',
      'is_pinned': false,
      'updated_at': '2026-11-10T09:00:00Z',
    },
  ];

  late final client = MockClient((request) async {
    final path = request.url.path.replaceFirst('/apps/cortex/v1', '');
    requests.add((
      request.method,
      '$path${request.url.hasQuery ? '?${request.url.query}' : ''}',
      request.body,
    ));
    http.Response json(Object data, [int status = 200]) => http.Response(
      jsonEncode(data),
      status,
      headers: {'content-type': 'application/json'},
    );
    if (path == '/chats' && request.method == 'GET') {
      final running = request.url.queryParameters['status'] == 'running';
      return json({
        'message': '',
        'data': running
            ? chats.where((x) => x['session_id'] == b).toList()
            : chats,
      });
    }
    if (path == '/models') {
      return json({
        'message': '',
        'data': {
          'max_input_tokens': 5120,
          'estimate_rule': {
            'unit': 'utf8_bytes',
            'bytes_per_token': 3,
            'copies': 2,
          },
        },
      });
    }
    if (path == '/personas') return json({'message': '', 'data': []});
    final id = path.split('/').last;
    if (request.method == 'PATCH') {
      final change = (jsonDecode(request.body) as Map).cast<String, dynamic>();
      chats.firstWhere((x) => x['session_id'] == id).addAll(change);
      return json({
        'message': 'ok',
        'data': {'session_id': id},
      });
    }
    if (request.method == 'DELETE') {
      if (deleteFailures > 0) {
        deleteFailures--;
        return json({
          'message': 'Database is busy.',
          'data': {'error_number': 1501},
        }, 503);
      }
      chats.removeWhere((x) => x['session_id'] == id);
      return json({'message': 'Chat deleted', 'data': {}});
    }
    return json({'message': 'no route', 'data': {}}, 404);
  });

  CortexApi get cortex =>
      CortexApi(baseUrl: 'https://api.test/apps/cortex/v1', client: client);
}

Widget app(Widget body) => MaterialApp(
  theme: cortexTheme(Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: body),
);

Future<Api> pumpList(WidgetTester tester, [Api? double]) async {
  final api = double ?? Api();
  await tester.pumpWidget(
    app(
      SizedBox(
        width: 280,
        child: ChatList(
          controller: ChatListController(api: api.cortex),
          location: '/v1/chats',
          now: () => now,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

List<String> titles(WidgetTester tester) => [
  for (final t in tester.widgetList<ListTile>(find.byType(ListTile)))
    (t.title as Text).data!,
];

Future<void> menu(WidgetTester tester, String id, String item) async {
  await tester.tap(find.byKey(Key('menu-$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'rows keep the API order with relative time and the running dot',
    (tester) async {
      await pumpList(tester);
      // Not sorted by title or time in the UI (31.1).
      expect(titles(tester), ['Zeta pinned', 'Beta recent', 'Alpha old']);
      expect(find.text('2 d ago'), findsOneWidget);
      expect(find.text('2 min ago'), findsOneWidget);
      expect(find.text('3 h ago'), findsOneWidget);
      expect(find.byKey(const Key('running-$b')), findsOneWidget);
      expect(find.byKey(const Key('running-$a')), findsNothing);
      expect(find.byIcon(AppIcons.pinSelected), findsOneWidget);
    },
  );

  testWidgets('empty list shows the empty state', (tester) async {
    await pumpList(tester, Api()..chats = []);
    expect(find.text('No chats yet'), findsOneWidget);
  });

  testWidgets('rename and pin go to the API and the list reloads', (
    tester,
  ) async {
    final api = await pumpList(tester);
    await menu(tester, c, 'Rename');
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      api.requests,
      contains(('PATCH', '/chats/$c', '{"title":"Renamed"}')),
    );
    expect(titles(tester).last, 'Renamed');
    await menu(tester, b, 'Pin');
    expect(
      api.requests,
      contains(('PATCH', '/chats/$b', '{"is_pinned":true}')),
    );
    await menu(tester, a, 'Unpin');
    expect(
      api.requests,
      contains(('PATCH', '/chats/$a', '{"is_pinned":false}')),
    );
  });

  testWidgets(
    'delete asks first; an error keeps the chat and Retry deletes it',
    (tester) async {
      final api = await pumpList(tester, Api()..deleteFailures = 1);
      await menu(tester, c, 'Delete');
      expect(find.text('Delete this chat?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Something went wrong (1501).'),
        findsOneWidget,
      );
      expect(titles(tester), contains('Alpha old'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(api.requests.where((r) => r.$1 == 'DELETE').length, 2);
      expect(titles(tester), isNot(contains('Alpha old')));
    },
  );

  testWidgets('temporary chat: fixed banner, a reload opens a new empty one', (
    tester,
  ) async {
    final api = Api();
    Widget screen() => app(
      ChatScreen(
        key: UniqueKey(),
        api: api.cortex,
        details: DetailsController(),
        temporary: true,
      ),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('temporary-banner')), findsOneWidget);
    expect(
      find.text('Temporary: not saved, lost when you refresh.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('rename')), findsNothing);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('messages')), findsNothing);
    expect(find.byKey(const Key('temporary-banner')), findsOneWidget);
    // A temporary chat never asks for a saved page.
    expect(api.requests.where((r) => r.$2.startsWith('/chats/')), isEmpty);
  });
}
