import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/attachment.dart';

/// Issue #11's "interactive inline audio message player" for a voice
/// message attachment: play/pause plus a duration/waveform-style bar.
/// Plays straight from the attachment's in-memory bytes (`BytesSource`),
/// no upload/download round trip needed since the bytes are already local.
class AudioMessagePlayer extends StatefulWidget {
  const AudioMessagePlayer({super.key, required this.attachment});

  final ChatAttachment attachment;

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration? _total;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  @override
  void initState() {
    super.initState();
    _total = widget.attachment.audioDuration;
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (_position > Duration.zero && _state == PlayerState.paused) {
      await _player.resume();
      return;
    }
    await _player.play(BytesSource(widget.attachment.bytes));
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _total ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              child: Icon(
                _state == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                size: 16,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StaticWaveform(
              progress: progress,
              activeColor: scheme.primary,
              inactiveColor: scheme.outline.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _format(_state == PlayerState.stopped ? total : (total - _position)),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative fixed-bar waveform (issue #11's "duration waveform"): this
/// app never analyzes real audio amplitude for a sent clip, the bars are a
/// stable pseudo-random pattern (seeded by nothing but index, so it's
/// deterministic per rebuild) whose fill sweeps left-to-right with
/// [progress], matching the visual language voice messages use everywhere
/// without needing real waveform decoding.
class _StaticWaveform extends StatelessWidget {
  const _StaticWaveform({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  static const _barCount = 24;
  static const _heights = [
    6.0, 10.0, 14.0, 8.0, 16.0, 12.0, 18.0, 9.0,
    14.0, 11.0, 17.0, 7.0, 13.0, 15.0, 9.0, 12.0,
    16.0, 10.0, 14.0, 8.0, 18.0, 11.0, 13.0, 7.0,
  ];

  @override
  Widget build(BuildContext context) {
    final filledCount = (progress * _barCount).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_barCount, (i) {
        return Container(
          width: 2,
          height: _heights[i],
          decoration: BoxDecoration(
            color: i < filledCount ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
