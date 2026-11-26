import 'dart:convert';
import 'api.dart';

int? _historyUnsigned(Object? value) =>
    value is int && value >= 0 ? value : null;
int? _historyErrorNumber(Object? value) =>
    value is int && value >= 0 && value <= 65535 ? value : null;
DateTime? _historyTimestamp(Object? value) {
  if (value is! String || !RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    return null;
  }
  return DateTime.tryParse(value);
}

class StageState {
  StageState(this.name, this.status, this.timeMs);
  final String name;
  String status;
  int timeMs;
}

class ThinkingPart {
  ThinkingPart(this.role, this.round, this.text);
  final String role;
  final int round;
  String text;
}

/// One output, built from the stream events (area 10) or from the history.
class OutputView {
  OutputView({this.outputId, this.status = 'running'})
    : started = DateTime.now();
  String? outputId;
  String? sessionId;
  String status;
  final stages = <StageState>[];
  String? step;
  Map<String, dynamic> stepParams = const {};
  List<int>? progress;
  int? expectedMs;
  final thinking = <ThinkingPart>[];
  final answer = StringBuffer();
  final sources = <(String title, String url)>[];
  final memories = <(String id, String title)>[];
  final notices = <(int number, String message)>[];
  int? errorNumber;
  String? errorMessage;
  int? inputTokens, outputTokens, totalTokens, totalMs;
  int lastEventId = 0;
  DateTime? started;

  /// Set when this answer continues a saved answer (cortex#82).
  ContinueSource? continuedFrom;

  bool get running => status == 'running' && errorNumber == null;
  bool get thinkingRuns =>
      running && stages.any((s) => s.name == 'think' && s.status == 'started');

  factory OutputView.fromHistory(Map<String, dynamic> o) {
    final view =
        OutputView(
            outputId: o['output_id'] as String?,
            status: '${o['status']}',
          )
          ..sessionId = o['session_id'] as String?
          ..started = _historyTimestamp(o['created_at']);
    final run = o['run'];
    if (run is Map) {
      view
        ..totalMs = _historyUnsigned(run['total_ms'])
        ..errorNumber = view.status == 'failed' || view.status == 'running'
            ? _historyErrorNumber(run['error_number'])
            : null;
      final tokens = run['tokens'];
      if (tokens is Map) {
        view
          ..inputTokens = _historyUnsigned(tokens['input'])
          ..outputTokens = _historyUnsigned(tokens['output'])
          ..totalTokens = _historyUnsigned(tokens['total']);
      }
    }
    view.answer.write(o['text'] ?? '');
    final thinking = o['thinking_text'] as String?;
    if (thinking != null && thinking.isNotEmpty) {
      view.thinking.add(ThinkingPart('notes', 1, thinking));
    }
    for (final s in (o['sources'] as List? ?? const [])) {
      view.sources.add(('${s['title']}', '${s['url']}'));
    }
    for (final m in (o['memories'] as List? ?? const [])) {
      view.memories.add(('${m['id']}', '${m['title']}'));
    }
    final from = o['continued_from'];
    if (from is Map) {
      view.continuedFrom = ContinueSource.fromHistory(
        from.cast<String, dynamic>(),
        view.answer.toString(),
      );
    }
    return view;
  }

  /// Applies one event. Returns true when the output reached its end.
  bool apply(ChatEvent e) {
    if (e.id <= lastEventId) {
      return false; // replayed duplicate after a reconnect
    }
    lastEventId = e.id;
    final d = e.data;
    switch (e.name) {
      case 'stage':
        final name = '${d['stage']}';
        final status = '${d['status']}';
        final current = stages.where((s) => s.name == name).firstOrNull;
        if (current == null) {
          stages.add(
            StageState(name, status, (d['time_ms'] as num?)?.toInt() ?? 0),
          );
        } else {
          current
            ..status = status
            ..timeMs = (d['time_ms'] as num?)?.toInt() ?? current.timeMs;
        }
        if (d.containsKey('expected_ms') && d['expected_ms'] != null) {
          expectedMs = (d['expected_ms'] as num).toInt();
        }
      case 'step':
        step = '${d['step']}';
        stepParams = ((d['params'] as Map?) ?? const {}).cast();
        progress = (d['progress'] as List?)
            ?.map((v) => (v as num).toInt())
            .toList();
      case 'sources':
        sources
          ..clear()
          ..addAll([
            for (final s in (d['sources'] as List? ?? const []))
              ('${s['title']}', '${s['url']}'),
          ]);
      case 'memories':
        memories
          ..clear()
          ..addAll([
            for (final m in (d['memories'] as List? ?? const []))
              ('${m['id']}', '${m['title']}'),
          ]);
      case 'thinking':
        final role = '${d['role']}';
        final round = (d['round'] as num?)?.toInt() ?? 1;
        final last = thinking.lastOrNull;
        if (last != null && last.role == role && last.round == round) {
          last.text += '${d['text']}';
        } else {
          thinking.add(ThinkingPart(role, round, '${d['text']}'));
        }
      case 'token':
        answer.write(d['text'] ?? '');
      case 'notice':
        notices.add(((d['notice_number'] as num).toInt(), e.message));
      case 'error':
        errorNumber = (d['error_number'] as num?)?.toInt();
        errorMessage = e.message;
        status = 'failed';
        return true;
      case 'done':
        outputId ??= d['output_id'] as String?;
        sessionId ??= d['session_id'] as String?;
        final tokens = (d['tokens'] as Map?) ?? const {};
        inputTokens = (tokens['input'] as num?)?.toInt();
        outputTokens = (tokens['output'] as num?)?.toInt();
        totalTokens = (tokens['total'] as num?)?.toInt();
        totalMs = (d['total_ms'] as num?)?.toInt();
        status = stages.any((s) => s.status == 'cancelled')
            ? 'cancelled'
            : 'done';
        return true;
    }
    return false;
  }
}

/// The source of a continued answer (cortex#82): the saved answer, the token
/// position and the 1-based rank of the recorded alternative.
class ContinueSource {
  const ContinueSource({
    required this.outputId,
    required this.tokenPosition,
    required this.rank,
    required this.word,
  });
  final String outputId;
  final int tokenPosition, rank;

  /// The alternative text that starts the continuation.
  final String word;

  /// History gives the byte where the alternative starts in the new answer;
  /// the caption shows the word that starts there.
  factory ContinueSource.fromHistory(Map<String, dynamic> value, String text) {
    final byte = (value['source_byte'] as num?)?.toInt() ?? 0;
    final bytes = utf8.encode(text);
    var word = '';
    if (byte >= 0 && byte < bytes.length) {
      final rest = utf8.decode(bytes.sublist(byte), allowMalformed: true);
      word = RegExp(r'^\s*\S+').firstMatch(rest)?.group(0)?.trim() ?? '';
    }
    return ContinueSource(
      outputId: '${value['output_id']}',
      tokenPosition: (value['token_position'] as num).toInt(),
      rank: (value['alternative_rank'] as num).toInt(),
      word: word,
    );
  }
}
