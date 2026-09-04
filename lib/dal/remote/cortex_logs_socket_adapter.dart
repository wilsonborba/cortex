import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/logs.dart';
import '../../core/settings.dart';

/// Streams cortex_api's live log lines from `ws://.../logs/stream` (see its
/// `lib/presentation/api/routes/logs_stream.py`).
///
/// This connects straight to cortex_api, bypassing api_for_apps' public
/// proxy entirely: that proxy (`LocalProxyService.forward_request`, see
/// `src/domain/services/local_proxy_service.py`) is built on
/// `httpx.AsyncClient` plain request/response streaming and its route is
/// only registered for `GET/POST/PUT/PATCH/DELETE/HEAD`, there is no
/// WebSocket upgrade handling anywhere in that path. A WebSocket cannot be
/// carried through it as-is, so this is a documented local-dev-only
/// shortcut gated by [AppSettings.enableLiveLogStreaming], not a production
/// integration. Do not enable it against a non-local cortex_api deployment.
class CortexLogsSocketAdapter {
  CortexLogsSocketAdapter({String? webSocketUrl})
    : _webSocketUrl = webSocketUrl ?? AppSettings.cortexLogsWebSocketUrl;

  final String _webSocketUrl;
  WebSocketChannel? _channel;

  /// Opens the connection and returns a broadcast stream of raw log lines.
  /// Throws a [StateError] if [AppSettings.enableLiveLogStreaming] is off,
  /// callers (the debug telemetry panel) must check that flag before
  /// offering any UI to connect.
  Stream<String> connect() {
    if (!AppSettings.enableLiveLogStreaming) {
      throw StateError(
        'Live log streaming is disabled (AppSettings.enableLiveLogStreaming '
        'is false). It only works against a local cortex_api instance, see '
        'CortexLogsSocketAdapter\'s doc comment.',
      );
    }

    final channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
    _channel = channel;

    final controller = StreamController<String>.broadcast(
      onCancel: () => disconnect(),
    );

    channel.stream.listen(
      (event) => controller.add(event.toString()),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.warning('Cortex logs socket error: $error');
        controller.addError(error, stackTrace);
      },
      onDone: () => controller.close(),
      cancelOnError: false,
    );

    return controller.stream;
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
