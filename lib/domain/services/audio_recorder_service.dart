import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Result of a finished recording, before it becomes a `ChatAttachment`.
class RecordedAudio {
  const RecordedAudio({
    required this.bytes,
    required this.mimeType,
    required this.duration,
  });

  final Uint8List bytes;
  final String mimeType;
  final Duration duration;
}

/// Wraps the `record` package for issue #11's voice-message flow: capture
/// raw microphone audio (not speech-to-text), so it can be sent and played
/// back as its own message, matching `VoiceRecordingBar`'s spec.
///
/// Uses `startStream` (raw bytes as they're captured) rather than `start`
/// (writes to a path/blob URL that then has to be fetched back), so the
/// finished clip's bytes are already in memory the moment recording stops,
/// with no extra network round trip on web.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<Uint8List>? _dataSub;
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  /// Opus-in-webm is what `record`'s web implementation actually produces
  /// across Chromium/Firefox, and it's a mime type cortex_api's ingestion
  /// already accepts (`audio/...`, see `attachment.dart`'s doc comment).
  static const _encoder = AudioEncoder.opus;
  static const _mimeType = 'audio/webm';

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts capturing. [onAmplitude] receives a rough level (dBFS-ish,
  /// negative to ~0) every 200ms for the live waveform indicator, matching
  /// the cadence the old dictation button used.
  Future<void> start({required void Function(double level) onAmplitude}) async {
    _buffer.clear();
    _startedAt = DateTime.now();
    final stream = await _recorder.startStream(
      const RecordConfig(encoder: _encoder, numChannels: 1),
    );
    _dataSub = stream.listen(_buffer.add);
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) => onAmplitude(amp.current));
  }

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// Stops and returns the recording, or null if nothing was captured.
  Future<RecordedAudio?> stop() async {
    final duration = elapsed;
    await _recorder.stop();
    await _amplitudeSub?.cancel();
    await _dataSub?.cancel();
    _amplitudeSub = null;
    _dataSub = null;
    _startedAt = null;
    final bytes = _buffer.takeBytes();
    if (bytes.isEmpty) return null;
    return RecordedAudio(bytes: bytes, mimeType: _mimeType, duration: duration);
  }

  /// Stops and discards whatever was captured, no bytes are read back.
  Future<void> cancel() async {
    await _amplitudeSub?.cancel();
    await _dataSub?.cancel();
    _amplitudeSub = null;
    _dataSub = null;
    _startedAt = null;
    _buffer.clear();
    try {
      await _recorder.cancel();
    } catch (_) {
      // Already stopped/never started: nothing to clean up.
    }
  }

  void dispose() {
    _amplitudeSub?.cancel();
    _dataSub?.cancel();
    _recorder.dispose();
  }
}
