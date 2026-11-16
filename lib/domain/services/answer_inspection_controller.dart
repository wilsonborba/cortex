import 'dart:convert';
import 'dart:math' as math;
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import '../models/answer_inspection.dart';

/// In-place inspection of one saved answer (cortex#77, cortex#78).
///
/// Read-only: it never changes the saved text and never calls a model. All
/// values come from the saved token log probabilities and alternatives.
class AnswerInspectionController extends ChangeNotifier {
  AnswerInspectionController({
    required this.text,
    this.loader,
    AnswerInspectionData? initialData,
  }) {
    _apply(initialData ?? const AnswerInspectionData());
    cursor = spans.isEmpty ? 0 : spans.length - 1;
  }
  final String text;
  final Future<AnswerInspectionData> Function()? loader;
  late AnswerInspectionData data;
  List<InspectionSpan> spans = const [];
  late InspectionSummary summary;

  /// Index in [spans] of the cursor. Text after it is ghost text.
  int cursor = 0;

  /// A click or a key fixed the cursor; the pointer does not move it.
  bool pinned = false;

  /// The alternatives radar is open at the cursor.
  bool radarOpen = false;

  /// Option index of the radar selection; null means the chosen option.
  int? pick;

  /// The user moved the cursor at least once (the hint goes away).
  bool moved = false;
  bool loading = false, failed = false, _disposed = false;

  InspectionSpan? get current => spans.isEmpty ? null : spans[cursor];
  bool get available => data.available;

  /// Selected radar option, or null for the chosen token.
  InspectionOption? get picked {
    final span = current;
    final index = pick;
    if (span == null || index == null || index >= span.options.length) {
      return null;
    }
    final option = span.options[index];
    return option.chosen ? null : option;
  }

  void _apply(AnswerInspectionData value) {
    data = value.matches(text)
        ? value
        : const AnswerInspectionData(reason: 'invalid_data');
    spans = data.available ? _tokenSpans(data) : _wordSpans(text);
    summary = _summary();
  }

  /// Spans of whole grapheme clusters. Tokens that end inside a character
  /// join the next token, so the cursor never splits a character.
  List<InspectionSpan> _tokenSpans(AnswerInspectionData data) {
    final boundaries = <int, int>{0: 0};
    var units = 0, bytes = 0;
    for (final character in text.characters) {
      units += character.length;
      bytes += utf8.encode(character).length;
      boundaries[bytes] = units;
    }
    final result = <InspectionSpan>[];
    var startByte = 0, first = 0;
    var logprob = 0.0;
    for (var i = 0; i < data.tokens.length; i++) {
      final token = data.tokens[i];
      logprob += token.logprob;
      final end = boundaries[token.endByte];
      if (end == null) continue;
      final start = boundaries[startByte]!;
      if (end > start) {
        final single = i == first;
        result.add(
          InspectionSpan(
            start: start,
            end: end,
            text: text.substring(start, end),
            token: single ? token : null,
            tokenIndex: single ? i : null,
            certainty: math.exp(logprob),
            options: single ? _options(token) : const [],
          ),
        );
      }
      startByte = token.endByte;
      first = i + 1;
      logprob = 0;
    }
    return List.unmodifiable(result);
  }

  static List<InspectionOption> _options(InspectionToken token) {
    final options = <InspectionOption>[];
    var hasChosen = false;
    for (var i = 0; i < token.alternatives.length; i++) {
      final alt = token.alternatives[i];
      final text = alt.text;
      if (text == null) continue;
      final chosen = !hasChosen && token.isChosen(alt);
      hasChosen |= chosen;
      options.add(InspectionOption(text, alt.likelihood, chosen, i + 1));
    }
    if (!hasChosen) {
      options.add(
        InspectionOption(token.text ?? '', token.likelihood, true, null),
      );
    }
    options.sort((a, b) => b.likelihood.compareTo(a.likelihood));
    return List.unmodifiable(options);
  }

  static List<InspectionSpan> _wordSpans(String text) => List.unmodifiable([
    for (final m in RegExp(r'\s*\S+|\s+$').allMatches(text))
      InspectionSpan(start: m.start, end: m.end, text: m.group(0)!),
  ]);

