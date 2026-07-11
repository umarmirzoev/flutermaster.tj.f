import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AuthBackground — фоновое видео для экранов входа/регистрации.
/// Если файл видео присутствует в assets, проигрывает его.
/// Иначе плавно откатывается к анимированному градиенту с частицами,
/// чтобы экран всегда выглядел «живым» даже без видео-файла.
///
/// Чтобы добавить своё видео:
///   1. Положите файл в assets/video/auth_bg.mp4
///   2. В pubspec.yaml добавьте под assets:  - assets/video/
///   3. Готово — виджет сам его подхватит.
/// ═══════════════════════════════════════════════════════════════════════════

class AuthBackground extends StatefulWidget {
  const AuthBackground({
    super.key,
    this.assetPath = 'assets/video/auth_bg.mp4',
    this.overlayColor = const Color(0xCC0A1F0C),
  });

  final String assetPath;
  final Color overlayColor;

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _videoReady = false;

  late final AnimationController _fallbackAnim;
  final _particles = <_P>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _fallbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    for (int i = 0; i < 25; i++) {
      _particles.add(_P(_rng));
    }
    _fallbackAnim.addListener(() {
      for (final p in _particles) {
        p.update(0.016);
      }
    });

    _tryLoadVideo();
  }

  Future<void> _tryLoadVideo() async {
    try {
      final c = VideoPlayerController.asset(widget.assetPath);
      await c.initialize();
      c
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _videoReady = true;
      });
    } catch (_) {
      // No video asset — fallback animated gradient stays.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fallbackAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoReady && _controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
          Container(color: widget.overlayColor),
        ],
      );
    }

    // Fallback: animated gradient + floating particles
    return AnimatedBuilder(
      animation: _fallbackAnim,
      builder: (context, _) {
        final t = _fallbackAnim.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + t * 2, -1),
                  end: Alignment(1 - t * 2, 1),
                  colors: const [
                    Color(0xFF0A1F0C),
                    Color(0xFF15421B),
                    Color(0xFF1C5A25),
                    Color(0xFF0A1F0C),
                  ],
                ),
              ),
            ),
            CustomPaint(painter: _ParticlePainter(_particles)),
            Container(color: widget.overlayColor.withValues(alpha: 0.3)),
          ],
        );
      },
    );
  }
}

class _P {
  _P(this.rng) {
    reset(initial: true);
  }
  final Random rng;
  late double x, y, size, speed, opacity;

  void reset({bool initial = false}) {
    x = rng.nextDouble();
    y = initial ? rng.nextDouble() : 1.1;
    size = 1.5 + rng.nextDouble() * 3;
    speed = 0.02 + rng.nextDouble() * 0.04;
    opacity = 0.1 + rng.nextDouble() * 0.3;
  }

  void update(double dt) {
    y -= speed * dt * 3;
    if (y < -0.05) reset();
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);
  final List<_P> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      paint.color = const Color(0xFF7FE889).withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
