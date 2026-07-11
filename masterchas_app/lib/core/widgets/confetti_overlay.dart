import 'dart:math';

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Confetti — праздничная анимация при успешном действии (заказ оформлен).
/// Лёгкая, без внешних зависимостей — рисуется на CustomPainter.
/// ═══════════════════════════════════════════════════════════════════════════

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.count = 60});

  final int count;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _Confetti {
  _Confetti(this.rng) {
    x = rng.nextDouble();
    y = -0.1 - rng.nextDouble() * 0.3;
    vx = (rng.nextDouble() - 0.5) * 0.4;
    vy = 0.3 + rng.nextDouble() * 0.5;
    size = 6 + rng.nextDouble() * 8;
    rotation = rng.nextDouble() * pi * 2;
    vrot = (rng.nextDouble() - 0.5) * 6;
    color = _colors[rng.nextInt(_colors.length)];
  }

  final Random rng;
  late double x, y, vx, vy, size, rotation, vrot;
  late Color color;

  static const _colors = [
    Color(0xFF57B55E),
    Color(0xFF6DD674),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFFBBF24),
  ];

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 0.3 * dt;
    rotation += vrot * dt;
  }
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _pieces = <_Confetti>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.count; i++) {
      _pieces.add(_Confetti(_rng));
    }
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _c.addListener(() {
      for (final p in _pieces) {
        p.update(0.016);
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(_pieces, opacity: 1 - _c.value * 0.3),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, {this.opacity = 1});
  final List<_Confetti> pieces;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      if (p.y < -0.1 || p.y > 1.15) continue;
      paint.color = p.color.withValues(alpha: opacity.clamp(0, 1));
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
