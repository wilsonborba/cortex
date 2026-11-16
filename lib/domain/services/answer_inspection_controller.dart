import 'dart:math' as math;
import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import '../models/answer_inspection.dart';

/// Read-only navigation over one saved answer. No generation API belongs here.
class AnswerInspectionController extends ChangeNotifier {
  AnswerInspectionController({
    required this.text,
    this.loader,
    AnswerInspectionData? initialData,
  }) {
    data = initialData == null
        ? const AnswerInspectionData()
        : initialData.matches(text)
        ? initialData
        : const AnswerInspectionData(reason: 'invalid_data');
    _allPositions = positions(null);
    _graphemeIndex = {
      for (var i = 0; i < _allPositions.length; i++)
        _allPositions[i].codeUnit: i,
    };
    _positions = positions(data.available ? data : null);
    index = _positions.length - 1;
    _updateMatches();
  }
  final String text;
  final Future<AnswerInspectionData> Function()? loader;
  late AnswerInspectionData data;
  late List<RevealPosition> _positions;
  late List<RevealPosition> _allPositions;
  late Map<int, int> _graphemeIndex;
  late int index;
  bool loading = false, failed = false, _disposed = false;
  InspectionMode mode = InspectionMode.predictions;
  int detail = 3;
  double dialAngle = math.pi * 0.75, dialDistance = 0.5;
  InspectionTextMatch? focusMatch;
  List<InspectionTextMatch> _earlier = [];
  List<InspectionTextMatch> get earlierMatches =>
      _earlier.take(detail).toList(growable: false);
  Iterable<InspectionToken> get visibleRecordedTokens =>
      data.tokens.where((t) => t.endByte <= cursor.byte && t.bytes.isNotEmpty);
  List<InspectionAlternative> get alternatives =>
      nextToken?.otherAlternatives.take(detail).toList(growable: false) ??
      const [];
  void selectMode(InspectionMode value) {
    if (mode == value) return;
    mode = value;
    dialAngle = value == InspectionMode.predictions
        ? math.pi * 0.75
        : math.pi * 0.25;
    notifyListeners();
  }

  void selectDetail(int value) {
    detail = value.clamp(1, 5);
    dialDistance = (detail - 1) / 4;
    notifyListeners();
  }

  void setDial(double angle, double distance) {
    if (!angle.isFinite || !distance.isFinite) return;
    dialAngle = angle.clamp(0, math.pi);
    dialDistance = distance.clamp(0, 1);
    mode = dialAngle >= math.pi / 2
        ? InspectionMode.predictions
        : InspectionMode.repeatedText;
    detail = 1 + (dialDistance * 4).round();
    notifyListeners();
  }

  int codeUnitAtByte(int byte) {
    var low = 0, high = _allPositions.length - 1;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_allPositions[middle].byte <= byte) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return _allPositions[low].codeUnit;
  }

  void _updateMatches() {
    focusMatch = null;
    _earlier = [];
    final prefix = visibleText.trimRight();
    final units = prefix.characters.toList();
    final letters = RegExp(r'[\p{L}\p{N}]', unicode: true);
    for (var length = math.min(24, units.length); length >= 2; length--) {
      final needle = units.sublist(units.length - length).join().trimLeft();
      if (needle.characters.length < 2 || !letters.hasMatch(needle)) continue;
      final start = prefix.length - needle.length;
      final earlier = text.substring(0, start);
      var from = earlier.length;
      final matches = <InspectionTextMatch>[];
      while (from >= 0 && matches.length < 5) {
        final found = earlier.lastIndexOf(needle, from);
        if (found < 0) break;
        if (_graphemeIndex.containsKey(found) &&
            _graphemeIndex.containsKey(found + needle.length)) {
          matches.add(InspectionTextMatch(found, found + needle.length));
        }
        from = found - needle.length;
      }
      if (matches.isNotEmpty) {
        focusMatch = InspectionTextMatch(start, prefix.length);
        _earlier = matches;
        return;
      }
    }
  }

  List<RevealPosition> positions(AnswerInspectionData? source) {
    final allowed = source?.tokens.map((t) => t.endByte).toSet();
    final result = [const RevealPosition(0, 0)];
    var units = 0, bytes = 0;
    for (final character in text.characters) {
      units += character.length;
      bytes += utf8.encode(character).length;
      if (allowed == null || allowed.contains(bytes)) {
        result.add(RevealPosition(units, bytes));
      }
    }
    if (result.last.codeUnit != text.length) {
      result.add(RevealPosition(text.length, bytes));
    }
    return result;
  }

  RevealPosition get cursor => _positions[index];
  String get visibleText => text.substring(0, cursor.codeUnit);
  double fractionForIndex(int value) => _allPositions.length == 1
      ? 1
      : _graphemeIndex[_positions[value].codeUnit]! /
            (_allPositions.length - 1);
  double get fraction => fractionForIndex(index);
  int indexForFraction(double value) {
    final target =
        value.clamp(0.0, 1.0).toDouble() * (_allPositions.length - 1);
    var best = 0;
    var distance = double.infinity;
    for (var i = 0; i < _positions.length; i++) {
      final difference = (_graphemeIndex[_positions[i].codeUnit]! - target)
          .abs();
      if (difference <= distance) {
        best = i;
        distance = difference;
      }
    }
    return best;
  }

  InspectionToken? get nextToken {
    if (!data.available || cursor.codeUnit == text.length) return null;
    for (final token in data.tokens) {
      if (token.startByte >= cursor.byte && token.bytes.isNotEmpty) {
        return token;
      }
    }
    return null;
  }

  void reveal(double value) {
    final next = indexForFraction(value);
    if (next != index) {
      index = next;
      _updateMatches();
      notifyListeners();
    }
  }

  double fractionAfterStep(int delta) =>
      fractionForIndex((index + delta).clamp(0, _positions.length - 1));
  void step(int delta) {
    final next = (index + delta).clamp(0, _positions.length - 1);
    if (next != index) {
      index = next;
      _updateMatches();
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (loader == null || loading || _disposed) return;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final result = await loader!();
      if (_disposed) return;
      final old = fraction;
      data = result.matches(text)
          ? result
          : const AnswerInspectionData(reason: 'invalid_data');
      _positions = positions(data.available ? data : null);
      index = indexForFraction(old);
      _updateMatches();
    } catch (_) {
      if (!_disposed) failed = true;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
