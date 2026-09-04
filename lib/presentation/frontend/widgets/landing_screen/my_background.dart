import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Chromatic particle liquid animation.
///
/// A field of soft, glowing, colour-shifting blobs drifts and bounces behind
/// the landing page content, in deliberate contrast with the rest of the app's
/// monochrome [AppTheme]. Motion is driven by real elapsed delta-time (not a
/// frame count), so the animation runs at the same physical speed regardless
/// of the device's refresh rate or any dropped frames.
class MyBackground extends StatefulWidget {
  const MyBackground({super.key, this.particleCount = 26});

  final int particleCount;

  @override
  State<MyBackground> createState() => _MyBackgroundState();
}

class _MyBackgroundState extends State<MyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  Duration _lastElapsed = Duration.zero;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(_rng),
    );
    _controller =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_tick)
          ..repeat();
  }

  void _tick() {
    final elapsed = _controller.lastElapsedDuration ?? Duration.zero;
    var dt =
        (elapsed - _lastElapsed).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    // Guard against the first tick (huge dt) or a debugger-paused resume.
    if (dt <= 0 || dt > 0.1) dt = 1 / 60;

    for (final particle in _particles) {
      particle.step(dt);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: CustomPaint(
          painter: _LiquidParticlesPainter(_particles),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.hue,
    required this.hueSpeed,
  });

  factory _Particle.random(math.Random rng) {
    // Positions and velocities are stored as fractions of the canvas size
    // (0..1) so the field looks the same regardless of viewport, and speeds
    // are expressed per second, ready to be scaled by delta-time.
    final angle = rng.nextDouble() * 2 * math.pi;
    final speed = 0.02 + rng.nextDouble() * 0.05;
    return _Particle(
      position: Offset(rng.nextDouble(), rng.nextDouble()),
      velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
      radius: 40 + rng.nextDouble() * 90,
      hue: rng.nextDouble() * 360,
      hueSpeed: 12 + rng.nextDouble() * 24,
    );
  }

  Offset position;
  Offset velocity;
  final double radius;
  double hue;
  final double hueSpeed;

  double _wobblePhase = 0;

  void step(double dt) {
    _wobblePhase += dt;
    // Gentle sinusoidal wobble layered on top of the linear drift gives the
    // blobs an organic, liquid feel instead of a mechanical straight bounce.
    final wobble = Offset(
      math.sin(_wobblePhase * 0.7) * 0.01,
      math.cos(_wobblePhase * 0.9) * 0.01,
    );
    position += (velocity + wobble) * dt;
    hue = (hue + hueSpeed * dt) % 360;

    var dx = velocity.dx;
    var dy = velocity.dy;
    if (position.dx < -0.15 || position.dx > 1.15) dx = -dx;
    if (position.dy < -0.15 || position.dy > 1.15) dy = -dy;
    velocity = Offset(dx, dy);
    position = Offset(
      position.dx.clamp(-0.2, 1.2),
      position.dy.clamp(-0.2, 1.2),
    );
  }
}

class _LiquidParticlesPainter extends CustomPainter {
  _LiquidParticlesPainter(this.particles) : super();

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final center = Offset(
        particle.position.dx * size.width,
        particle.position.dy * size.height,
      );
      final color = HSVColor.fromAHSV(0.55, particle.hue, 0.65, 1.0).toColor();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: particle.radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(center, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidParticlesPainter oldDelegate) => true;
}
