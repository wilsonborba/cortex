import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/attachment.dart';
import '../../../domain/services/audio_recorder_service.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Issue #11's inline recording bar: tapping the prompt dock's mic button
/// transitions the whole dock into this bar (pulsating red indicator with
/// an elapsed timer, a live waveform, a cancel button that discards the
/// clip, and a send button that hands a finished `ChatAttachment` back to
/// the caller). Replaces the old speech-to-text dictation button entirely,
/// this records and sends an actual playable voice message instead of
/// transcribing into the text field.
class VoiceRecordingBar extends StatefulWidget {
  const VoiceRecordingBar({
    super.key,
    required this.onSend,
    required this.onCancelled,
  });

  /// Called with the finished recording once the user taps send. The bar
  /// has already torn itself down by the time this fires.
  final ValueChanged<ChatAttachment> onSend;

  /// Called when recording is cancelled/discarded (explicit cancel tap, or
  /// a recording too short to be worth sending), so the dock can go back to
  /// its normal state without a message being produced.
  final VoidCallback onCancelled;

  @override
  State<VoiceRecordingBar> createState() => _VoiceRecordingBarState();
}

class _VoiceRecordingBarState extends State<VoiceRecordingBar> {
  final _service = AudioRecorderService();
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;
  double _amplitude = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context);
    try {
      final available = await _service.hasPermission();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.micPermissionDenied),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onCancelled();
        return;
      }

      await _service.start(
        onAmplitude: (level) {
          if (mounted) setState(() => _amplitude = level);
        },
      );
      _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() => _elapsed = _service.elapsed);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.micPermissionDenied),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onCancelled();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    // If the widget is torn down without an explicit stop (send/cancel
    // already handled), make sure the microphone is actually released.
    if (!_finishing) _service.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    _tickTimer?.cancel();
    _finishing = true;
    await _service.cancel();
    widget.onCancelled();
  }

  Future<void> _send() async {
    _tickTimer?.cancel();
    _finishing = true;
    final recorded = await _service.stop();
    if (recorded == null || recorded.duration < const Duration(milliseconds: 500)) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.voiceMessageTooShort),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      widget.onCancelled();
      return;
    }
    final attachment = ChatAttachment(
      id: 'voice-${DateTime.now().microsecondsSinceEpoch}',
      filename: 'voice-message.webm',
      mimeType: recorded.mimeType,
      bytes: recorded.bytes,
      audioDuration: recorded.duration,
    );
    widget.onSend(attachment);
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          Tooltip(
            message: l10n.voiceCancelRecording,
            child: IconButton(
              onPressed: _cancel,
              icon: Icon(Icons.delete_outline, color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          _PulsatingDot(color: scheme.error),
          const SizedBox(width: 8),
          Text(
            '● ${_formatElapsed(_elapsed)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _LiveWaveform(amplitude: _amplitude, color: scheme.error)),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Tooltip(
              message: l10n.voiceSendRecording,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: _send,
                child: Icon(Icons.arrow_upward, size: 16, color: scheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pulsating red recording indicator called out explicitly in issue
/// #11 ("pulsating red indicator").
class _PulsatingDot extends StatefulWidget {
  const _PulsatingDot({required this.color});

  final Color color;

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Live waveform bars reacting to [amplitude], same visual language the old
/// dictation button used for its live sound-wave indicator.
class _LiveWaveform extends StatelessWidget {
  const _LiveWaveform({required this.amplitude, required this.color});

  final double amplitude;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final level = ((amplitude + 45) / 45).clamp(0.08, 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(12, (i) {
        final phase = (i.isEven ? level : level * 0.55).clamp(0.08, 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 3,
          height: 4 + phase * 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