  InspectionSummary _summary() {
    final measured = spans.where((s) => s.certainty != null).toList();
    double? average;
    if (measured.isNotEmpty) {
      average = math.exp(
        measured.fold<double>(0, (v, s) => v + math.log(s.certainty!)) /
            measured.length,
      );
    }
    int? lowest;
    for (var i = 0; i < spans.length; i++) {
      final s = spans[i];
      if (s.certainty == null || !s.hasWord) continue;
      if (lowest == null || s.certainty! < spans[lowest].certainty!) {
        lowest = i;
      }
    }
    return InspectionSummary(
      average: average,
      lowest: lowest,
      forks: [
        for (var i = 0; i < spans.length; i++)
          if (spans[i].fork) i,
      ],
      tokens: data.available ? data.tokens.length : 0,
    );
  }

  /// Geometric mean of the span certainties, or null without data.
  double? certaintyOf(Iterable<int> indexes) {
    final values = [
      for (final i in indexes)
        if (spans[i].certainty != null) spans[i].certainty!,
    ];
    if (values.isEmpty) return null;
    return math.exp(
      values.fold<double>(0, (v, p) => v + math.log(p)) / values.length,
    );
  }

  /// Short function words do not get links.
  static const _stop = {
    'the', 'and', 'was', 'her', 'his', 'she', 'had', 'with', 'but', 'not', //
    'uma', 'que', 'com', 'para', 'não', 'ela', 'mas', 'dela', 'seu', 'até',
  };

  /// Earlier spans with the same word, or with the word of an alternative of
  /// the cursor span. Only text before the cursor is used.
  List<InspectionLink> links([int? index]) {
    final at = index ?? cursor;
    if (spans.isEmpty) return const [];
    final span = spans[at];
    final word = span.word;
    bool usable(String w) => w.characters.length >= 3 && !_stop.contains(w);
    final alternatives = {
      for (final o in span.options)
        if (!o.chosen && o.likelihood >= 0.05)
          InspectionSpan(start: 0, end: 0, text: o.text).word,
    }..removeWhere((w) => !usable(w) || w == word);
    final result = <InspectionLink>[];
    for (var i = 0; i < at; i++) {
      final other = spans[i].word;
      if (usable(word) && other == word) {
        result.add(InspectionLink(i));
      } else if (alternatives.contains(other)) {
        result.add(InspectionLink(i, alternative: true));
      }
    }
    return result;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// Move the cursor. Returns true when it changed.
  bool moveTo(int index, {bool? pin}) {
    if (spans.isEmpty) return false;
    final next = index.clamp(0, spans.length - 1);
    final changed = next != cursor || (pin != null && pin != pinned);
    moved = true;
    if (pin != null) pinned = pin;
    if (next != cursor) {
      cursor = next;
      pick = null;
      radarOpen = false;
    }
    if (changed) _changed();
    return changed;
  }

  void step(int delta) => moveTo(cursor + delta, pin: true);

  /// The span that holds code unit [offset].
  int spanAt(int offset) {
    var low = 0, high = spans.length - 1;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (spans[middle].start <= offset) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  void nextFork() {
    final forks = summary.forks;
    if (forks.isEmpty) return;
    final next = forks.firstWhere((i) => i > cursor, orElse: () => forks.first);
    moveTo(next, pin: true);
    openRadar();
  }

  void showLowest() {
    final lowest = summary.lowest;
    if (lowest == null) return;
    moveTo(lowest, pin: true);
    openRadar();
  }

  void openRadar() {
    if (!available || current == null || current!.options.isEmpty) return;
    radarOpen = true;
    pick = null;
    _changed();
  }

  void closeRadar({bool unpin = false}) {
    if (!radarOpen && !(unpin && pinned)) return;
    radarOpen = false;
    pick = null;
    if (unpin) pinned = false;
    _changed();
  }

  void select(int option) {
    if (pick == option) return;
    pick = option;
    _changed();
  }

  Future<void> load() async {
    if (loader == null || loading || _disposed) return;
    loading = true;
    failed = false;
    _changed();
    try {
      final result = await loader!();
      if (_disposed) return;
      final offset = current?.end ?? text.length;
      _apply(result);
      cursor = spans.isEmpty ? 0 : spanAt(math.max(0, offset - 1));
      pick = null;
      radarOpen = false;
    } catch (_) {
      if (!_disposed) failed = true;
    } finally {
      if (!_disposed) {
        loading = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
