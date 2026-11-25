/// One event of the Cortex output stream (area 10): id, name and the
/// `{message, data}` body.
class ChatEvent {
  const ChatEvent(this.id, this.name, this.message, this.data);
  final int id;
  final String name;
  final String message;
  final Map<String, dynamic> data;
}

/// A Cortex error with its process number (area 1.10).
class ApiError implements Exception {
  const ApiError(
    this.status,
    this.number,
    this.message, {
    this.fieldErrors = const {},
  });
  final int status;
  final int? number;
  final String message;
  final Map<String, String> fieldErrors;
  @override
  String toString() => 'ApiError($status, $number, $message)';
}

/// Token estimate of GET /models (2.10): ceil(bytes / bytes_per_token) * copies.
class InputBudget {
  const InputBudget({
    required this.maxTokens,
    required this.bytesPerToken,
    required this.copies,
  });
  final int maxTokens;
  final int bytesPerToken;
  final int copies;
  static const fallback = InputBudget(
    maxTokens: 5120,
    bytesPerToken: 3,
    copies: 2,
  );
  factory InputBudget.fromJson(Map<String, dynamic> data) {
    final rule = (data['estimate_rule'] as Map?) ?? const {};
    return InputBudget(
      maxTokens:
          (data['max_input_tokens'] as num?)?.toInt() ?? fallback.maxTokens,
      bytesPerToken:
          (rule['bytes_per_token'] as num?)?.toInt() ?? fallback.bytesPerToken,
      copies: (rule['copies'] as num?)?.toInt() ?? fallback.copies,
    );
  }
  int estimate(int utf8Bytes) =>
      ((utf8Bytes + bytesPerToken - 1) ~/ bytesPerToken) * copies;
}

/// One selectable, allowlisted chat profile returned by GET /models.
class ChatModelProfile {
  const ChatModelProfile({
    required this.id,
    required this.tier,
    required this.name,
    required this.contextTokens,
    required this.maxInputTokens,
    required this.maxOutputTokens,
    required this.capabilities,
  });

  final String id;
  final String tier;
  final String name;
  final int contextTokens;
  final int maxInputTokens;
  final int maxOutputTokens;
  final Set<String> capabilities;

  bool get isT1 => tier.toLowerCase() == 't1';
  bool get supportsVision =>
      capabilities.contains('vision') ||
      (id == 'cortex-t0' && capabilities.isEmpty);

  factory ChatModelProfile.fromJson(
    Map<String, dynamic> json, {
    required int legacyInputLimit,
  }) {
    final id = json['id'];
    final tier = json['tier'];
    final name = json['name'];
    if (id is! String || id.isEmpty || tier is! String || name is! String) {
      throw const FormatException('GET /models contains an invalid profile');
    }
    final rawCapabilities = json['capabilities'];
    if (rawCapabilities != null && rawCapabilities is! List) {
      throw const FormatException('GET /models capabilities must be a list');
    }
    return ChatModelProfile(
      id: id,
      tier: tier,
      name: name,
      contextTokens: (json['context_tokens'] as num?)?.toInt() ?? 0,
      maxInputTokens:
          (json['max_input_tokens'] as num?)?.toInt() ?? legacyInputLimit,
      maxOutputTokens: (json['max_output_tokens'] as num?)?.toInt() ?? 0,
      capabilities: {
        for (final value in rawCapabilities as List? ?? const [])
          if (value is String) value,
      },
    );
  }
}

/// Allowlisted catalog and the shared legacy UTF-8 token estimate rule.
class ChatModelCatalog {
  const ChatModelCatalog({
    required this.models,
    required this.defaultModelId,
    required this.budget,
  });

  final List<ChatModelProfile> models;
  final String defaultModelId;
  final InputBudget budget;

  ChatModelProfile? find(String? id) {
    if (id == null) return null;
    for (final model in models) {
      if (model.id == id) return model;
    }
    return null;
  }

  factory ChatModelCatalog.fromJson(Map<String, dynamic> json) {
    final budget = InputBudget.fromJson(json);
    final rawModels = json['models'];
    final models = <ChatModelProfile>[];
    if (rawModels == null) {
      // Older API builds expose only the global input limit. Treat that shape
      // as the existing T0 profile; do not fabricate either T1 profile.
      models.add(
        ChatModelProfile(
          id: 'cortex-t0',
          tier: 't0',
          name: 'Cortex T0',
          contextTokens: 0,
          maxInputTokens: budget.maxTokens,
          maxOutputTokens: 0,
          capabilities: const {},
        ),
      );
    } else {
      if (rawModels is! List) {
        throw const FormatException('GET /models profiles must be a list');
      }
      for (final raw in rawModels) {
        if (raw is! Map) {
          throw const FormatException(
            'GET /models contains an invalid profile',
          );
        }
        models.add(
          ChatModelProfile.fromJson(
            raw.cast<String, dynamic>(),
            legacyInputLimit: budget.maxTokens,
          ),
        );
      }
    }
    final explicitDefault = json['default_model_id'];
    final defaultModelId =
        explicitDefault is String && explicitDefault.isNotEmpty
        ? explicitDefault
        : models.isEmpty
        ? ''
        : models.first.id;
    return ChatModelCatalog(
      models: List.unmodifiable(models),
      defaultModelId: defaultModelId,
      budget: budget,
    );
  }
}

/// Result of POST /files: a file id, or the file-not-saved notice (8.8).
class UploadResult {
  const UploadResult({this.fileId, this.noticeNumber});
  final String? fileId;
  final int? noticeNumber;
}
