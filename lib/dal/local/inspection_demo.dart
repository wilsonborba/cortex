import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/answer_inspection.dart';

/// Static recorded inspection samples for the public landing (cortex#81).
/// Each file holds one short fictional answer and its genuine recorded token
/// alternatives. Loading them never calls a model or the Cortex API.
class InspectionDemoSource {
  const InspectionDemoSource({this.bundle});
  final AssetBundle? bundle;

  static String language(String code) => switch (code) {
    'pt' => 'pt',
    'th' => 'th',
    _ => 'en',
  };

  static final _cache = <String, (String, AnswerInspectionData)>{};

  /// A sample that already loaded, so the example shows without a wait.
  static (String, AnswerInspectionData)? cached(String languageCode) =>
      _cache[language(languageCode)];

  Future<void> preloadAll() async {
    for (final code in const ['en', 'pt', 'th']) {
      await load(code);
    }
  }

  Future<(String, AnswerInspectionData)> load(String languageCode) async {
    final hit = cached(languageCode);
    if (hit != null) return hit;
    final raw = await (bundle ?? rootBundle).loadString(
      'lib/dal/data/inspection_demo_${language(languageCode)}.json',
    );
    final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return _cache[language(languageCode)] = (
      json['text'] as String,
      AnswerInspectionData.fromJson(json),
    );
  }
}
