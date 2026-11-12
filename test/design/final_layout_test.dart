import 'dart:convert';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../chat/chat_test.dart' as chat;
import '../memory/memory_test.dart' as memory;
import '../usage/usage_test.dart' as usage;
import 'foundation_screens_test.dart' show fixtureClient;

http.Client stressClient() {
  final base = fixtureClient(), telemetry = usage.Api();
  return MockClient((request) async {
    final path = request.url.path.replaceFirst('/apps/cortex/v1', '');
    http.Response reply(Object data) => http.Response(
      jsonEncode({'data': data, 'message': ''}),
      200,
      headers: {'content-type': 'application/json'},
    );
    if (path == '/chats') {
      return reply([
        for (var i = 0; i < 200; i++)
          {
            'session_id': i == 0
                ? chat.sid
                : '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
            'title': List.filled(12, 'Synthetic long chat title').join(' '),
            'updated_at': '2030-01-01T12:00:00Z',
          },
      ]);
    }
    if (path == '/chats/${chat.sid}') {
      return reply({
        'chat': {
          'session_id': chat.sid,
          'title': List.filled(20, 'Long synthetic title').join(' '),
        },
        'inputs': [
          {
            'input_id': 'synthetic-input',
            'text': List.filled(40, 'Synthetic user message').join(' '),
            'created_at': '2030-01-01T12:00:00Z',
          },
        ],
        'outputs': [
          {
            'input_id': 'synthetic-input',
            'output_id': chat.oid,
            'status': 'done',
            'text':
                '## Synthetic answer\n\n${List.filled(12, 'Readable example paragraph.\n\n').join()}\n```text\n${List.filled(100, 'long_code_token').join('_')}\n```',
          },
        ],
      });
    }
    if (path.startsWith('/memory-graph')) {
      final data = memory.graph(
        focus: path.contains('/nodes/') ? memory.memoryId : null,
      );
      final nodes = data['nodes'] as List;
      (nodes.first as Map)['metadata']['title'] = List.filled(
        15,
        'Long synthetic memory title',
      ).join(' ');
      (nodes.first as Map)['metadata']['summary'] = List.filled(
        60,
        'Synthetic summary sentence.',
      ).join(' ');
      (nodes[2] as Map)['label'] = 'Synthetic reader';
      for (var i = nodes.length; i < 200; i++) {
        nodes.add({
          'id': 'synthetic-note-$i',
          'node_type': 'memory',
          'label': 'Synthetic note $i',
          'metadata': {'created_at': '2030-01-01T12:00:00Z'},
        });
      }
      return reply(data);
    }
    final copy = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes;
    if (path.startsWith('/telemetry/')) {
      return telemetry.client.send(copy).then(http.Response.fromStream);
    }
    return base.send(copy).then(http.Response.fromStream);
  });
}

void main() {
  const routes = [
    '/v1/chats',
    '/v1/chats/${chat.sid}',
    '/v1/chats/temporary',
    '/v1/memory',
    '/v1/memory/${memory.memoryId}',
    '/v1/personas',
    '/v1/personas/new',
    '/v1/personas/p1',
    '/v1/settings',
    '/v1/usage',
    '/v1/usage/timing',
    '/v1/usage/stats',
    '/v1/usage/events',
  ];
  for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'all signed-in layouts with long data $width ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final session = SessionController(
            service: SessionService(cookieReader: () => 'synthetic-session'),
          );
          await session.refresh();
          final prefs = Preferences();
          final router = buildRouter(
            session: session,
            auth: memory.Auth(),
            api: CortexApi(
              baseUrl: 'https://api.test/apps/cortex/v1',
              client: stressClient(),
            ),
            emailLoader: () async =>
                'synthetic.very.long.account.label.for.layout.review@example.test',
          );
          await tester.pumpWidget(
            PreferencesScope(
              preferences: prefs,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: cortexTheme(brightness),
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
              ),
            ),
          );
          for (final route in routes) {
            router.go(route);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: route);
          }
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          session.dispose();
          prefs.dispose();
        },
      );
    }
  }
  for (final locale in [
    const Locale('en'),
    const Locale('pt', 'BR'),
    const Locale('th'),
  ]) {
    for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('work text at 200 percent ${locale.toLanguageTag()} $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final session = SessionController(
          service: SessionService(cookieReader: () => 'synthetic-session'),
        );
        await session.refresh();
        final prefs = Preferences();
        final router = buildRouter(
          session: session,
          auth: memory.Auth(),
          api: CortexApi(
            baseUrl: 'https://api.test/apps/cortex/v1',
            client: stressClient(),
          ),
          emailLoader: () async =>
              'synthetic.long.account.for.text.scale.review@example.test',
        );
        await tester.pumpWidget(
          PreferencesScope(
            preferences: prefs,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: cortexTheme(Brightness.dark),
              locale: locale,
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        for (final route in [
          '/v1/chats',
          '/v1/settings',
          '/v1/memory/${memory.memoryId}',
        ]) {
          router.go(route);
          await tester.pumpAndSettle();
          if (route == '/v1/chats') {
            await tester.enterText(
              find.byKey(const Key('composer-text')),
              List.filled(12, 'Synthetic draft text').join(' '),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull, reason: route);
        }
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        session.dispose();
        prefs.dispose();
      });
    }
  }
}
