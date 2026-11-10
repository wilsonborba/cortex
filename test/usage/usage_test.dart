import 'dart:async';
import 'dart:convert';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/models/telemetry.dart';
import 'package:cortex/domain/services/usage_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/usage/usage_screen.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class Api {
  final requests = <Uri>[];
  bool admin = false, empty = false;
  int failures = 0;
  Completer<void>? gate;
  late final client = MockClient((request) async {
    requests.add(request.url);
    await gate?.future;
    Object data;
    if (failures > 0) {
      failures--;
      return http.Response(
        jsonEncode({
          'message': 'server detail',
          'data': {'error_number': 1037},
        }),
        503,
      );
    }
    switch (request.url.path.split('/').last) {
      case 'usage':
        data = {
          'window_hours': 24,
          'tokens': {'input': 1234, 'output': 56, 'total': 1290},
          'items': {'images': 2, 'audio': 3},
          'loyalty_weight': {
            'value': 1,
            'age': null,
            'frequency': null,
            'account_days': null,
            'sign_in_days_90': null,
          },
          'formula': '1 + age + frequency',
        };
      case 'timing':
        data = [
          for (final mode in ['fast', 'medium', 'deep'])
            for (final thinking in [false, true])
              {
                'kind': {'web_mode': mode, 'thinking': thinking},
                'expected_ms': thinking ? null : 1250,
              },
        ];
      case 'stats':
        data = empty
            ? []
            : [
                for (final mode in ['deep', 'fast'])
                  {
                    'kind': {'web_mode': mode, 'thinking': false},
                    'total_runs': 4,
                    'avg_latency_ms': 2500,
                    'avg_latency_seconds': 2.5,
                    'avg_input_tokens': 20,
                    'avg_output_tokens': 10,
                    'avg_total_tokens': 30,
                    'success_rate': .75,
                  },
              ];
      default:
        final more = request.url.queryParameters.containsKey('before');
        data = empty
            ? []
            : [
                for (var i = more ? 20 : 0; i < (more ? 21 : 20); i++)
                  {
                    'request_id': 'output:$i',
                    'output_id': 'output',
                    if (admin) 'user_id': 'user-$i',
                    'model': 'local-model',
                    'role': 'answer',
                    'input_tokens': i,
                    'output_tokens': 2,
                    'total_tokens': i + 2,
                    'started_at': '2026-11-10T10:00:00Z',
                    'finished_at': '2026-11-10T10:00:01Z',
                  },
              ];
    }
    return http.Response(
      jsonEncode({'message': '', 'data': data}),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

Future<GoRouter> pump(
  WidgetTester tester,
  Api api,
  UsageView view, {
  Locale locale = const Locale('en'),
  double scale = 1,
  bool settle = true,
}) async {
  tester.view.physicalSize = scale == 1
      ? const Size(1000, 950)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = UsageController(
    api: CortexApi(baseUrl: 'https://api.test', client: api.client),
  );
  final router = GoRouter(
    initialLocation: view == UsageView.usage
        ? '/v1/usage'
        : '/v1/usage/${view.name}',
    routes: [
      for (final tab in UsageView.values)
        GoRoute(
          path: tab == UsageView.usage ? '/v1/usage' : '/v1/usage/${tab.name}',
          builder: (_, _) => Scaffold(
            body: UsageScreen(controller: controller, view: tab),
          ),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: locale,
      theme: cortexTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

void main() {
  testWidgets('usage shows API counters and unavailable loyalty parts', (
    tester,
  ) async {
    final api = Api();
    await pump(tester, api, UsageView.usage);
    expect(find.text('Your usage in the last 24 hours'), findsOneWidget);
    expect(find.text('Input tokens: 1,234'), findsOneWidget);
    expect(find.text('Output tokens: 56'), findsOneWidget);
    expect(find.text('Images: 2'), findsOneWidget);
    expect(find.text('Audio items: 3'), findsOneWidget);
    expect(find.text('Weight: 1'), findsOneWidget);
    expect(find.textContaining('Not available yet'), findsNWidgets(4));
    expect(api.requests.single.path, '/telemetry/usage');
  });
  testWidgets('timing has six API kinds and paths change the selected tab', (
    tester,
  ) async {
    final api = Api();
    final router = await pump(tester, api, UsageView.timing);
    expect(find.text('Fast, thinking off: 1.25 s'), findsOneWidget);
    expect(find.text('Deep, thinking on: Not available yet'), findsOneWidget);
    expect(find.textContaining('thinking off:'), findsNWidgets(3));
    await tester.tap(find.widgetWithText(TextButton, 'Events'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/v1/usage/events');
    expect(api.requests.last.path, '/telemetry/events');
    expect(find.text('User'), findsNothing);
  });
  testWidgets('stats chart keeps API group order and renders each measure', (
    tester,
  ) async {
    await pump(tester, Api(), UsageView.stats);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('1. Deep, thinking off: 4'), findsOneWidget);
    for (final metric in [
      'Average time',
      'Average input tokens',
      'Average output tokens',
      'Average total tokens',
      'Success rate',
    ]) {
      await tester.tap(find.byKey(const Key('stats-metric')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(metric).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('1. Deep, thinking off: 75%'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.duration, Duration.zero);
    expect(chart.data.barGroups.first.barRods.single.toY, 75);
  });
  testWidgets('admin user column and Load more use the server cursor', (
    tester,
  ) async {
    final api = Api()..admin = true;
    await pump(tester, api, UsageView.events);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('user-0'), findsOneWidget);
    final more = find.byKey(const Key('events-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters, {
      'limit': '20',
      'before': 'output:19',
    });

    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 21);
    expect(more, findsNothing);
  });
  testWidgets('loading, failure retry and empty stats retain their states', (
    tester,
  ) async {
    final api = Api()
      ..gate = Completer<void>()
      ..failures = 1;
    await pump(tester, api, UsageView.stats, settle: false);
    expect(find.byType(BarChart), findsNothing);
    api.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Usage could not be loaded.'), findsOneWidget);
    api.empty = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No usage records yet'), findsOneWidget);
  });
  testWidgets('all four views support EN, PT-BR and TH at 200 percent', (
    tester,
  ) async {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      for (final view in UsageView.values) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, Api()..admin = true, view, locale: locale, scale: 2);
        expect(tester.takeException(), isNull, reason: '$locale $view');
        if (view == UsageView.usage) {
          final expected = switch (locale.languageCode) {
            'pt' => 'Seu uso nas últimas 24 horas',
            'th' => 'การใช้งานของคุณใน 24 ชั่วโมงที่ผ่านมา',
            _ => 'Your usage in the last 24 hours',
          };
          expect(find.text(expected), findsOneWidget);
        }
      }
    }
  });
}
