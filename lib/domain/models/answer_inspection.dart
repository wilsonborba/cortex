import 'dart:convert';
import 'dart:math' as math;

class InspectionAlternative {
  const InspectionAlternative(this.bytes, this.logprob);
  final List<int> bytes;
  final double logprob;
  double get likelihood => math.exp(logprob);
  String? get text {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  factory InspectionAlternative.fromJson(Map<String, dynamic> value) {
    final bytes = (value['bytes'] as List)
        .map((v) => (v as num).toInt())
        .toList();
    final p = (value['logprob'] as num).toDouble();
    if (bytes.length > 1024 ||
        bytes.any((v) => v < 0 || v > 255) ||
        !p.isFinite ||
        p > 0) {
      throw const FormatException('Invalid token data');
    }
    return InspectionAlternative(List.unmodifiable(bytes), p);
  }
}

class InspectionToken extends InspectionAlternative {
  const InspectionToken(
    super.bytes,
    super.logprob,
    this.startByte,
    this.endByte,
    this.alternatives,
  );
  final int startByte, endByte;
  final List<InspectionAlternative> alternatives;
  bool isChosen(InspectionAlternative value) {
    if (value.bytes.length != bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (value.bytes[i] != bytes[i]) return false;
    }
    return true;
  }

  Iterable<InspectionAlternative> get otherAlternatives =>
      alternatives.where((a) => !isChosen(a));
  factory InspectionToken.fromJson(Map<String, dynamic> value) {
    final base = InspectionAlternative.fromJson(value);
    final alternatives = [
      for (final v in value['alternatives'] as List)
        InspectionAlternative.fromJson((v as Map).cast<String, dynamic>()),
    ];
    if (alternatives.length > 5) {
      throw const FormatException('Too many alternatives');
    }
    return InspectionToken(
      base.bytes,
      base.logprob,
      (value['start_byte'] as num).toInt(),
      (value['end_byte'] as num).toInt(),
      List.unmodifiable(alternatives),
    );
  }
}

class AnswerInspectionData {
  const AnswerInspectionData({
    this.model = '',
    this.reason = 'not_recorded',
    this.tokens = const [],
  });
  final String model;
  final String? reason;
  final List<InspectionToken> tokens;
  bool get available => reason == null && tokens.isNotEmpty;
  factory AnswerInspectionData.fromJson(Map<String, dynamic> value) =>
      AnswerInspectionData(
        model: value['model'] as String? ?? '',
        reason: value['reason'] as String?,
        tokens: List.unmodifiable([
          for (final v in value['tokens'] as List? ?? const [])
            InspectionToken.fromJson((v as Map).cast<String, dynamic>()),
        ]),
      );
  bool matches(String answer) {
    if (!available) return tokens.isEmpty;
    final bytes = utf8.encode(answer);
    var offset = 0;
    for (final token in tokens) {
      if (token.startByte != offset ||
          token.endByte != offset + token.bytes.length ||
          token.endByte > bytes.length) {
        return false;
      }
      for (final b in token.bytes) {
        if (bytes[offset++] != b) return false;
      }
    }
    return offset == bytes.length;
  }
}

/// One recorded option at a span: the chosen token or an alternative.
class InspectionOption {
  const InspectionOption(this.text, this.likelihood, this.chosen, this.rank);
  final String text;
  final double likelihood;
  final bool chosen;

  /// 1-based rank in the saved alternatives, or null when the chosen token
  /// is not in the saved list. The continue request uses this rank.
  final int? rank;
}

/// A piece of the answer text that the cursor can stop on. With recorded
/// data it is one model token (or a few tokens that split one character).
/// Without data it is one word, and it has no certainty.
class InspectionSpan {
  const InspectionSpan({
    required this.start,
    required this.end,
    required this.text,
    this.token,
    this.tokenIndex,
    this.certainty,
    this.options = const [],
  });
  final int start, end;
  final String text;
  final InspectionToken? token;

  /// Position of [token] in the saved token list. For a joined span this is
  /// its first token, where the model made the choice.
  final int? tokenIndex;

  /// Recorded likelihood of the chosen text, from 0 to 1.
  final double? certainty;

  /// Chosen token and saved alternatives, most likely first.
  final List<InspectionOption> options;

  /// Normalized word for exact earlier-word links.
  String get word => text.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}\p{M}]', unicode: true),
    '',
  );
  bool get hasWord => word.isNotEmpty;

  /// The best other option is at least half as likely as the chosen one.
  bool get fork {
    final chosen = certainty;
    if (chosen == null) return false;
    final others = options.where((o) => !o.chosen);
    return others.isNotEmpty && others.first.likelihood >= chosen * 0.5;
  }

  double get otherLikelihood =>
      math.max(0, 1 - options.fold<double>(0, (v, o) => v + o.likelihood));
}

/// An earlier span with the same word, or with the word of an alternative.
class InspectionLink {
  const InspectionLink(this.span, {this.alternative = false});
  final int span;
  final bool alternative;
}

/// Answer statistics for the summary cards.
class InspectionSummary {
  const InspectionSummary({
    required this.average,
    required this.lowest,
    required this.forks,
    required this.tokens,
  });
  final double? average;
  final int? lowest;
  final List<int> forks;
  final int tokens;
}
