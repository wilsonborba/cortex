import 'package:speech_to_text/speech_to_text.dart';

/// Wraps `speech_to_text` for the prompt dock's microphone button
/// (issue #6): on-device transcription, no dedicated backend involved.
///
/// `speech_to_text` was picked over `record` because there is no
/// cortex_api speech/transcription endpoint reachable from this client
/// (a grep of cortex_api for "transcri|speech|audio" only turns up
/// server-side Whisper usage for *uploaded attachments*, there is no
/// public streaming speech endpoint), and `speech_to_text` gives on-device
/// transcription plus its own microphone-permission handling on both
/// mobile (via the platform speech recognizer permission) and web (via the
/// browser's own mic permission prompt), so no extra `permission_handler`
/// dependency is needed just for this feature.
class VoiceInputService {
  VoiceInputService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _available = false;

  /// Must be called (and must return true) before [startListening]. Also
  /// triggers the platform/browser microphone permission prompt the first
  /// time it is called.
  Future<bool> initialize() async {
    _available = await _speech.initialize();
    return _available;
  }

  bool get isAvailable => _available;

  bool get isListening => _speech.isListening;

  /// Starts listening. [onResult] is called with the current best-guess
  /// transcript every time it changes (interim and final results alike, so
  /// callers should treat later calls as replacing, not appending to,
  /// earlier ones). [onAmplitude] is called with the microphone's sound
  /// level in dB (roughly -50 to 0 quiet-to-loud) for the live sound-wave
  /// visualization.
  Future<void> startListening({
    required void Function(String transcript) onResult,
    void Function(double amplitudeDb)? onAmplitude,
  }) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      onSoundLevelChange: onAmplitude,
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> stopListening() => _speech.stop();

  void dispose() {
    if (_speech.isListening) _speech.cancel();
  }
}
