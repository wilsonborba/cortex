import 'dart:convert';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/output_block.dart';
import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/widgets/common/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'chat_test.dart' as fixture;

Map<String, dynamic> page(int start, {bool running = false}) => {
  'chat': {'session_id': fixture.sid, 'title': 'Synthetic history'},
  'inputs': [
    for (var i = start + 19; i >= start; i--)
      {
        'input_id': 'i-$i',
        'text': 'Question $i',
        'created_at': '2026-11-12T12:00:00Z',
      },
  ],
  'outputs': [
    for (var i = start; i < start + 20; i++)
      {
        'input_id': 'i-$i',
        'output_id': i == start + 19 ? fixture.oid : 'o-$i',
        'status': running && i == start + 19 ? 'running' : 'done',
        'text': 'Answer $i with a short synthetic paragraph.',
      },
  ],
};
Widget outputApp(OutputView output) => MaterialApp(
  theme: cortexTheme(Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: OutputBlock(output: output, onRetry: () {}),
    ),
  ),
);
void main() {
  testWidgets('terminal run error in a running SQL row is shown as terminal', (
    tester,
  ) async {
    final api = fixture.Api()
      ..page = {
        'chat': {'session_id': fixture.sid, 'title': 'Synthetic saved chat'},
        'inputs': [
          {'input_id': 'i-save-error', 'text': 'Synthetic failed save'},
        ],
        'outputs': [
          {
            'input_id': 'i-save-error',
            'output_id': 'o-save-error',
            'session_id': fixture.sid,
            'status': 'running',
            'created_at': '2026-11-01T03:04:05Z',
            'text': 'Synthetic partial answer',
            'run': {'total_ms': 25, 'error_number': 1017},
          },
        ],
      };
    final (chat, _) = await fixture.pump(
      tester,
      session: fixture.sid,
      api: api,
    );
    await tester.pumpAndSettle();
    final output = chat.exchanges.single.output;
    expect(output.status, 'running');
    expect(output.errorNumber, 1017);
    expect(output.totalMs, 25);
    expect(output.started, DateTime.utc(2026, 11, 1, 3, 4, 5));
    expect(chat.running, isNull);
    expect(find.byKey(const Key('output-error')), findsOneWidget);
    expect(find.byTooltip('Retry'), findsOneWidget);
    expect(find.byKey(const Key('status-line')), findsNothing);
    final stats = tester.widget<Text>(find.byKey(const Key('stats-line')));
    expect(stats.data, contains('0.0 s')); // 25 ms at one decimal place
    final time = TimeOfDay.fromDateTime(
      output.started!.toLocal(),
    ).format(tester.element(find.byKey(const Key('stats-line'))));
    expect(stats.data, contains(time));
    chat.dispose();
  });

  testWidgets('history controller restores a blocked run without retry', (
    tester,
  ) async {
    final api = fixture.Api()
      ..page = {
        'chat': {'session_id': fixture.sid, 'title': 'Synthetic saved chat'},
        'inputs': [
          {'input_id': 'i-block', 'text': 'Synthetic blocked request'},
        ],
        'outputs': [
          {
            'input_id': 'i-block',
            'output_id': 'o-block',
            'session_id': fixture.sid,
            'status': 'failed',
            'text': '',
            'run': {'total_ms': 25, 'error_number': securityBlock},
          },
        ],
      };
    final (chat, _) = await fixture.pump(
      tester,
      session: fixture.sid,
      api: api,
    );
    await tester.pumpAndSettle();
    final output = chat.exchanges.single.output;
    expect(output.status, 'failed');
    expect(output.errorNumber, securityBlock);
    expect(output.totalMs, 25);
    expect(find.byIcon(AppIcons.securityBlock), findsOneWidget);
    expect(find.byTooltip('Retry'), findsNothing);
    chat.dispose();
  });

  testWidgets('history ordinary failure retains its retry action', (
    tester,
  ) async {
    final api = fixture.Api()
      ..page = {
        'chat': {'session_id': fixture.sid, 'title': 'Synthetic saved chat'},
        'inputs': [
          {'input_id': 'i-failed', 'text': 'Synthetic failed request'},
        ],
        'outputs': [
          {
            'input_id': 'i-failed',
            'output_id': 'o-failed',
            'session_id': fixture.sid,
            'status': 'failed',
            'text': '',
            'run': {'total_ms': 40, 'error_number': 1012},
          },
        ],
      };
    final (chat, _) = await fixture.pump(
      tester,
      session: fixture.sid,
      api: api,
    );
    await tester.pumpAndSettle();
    expect(chat.exchanges.single.output.errorNumber, 1012);
    expect(find.byTooltip('Retry'), findsOneWidget);
    expect(find.byIcon(AppIcons.securityBlock), findsNothing);
    chat.dispose();
  });

  testWidgets('three older pages keep a known exchange at the same position', (
    tester,
  ) async {
    final api = fixture.Api()..page = page(60);
    final (chat, _) = await fixture.pump(
      tester,
      session: fixture.sid,
      api: api,
    );
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('messages')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    scroll.jumpTo(scroll.maxScrollExtent - 100);
    await tester.pump();
    final known = find.byKey(const ValueKey('exchange-i-78'));
    final top = tester.getTopLeft(known).dy;
    final offset = scroll.pixels;
    for (final start in [40, 20, 0]) {
      api.page = page(start);
      await chat.loadOlder();
      await tester.pumpAndSettle();
      expect(scroll.pixels, closeTo(offset, .01));
      expect(tester.getTopLeft(known).dy, closeTo(top, .01));
    }
    expect(find.byType(SliverList, skipOffstage: false), findsNWidgets(2));
    await fixture.stopReconnecting(tester, chat);
  });
  testWidgets('streaming does not move the viewport while reading older text', (
    tester,
  ) async {
    final api = fixture.Api()
      ..page = page(60, running: true)
      ..keepOpen = true;
    api.streamFor = (_) => fixture.stream(done: false);
    final (chat, _) = await fixture.pump(
      tester,
      session: fixture.sid,
      api: api,
    );
    await tester.pump(const Duration(milliseconds: 100));
    final scroll = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('messages')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    scroll.jumpTo(scroll.maxScrollExtent - 200);
    await tester.pump();
    final offset = scroll.pixels;
    api.open.add(
      utf8.encode(
        fixture.sse(100, 'token', {'text': ' Additional streamed text.' * 20}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(scroll.pixels, offset);
    expect(find.byKey(const Key('jump-latest')), findsOneWidget);
    await fixture.stopReconnecting(tester, chat);
  });
  testWidgets('clipboard rejection shows an error and never says copied', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'synthetic-rejection');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final output = OutputView(status: 'done')
      ..answer.write('Raw **synthetic answer**');
    await tester.pumpWidget(outputApp(output));
    await tester.tap(find.byTooltip('Copy'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not copy. Select the text and try again.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Copied'), findsNothing);
  });
  testWidgets('wait states follow the Fluent thresholds (#63)', (tester) async {
    final start = DateTime(2030, 1, 1, 12);
    var now = start;
    final output = OutputView()
      ..started = start
      ..step = 'web.search';
    Widget app() => MaterialApp(
      theme: cortexTheme(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OutputBlock(output: output, now: () => now),
        ),
      ),
    );
    // Under 1 second: no indicator.
    await tester.pumpWidget(app());
    expect(find.byKey(const Key('status-line')), findsNothing);
    expect(find.byType(AppSpinner), findsNothing);
    now = start.add(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('status-line')), findsNothing);
    // From 1 second with no total: a 16 px spinner and the "-ing" label.
    now = start.add(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(AppSpinner), findsOneWidget);
    expect(find.textContaining('\u00a0\u2026'), findsOneWidget);
    expect(find.byType(AppProgressBar), findsNothing);
    // A known total under 3 s: still the spinner.
    output
      ..step = 'web.page.read'
      ..progress = [3, 10];
    await tester.pumpWidget(app());
    expect(find.byType(AppSpinner), findsOneWidget);
    expect(find.byType(AppProgressBar), findsNothing);
    // Longer, with a known total: the 2 px bar, no spinner.
    now = start.add(const Duration(milliseconds: 3500));
    await tester.pumpWidget(app());
    expect(find.byType(AppProgressBar), findsOneWidget);
    expect(find.byType(AppSpinner), findsNothing);
    // Thinking: the pulsing dot, no spinner and no bar.
    output
      ..progress = null
      ..step = null
      ..stages.add(StageState('think', 'started', 0));
    await tester.pumpWidget(app());
    expect(find.byKey(const Key('thinking-dot')), findsOneWidget);
    expect(find.byType(AppSpinner), findsNothing);
    expect(find.byType(AppProgressBar), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('status text length does not change the 24 pixel row', (
    tester,
  ) async {
    for (final model in ['Example', 'Long synthetic model name ' * 20]) {
      final output = OutputView()
        ..step = 'thinking.step'
        ..stepParams = {'role': 'plan', 'model': model}
        ..expectedMs = 30000
        // No indicator in the first second (#63).
        ..started = DateTime.now().subtract(const Duration(seconds: 2));
      await tester.pumpWidget(outputApp(output));
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('status-line'))).height, 24);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  for (final state in ['done', 'cancelled', 'failed', 'blocked']) {
    testWidgets('terminal state $state keeps text and allowed actions', (
      tester,
    ) async {
      final output = OutputView(status: state == 'blocked' ? 'failed' : state)
        ..answer.write('Synthetic partial answer');
      if (state == 'failed') output.errorNumber = 1012;
      if (state == 'blocked') output.errorNumber = securityBlock;
      await tester.pumpWidget(outputApp(output));
      await tester.pumpAndSettle();
      expect(find.textContaining('Synthetic partial answer'), findsOneWidget);
      // The action row has a Retry icon button with a tooltip (#63).
      expect(
        find.byTooltip('Retry'),
        state == 'blocked' ? findsNothing : findsOneWidget,
      );
      expect(find.byKey(const Key('ai-note')), findsOneWidget);
      if (state == 'blocked') {
        expect(find.byIcon(AppIcons.securityBlock), findsOneWidget);
      }
      if (state == 'cancelled') expect(find.text('Stopped'), findsOneWidget);
    });
  }
  testWidgets('timing-only history never displays invented token zeros', (
    tester,
  ) async {
    final output = OutputView.fromHistory({
      'output_id': 'legacy',
      'status': 'done',
      'text': 'Synthetic answer',
      'run': {'total_ms': 1250},
    });
    await tester.pumpWidget(outputApp(output));
    await tester.pumpAndSettle();
    final line = tester.widget<Text>(find.byKey(const Key('stats-line')));
    expect(line.data, contains('1.3 s'));
    expect(line.data, startsWith('Duration:'));
    expect(line.data, isNot(contains('0 in')));
    expect(line.data, isNot(contains('0 out')));
  });
}
