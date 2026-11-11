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
import '../personas/persona_test.dart' as personas;
import 'components_golden_test.dart' show loadFonts;

// All content comes from local synthetic doubles. No live API is used.
http.Client fixtureClient() {
  final person = personas.Api();
  return MockClient((request) async {
    final path = request.url.path.replaceFirst('/apps/cortex/v1', '');
    http.Response reply(Object data) => http.Response(
      jsonEncode({'data': data, 'message': ''}),
      200,
      headers: {'content-type': 'application/json'},
    );
    if (path.startsWith('/personas')) {
      final copy = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes;
      return person.client.send(copy).then(http.Response.fromStream);
    }
    if (path == '/chats') {
      return reply([
        {
          'session_id': chat.sid,
          'title': 'Design review example',
          'updated_at': '2026-11-12T12:00:00Z',
        },
      ]);
    }
    if (path == '/models') {
      return reply({
        'max_input_tokens': 5120,
        'estimate_rule': {
          'unit': 'utf8_bytes',
          'bytes_per_token': 3,
          'copies': 2,
        },
      });
    }
    if (path == '/chats/${chat.sid}') {
      return reply({
        'chat': {'session_id': chat.sid, 'title': 'Design review example'},
        'inputs': [
          {
            'input_id': 'synthetic-input',
            'text': 'Help me plan a short reading session.',
            'created_at': '2026-11-12T12:00:00Z',
          },
        ],
        'outputs': [
          {
            'input_id': 'synthetic-input',
            'output_id': chat.oid,
            'status': 'done',
            'text':
                '## A simple reading plan\n\nChoose one topic and keep a short note of the main idea.\n\n1. Read one section.\n2. Write a brief summary.\n3. Review your notes.\n\n[Example reference](https://example.com)',
          },
        ],
      });
    }
    if (path.startsWith('/memory-graph')) {
      final value = memory.graph(
        focus: path.contains('/nodes/') ? memory.memoryId : null,
      );
      final nodes = value['nodes'] as List;
      for (final node in nodes) {
        if (node['node_type'] == 'entity') node['label'] = 'Example reader';
      }
      return reply(value);
    }
    throw StateError('Unexpected synthetic request: $path');
  });
}

void main() {
  setUpAll(loadFonts);
  const screens = {
    'chat': '/v1/chats/${chat.sid}',
    'memory': '/v1/memory/memory-one',
    'personas': '/v1/personas',
    'persona_form': '/v1/personas/p1',
    'product': '/v1/home',
    'process': '/v1/home/how-it-works',
    'public_memory': '/v1/home/memory',

    'faq': '/v1/home/faq',
  };
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 768.0, 1024.0, 1300.0, 1440.0]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} ${brightness.name} ${width.toInt()}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final session = SessionController(
            service: SessionService(cookieReader: () => 'synthetic-session'),
          );
          await session.refresh();
          final api = CortexApi(
            baseUrl: 'https://api.test/apps/cortex/v1',
            client: fixtureClient(),
          );
          final router = buildRouter(
            session: session,
            auth: memory.Auth(),
            api: api,
            emailLoader: () async => 'reader@example.test',
            initialLocation: entry.value,
          );
          final preferences = Preferences();
          await tester.pumpWidget(
            PreferencesScope(
              preferences: preferences,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: cortexTheme(brightness),
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // The existing public example uses unseeded force positions.
          // Capture its evidence on update, but do not assert random coordinates.
          // Issue 55 replaces this renderer with the aligned custom canvas.
          if ((width == 390 || width == 1300) &&
              (entry.key != 'public_memory' || autoUpdateGoldenFiles)) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/foundation_${entry.key}_${brightness.name}_${width.toInt()}.png',
              ),
            );
          }
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          session.dispose();
          preferences.dispose();
        });
      }
    }
  }
}
