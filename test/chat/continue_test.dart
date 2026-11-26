import 'dart:convert';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/domain/services/answer_inspection_controller.dart';
import 'package:cortex/domain/services/chat_controller.dart';
import 'package:cortex/presentation/frontend/screens/chat/output_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../inspection/answer_inspection_test.dart' as fixture;
import 'chat_test.dart';

void main() {
  test(
    'history restores only returned run evidence, including explicit zero',
    () {
      final missing = OutputView.fromHistory({
        'output_id': 'missing',
        'status': 'done',
        'text': 'answer',
        'continued_from': {
          'output_id': oid,
          'token_position': 1,
          'alternative_rank': 1,
          'source_byte': 0,
        },
      });
      expect(missing.status, 'done');
      expect(missing.totalMs, isNull);
      expect(missing.inputTokens, isNull);
      expect(missing.errorNumber, isNull);
      expect(missing.started, isNull);
      expect(missing.continuedFrom!.outputId, oid);

      final historical = OutputView.fromHistory({
        'output_id': 'dated',
        'status': 'done',
        'text': 'answer',
        'created_at': '2026-11-01T03:04:05Z',
      });
      expect(historical.started, DateTime.utc(2026, 11, 1, 3, 4, 5));

      final malformedTimestamp = OutputView.fromHistory({
        'output_id': 'malformed-date',
        'status': 'done',
        'text': 'answer',
        'created_at': 'not-a-timestamp',
      });
      expect(malformedTimestamp.started, isNull);

      final timingOnly = OutputView.fromHistory({
        'output_id': 'legacy',
        'status': 'done',
        'text': 'answer',
        'run': {'total_ms': 0},
      });
      expect(timingOnly.totalMs, 0);
      expect(timingOnly.inputTokens, isNull);
      expect(timingOnly.outputTokens, isNull);

      final zeroes = OutputView.fromHistory({
        'output_id': 'zero',
        'status': 'done',
        'text': 'answer',
        'run': {
          'total_ms': 0,
          'tokens': {'input': 0, 'output': 0, 'total': 0},
        },
      });
      expect(zeroes.totalMs, 0);
      expect(zeroes.inputTokens, 0);
      expect(zeroes.outputTokens, 0);
      expect(zeroes.totalTokens, 0);

      for (final status in ['done', 'cancelled']) {
        final output = OutputView.fromHistory({
          'output_id': status,
          'status': status,
          'text': '',
          'run': {'total_ms': 9, 'error_number': 1014},
        });
        expect(output.status, status);
        expect(output.errorNumber, isNull);
      }
      final failed = OutputView.fromHistory({
        'output_id': 'failed',
        'status': 'failed',
        'text': '',
        'run': {'total_ms': 12, 'error_number': 1014},
      });
      expect(failed.status, 'failed');
      expect(failed.errorNumber, 1014);

      final terminalRun = OutputView.fromHistory({
        'output_id': 'terminal-save-error',
        'status': 'running',
        'text': 'partial answer',
        'run': {'total_ms': 25, 'error_number': 1017},
      });
      expect(terminalRun.status, 'running');
      expect(terminalRun.running, isFalse);
      expect(terminalRun.errorNumber, 1017);
      expect(terminalRun.totalMs, 25);

      final genuinelyRunning = OutputView.fromHistory({
        'output_id': 'still-running',
        'status': 'running',
        'text': 'partial answer',
        'run': {'total_ms': 25},
      });
      expect(genuinelyRunning.running, isTrue);
      expect(genuinelyRunning.errorNumber, isNull);

      final invalid = OutputView.fromHistory({
        'output_id': 'invalid',
        'status': 'done',
        'text': 'kept',
        'run': {
          'total_ms': 'unknown',
          'created_at': 'yesterday',
          'error_number': 70000,
          'tokens': {'input': -1, 'output': 'missing', 'total': 0},
        },
      });
      expect(invalid.answer.toString(), 'kept');
      expect(invalid.totalMs, isNull);
      expect(invalid.errorNumber, isNull);
      expect(invalid.started, isNull);
      expect(invalid.inputTokens, isNull);
      expect(invalid.outputTokens, isNull);
      expect(invalid.totalTokens, 0);
    },
  );

  test(
    'continue sends only saved ids and repeats the source question',
    () async {
      final fake = Api();
      fake.modelFields = {
        'default_model_id': 'cortex-t0',
        'models': [
          {
            'id': 'cortex-t0',
            'tier': 't0',
            'name': 'Cortex T0',
            'max_input_tokens': 5120,
          },
        ],
      };
      final api = CortexApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: fake.client,
      );
      fake.page = {
        'chat': {
          'session_id': sid,
          'title': 'Saved chat',
          'model_id': 'cortex-t0',
        },
        'inputs': [],
        'outputs': [],
      };
      final chat = ChatController(api: api, sessionId: sid);
      await chat.open();
      final source = Exchange(
        text: 'Synthetic question',
        output: OutputView(outputId: oid, status: 'done')
          ..answer.write('A map.'),
      );
      chat.exchanges.add(source);
      const from = ContinueSource(
        outputId: oid,
        tokenPosition: 1,
        rank: 2,
        word: 'paper',
      );
      await chat.continueFrom(source, from);
      await pumpEventQueue();
      final post = fake.requests.where((r) => r.$1 == 'POST').single;
      expect(post.$2, '/chats/$sid/inputs');
      final body = jsonDecode(post.$3) as Map<String, dynamic>;
      expect(body['continue_from'], {
        'output_id': oid,
        'token_position': 1,
        'alternative_rank': 2,
      });
      expect(body['model_id'], 'cortex-t0');
      expect(body.containsKey('text'), false, reason: 'the server builds text');
      expect(chat.exchanges.last.text, 'Synthetic question');
      expect(chat.exchanges.last.output.continuedFrom, from);
      chat.dispose();
      final temporary = ChatController(
        api: api,
        sessionId: sid,
        temporary: true,
      );
      await temporary.continueFrom(source, from);
      expect(temporary.exchanges, isEmpty);
      temporary.dispose();
    },
  );
  test(
    'legacy catalog continue omits model_id accepted fields reject',
    () async {
      final fake = Api()..rejectLegacyModelId = true;
      fake.page = {
        'chat': {'session_id': sid, 'title': 'Legacy chat'},
        'inputs': [],
        'outputs': [],
      };
      final api = CortexApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: fake.client,
      );
      final chat = ChatController(api: api, sessionId: sid);
      await chat.open();
      expect(chat.modelCatalog!.hasExplicitProfiles, isFalse);
      final source = Exchange(
        text: 'Synthetic question',
        output: OutputView(outputId: oid, status: 'done'),
      );
      chat.exchanges.add(source);
      const from = ContinueSource(
        outputId: oid,
        tokenPosition: 1,
        rank: 2,
        word: 'paper',
      );
      await chat.continueFrom(source, from);
      await pumpEventQueue();
      final post = fake.requests.where((r) => r.$1 == 'POST').single;
      final body = jsonDecode(post.$3) as Map<String, dynamic>;
      expect(post.$2, '/chats/$sid/inputs');
      expect(body.containsKey('model_id'), isFalse);
      expect(body['continue_from'], {
        'output_id': oid,
        'token_position': 1,
        'alternative_rank': 2,
      });
      expect(chat.exchanges.last.output.errorNumber, isNull);
      chat.dispose();
    },
  );
  test('history gives the continued word from the source byte', () {
    final view = OutputView.fromHistory({
      'output_id': 'new',
      'status': 'done',
      'text': 'Mira found a paper beneath the trees.',
      'continued_from': {
        'output_id': oid,
        'token_position': 3,
        'alternative_rank': 2,
        'source_byte': 12,
      },
    });
    expect(view.continuedFrom!.outputId, oid);
    expect(view.continuedFrom!.word, 'paper');
    expect(view.continuedFrom!.rank, 2);
  });
  testWidgets('radar continue sends the token position and the rank', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final text = fixture.sampleText('en');
    final output = fixture.doneOutput(text);
    ContinueSource? sent;
    late AnswerInspectionController inspection;
    await tester.pumpWidget(
      fixture.app(
        fixture.column(
          (gutter) => OutputBlock(
            output: output,
            gutter: gutter,
            inspect: () => inspection = AnswerInspectionController(
              text: text,
              initialData: fixture.fixtureData(text),
            ),
            onContinue: (from) => sent = from,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('inspect-answer')));
    await tester.pumpAndSettle();
    inspection.nextFork();
    inspection.select(1);
    await tester.pumpAndSettle();
    final span = inspection.current!;
    await tester.tap(find.byKey(const Key('radar-continue')));
    await tester.pumpAndSettle();
    expect(sent!.outputId, 'output');
    expect(sent!.tokenPosition, span.tokenIndex);
    expect(sent!.rank, span.options[1].rank);
    expect(sent!.word, span.options[1].text.trim());
    expect(find.byKey(const Key('answer-inspection')), findsNothing);
    expect(output.answer.toString(), text);
  });
  testWidgets('a continued answer shows its source caption', (tester) async {
    var shown = 0;
    final output = fixture.doneOutput('Mira found a paper.')
      ..continuedFrom = const ContinueSource(
        outputId: oid,
        tokenPosition: 3,
        rank: 2,
        word: 'paper',
      );
    await tester.pumpWidget(
      fixture.app(
        fixture.column(
          (gutter) => OutputBlock(
            output: output,
            gutter: gutter,
            onSource: () => shown++,
          ),
        ),
        language: 'pt',
      ),
    );
    expect(find.text('Continuação a partir de “paper”'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continued-from')));
    expect(shown, 1);
  });
}
