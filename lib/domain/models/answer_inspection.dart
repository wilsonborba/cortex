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

class RevealPosition {
  const RevealPosition(this.codeUnit, this.byte);
  final int codeUnit, byte;
}
