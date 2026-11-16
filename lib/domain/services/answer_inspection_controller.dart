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
  }
  final String text;
  final Future<AnswerInspectionData> Function()? loader;
  late AnswerInspectionData data;
  late List<RevealPosition> _positions;
  late List<RevealPosition> _allPositions;
  late Map<int, int> _graphemeIndex;
  late int index;
  bool loading = false, failed = false, _disposed = false;
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
      notifyListeners();
    }
  }

  double fractionAfterStep(int delta) =>
      fractionForIndex((index + delta).clamp(0, _positions.length - 1));
  void step(int delta) {
    final next = (index + delta).clamp(0, _positions.length - 1);
    if (next != index) {
      index = next;
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
