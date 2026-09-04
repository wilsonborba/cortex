import 'package:flutter/material.dart';

import '../../../domain/services/voice_input_service.dart';
import '../../../l10n/generated/app_localizations.dart';

/// ChatGPT-style microphone button for the prompt dock (issue #6):
/// tapping starts on-device speech-to-text ([VoiceInputService]) with a
/// live sound-wave/amplitude visualization, tapping again stops it and
/// hands the transcript to [onTranscript] so the caller can insert it into
/// the prompt field (this widget never auto-sends).
class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton({super.key, required this.onTranscript});

  final ValueChanged<String> onTranscript;

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _service = VoiceInputService();
  bool _listening = false;
  double _amplitude = 0;
  String _transcript = '';

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _service.stopListening();
      final transcript = _transcript.trim();
      setState(() {
        _listening = false;
        _transcript = '';
        _amplitude = 0;
      });
      if (transcript.isNotEmpty) widget.onTranscript(transcript);
      return;
    }

    final available = await _service.initialize();
    if (!available) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.micPermissionDenied),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _listening = true;
      _transcript = '';
      _amplitude = 0;
    });
    await _service.startListening(
      onResult: (text) => _transcript = text,
      onAmplitude: (level) {
        if (mounted) setState(() => _amplitude = level);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: _listening ? 148 : 48,
      height: 48,
      decoration: BoxDecoration(
        color: _listening ? scheme.error.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_listening)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _SoundWave(amplitude: _amplitude, color: scheme.error),
              ),
            ),
          Tooltip(
            message: _listening ? l10n.voiceStopRecording : l10n.voiceStartRecording,
            child: IconButton(
              onPressed: _toggle,
              icon: Icon(
                _listening ? Icons.stop_circle : Icons.mic_none_outlined,
                color: _listening
                    ? scheme.error
                    : scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Five bars whose heights react to [amplitude] (roughly a dB-ish level
/// reported by `speech_to_text`'s `onSoundLevelChange`, small negative to
/// positive numbers, exact range varies per platform, hence the loose
/// normalization here: this is a cosmetic live indicator, not a precise
/// metering widget).
class _SoundWave extends StatelessWidget {
  const _SoundWave({required this.amplitude, required this.color});

  final double amplitude;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final level = ((amplitude + 2) / 12).clamp(0.08, 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final phase = (i.isEven ? level : level * 0.6).clamp(0.08, 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 3,
          height: 6 + phase * 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
