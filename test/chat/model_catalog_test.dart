import 'package:cortex/domain/models/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses allowlisted catalog defaults and profile-specific limits', () {
    final catalog = ChatModelCatalog.fromJson({
      'models': [
        {
          'id': 'cortex-t0',
          'tier': 't0',
          'name': 'Cortex T0',
          'context_tokens': 8192,
          'max_input_tokens': 5000,
          'max_output_tokens': 1024,
          'capabilities': ['text', 'vision'],
        },
        {
          'id': 'bonsai25-uncensored',
          'tier': 't1',
          'name': 'Bonsai 2.5 27B Uncensored',
          'context_tokens': 8192,
          'max_input_tokens': 4800,
          'max_output_tokens': 2048,
          'capabilities': ['text', 'vision', 'tool-calls'],
        },
        {
          'id': 'bonsai25-official',
          'tier': 't1',
          'name': 'Bonsai 2.5 27B Official',
          'context_tokens': 8192,
          'max_input_tokens': 4700,
          'max_output_tokens': 2048,
          'capabilities': ['text', 'vision', 'tool-calls'],
        },
      ],
      'default_model_id': 'bonsai25-uncensored',
      'max_input_tokens': 5000,
      'estimate_rule': {
        'unit': 'utf8_bytes',
        'bytes_per_token': 3,
        'copies': 2,
      },
    });

    expect(catalog.defaultModelId, 'bonsai25-uncensored');
    expect(catalog.models.map((profile) => profile.id), [
      'cortex-t0',
      'bonsai25-uncensored',
      'bonsai25-official',
    ]);
    expect(catalog.find('bonsai25-uncensored')!.maxInputTokens, 4800);
    expect(catalog.find('bonsai25-official')!.maxOutputTokens, 2048);
    expect(catalog.find('bonsai25-official')!.supportsVision, isTrue);
    expect(catalog.find('/arbitrary/model.gguf'), isNull);
  });

  test('legacy catalog response exposes only T0', () {
    final catalog = ChatModelCatalog.fromJson({
      'max_input_tokens': 512,
      'estimate_rule': {'bytes_per_token': 2, 'copies': 1},
    });

    expect(catalog.defaultModelId, 'cortex-t0');
    expect(catalog.models.map((profile) => profile.id), ['cortex-t0']);
    expect(catalog.find('bonsai25-uncensored'), isNull);
    expect(catalog.budget.maxTokens, 512);
  });

  test('does not replace a declared but unavailable default', () {
    final catalog = ChatModelCatalog.fromJson({
      'models': [
        {'id': 'cortex-t0', 'tier': 't0', 'name': 'Cortex T0'},
      ],
      'default_model_id': 'bonsai25-uncensored',
      'max_input_tokens': 512,
    });

    expect(catalog.defaultModelId, 'bonsai25-uncensored');
    expect(catalog.find(catalog.defaultModelId), isNull);
  });
}
