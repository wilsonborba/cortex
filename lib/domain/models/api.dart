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
  const ApiError(this.status, this.number, this.message);
  final int status;
  final int? number;
  final String message;
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

/// Result of POST /files: a file id, or the file-not-saved notice (8.8).
class UploadResult {
  const UploadResult({this.fileId, this.noticeNumber});
  final String? fileId;
  final int? noticeNumber;
}
