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
///
/// [AudioEncoder.pcm16bits] is the *only* encoder `record_web`'s
/// `startStream` supports (confirmed in its source: every other encoder,
/// `opus` included, hits a `default: throw Exception('Stream not
/// supported.')` branch before the microphone is ever touched, so no
/// permission prompt fires and the buffer stays empty, exactly the
/// "records nothing, no permission dialog" symptom this fixes). Its
/// streamed chunks are headerless raw PCM16 samples, so [stop] wraps the
/// accumulated bytes in a standard WAV header itself before handing back a
/// clip that is actually a valid, playable `audio/wav` file.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<Uint8List>? _dataSub;
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  static const _encoder = AudioEncoder.pcm16bits;
  static const _sampleRate = 44100;
  static const _numChannels = 1;
  static const _bitsPerSample = 16;
  static const _mimeType = 'audio/wav';

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts capturing. [onAmplitude] receives a rough level (dBFS-ish,
  /// negative to ~0) every 200ms for the live waveform indicator, matching
  /// the cadence the old dictation button used.
  Future<void> start({required void Function(double level) onAmplitude}) async {
    _buffer.clear();
    _startedAt = DateTime.now();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: _encoder,
        sampleRate: _sampleRate,
        numChannels: _numChannels,
      ),
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
    final pcmBytes = _buffer.takeBytes();
    if (pcmBytes.isEmpty) return null;
    return RecordedAudio(bytes: _wrapAsWav(pcmBytes), mimeType: _mimeType, duration: duration);
  }

  /// Prepends a standard 44-byte PCM WAV header to raw, headerless 16-bit
  /// PCM samples so the result is a self-contained, playable audio file.
  static Uint8List _wrapAsWav(Uint8List pcmBytes) {
    const headerSize = 44;
    final byteRate = _sampleRate * _numChannels * _bitsPerSample ~/ 8;
    final blockAlign = _numChannels * _bitsPerSample ~/ 8;
    final dataSize = pcmBytes.length;

    final header = ByteData(headerSize);
    void writeAscii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        header.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // audio format: PCM
    header.setUint16(22, _numChannels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final result = BytesBuilder(copy: false);
    result.add(header.buffer.asUint8List());
    result.add(pcmBytes);
    return result.takeBytes();
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
