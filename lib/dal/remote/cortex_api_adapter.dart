import '../../core/settings.dart';

/// Remote adapter for the Cortex backend facade.
///
/// This is intentionally unwired: no HTTP call is made from this class yet.
/// It exists only as the seam that issue #3 (backend/API integration) will
/// fill in, so the domain layer already has a stable contract to call
/// against once streaming chat completions are implemented.
class CortexApiAdapter {
  const CortexApiAdapter({this.baseUrl = AppSettings.cortexApiBaseUrl});

  final String baseUrl;

  /// Placeholder for `POST /v1/chat/completions`. Not implemented in this
  /// issue: the chat UI currently runs entirely against mocked data.
  Future<void> streamChatCompletion() async {
    throw UnimplementedError(
      'Backend wiring is out of scope for issue #1, see issue #3.',
    );
  }
}
