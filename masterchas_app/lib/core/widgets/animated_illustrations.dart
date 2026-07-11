import 'dart:math';

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Анимированные иллюстрации (рисуются кодом, не фото).
/// AiRobot — парящий робот с мигающими глазами и пульсирующим свечением.
/// CleanerIllustration — стилизованная сцена уборки/ремонта.
/// ═══════════════════════════════════════════════════════════════════════════

class AiRobotIllustration extends StatefulWidget {
  const AiRobotIllustration({super.key, this.size = 100});

  final double size;

  @override
  State<AiRobotIllustration> createState() => _AiRobotIllustrationState();
}

class _AiRobotIllustrationState extends State<AiRobotIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _blink]),
      builder: (context, _) {
        final floatY = sin(_float.value * pi) * 6;
        // blink: eyes closed briefly near the end of the cycle
        final phase = _blink.value;
        final eyeOpen = (phase > 0.92 && phase < 0.97) ? 0.15 : 1.0;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RobotPainter(eyeOpen: eyeOpen, glow: _float.value),
          ),
        );
      },
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({required this.eyeOpen, required this.glow});
  final double eyeOpen;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Glow behind head
    final glowPaint = Paint()
      ..color = const Color(0xFF6DD674).withValues(alpha: 0.25 + glow * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, h * 0.42), w * 0.34, glowPaint);

    // Antenna
    final antennaPaint = Paint()
      ..color = const Color(0xFFCFF7D4)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, h * 0.16), Offset(cx, h * 0.08), antennaPaint);
    canvas.drawCircle(
      Offset(cx, h * 0.06),
      w * 0.04,
      Paint()..color = const Color(0xFF7FE889),
    );

    // Head (rounded rect)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.42), width: w * 0.62, height: h * 0.5),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(
      headRect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4FFF6), Color(0xFFDCF5DF)],
      ).createShader(headRect.outerRect),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = const Color(0xFF57B55E).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015,
    );

    // Face screen (dark rounded rect)
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.42), width: w * 0.44, height: h * 0.3),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(faceRect, Paint()..color = const Color(0xFF12241B));

    // Eyes (glowing green, blink via height scale)
    final eyePaint = Paint()..color = const Color(0xFF6DD674);
    final eyeGlow = Paint()
      ..color = const Color(0xFF6DD674).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final eyeW = w * 0.08;
    final eyeH = h * 0.09 * eyeOpen;
    for (final dx in [-w * 0.1, w * 0.1]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + dx, h * 0.4), width: eyeW, height: eyeH),
        Radius.circular(eyeW / 2),
      );
      canvas.drawRRect(r, eyeGlow);
      canvas.drawRRect(r, eyePaint);
    }

    // Smile (small arc)
    final smilePaint = Paint()
      ..color = const Color(0xFF6DD674)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(cx - w * 0.06, h * 0.5);
    smilePath.quadraticBezierTo(cx, h * 0.55, cx + w * 0.06, h * 0.5);
    canvas.drawPath(smilePath, smilePaint);

    // Body hint (small rounded shoulders)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.82), width: w * 0.5, height: h * 0.28),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE4F7E6), Color(0xFFC5EDCA)],
      ).createShader(bodyRect.outerRect),
    );
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.eyeOpen != eyeOpen || old.glow != glow;
}

/// Simple animated tool/spark illustration for the discount banner.
class ToolSparkIllustration extends StatefulWidget {
  const ToolSparkIllustration({super.key, this.size = 90});

  final double size;

  @override
  State<ToolSparkIllustration> createState() => _ToolSparkIllustrationState();
}

class _ToolSparkIllustrationState extends State<ToolSparkIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ToolSparkPainter(_c.value),
        );
      },
    );
  }
}

class _ToolSparkPainter extends CustomPainter {
  _ToolSparkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final cy = size.height / 2;

    // Rotating sparkle ring
    for (int i = 0; i < 6; i++) {
      final angle = t * 2 * pi + i * pi / 3;
      final r = w * 0.42;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      final pulse = (sin(t * 2 * pi + i) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        w * 0.03 * (0.5 + pulse),
        Paint()..color = Colors.white.withValues(alpha: 0.4 + pulse * 0.4),
      );
    }

    // Center white circle with wrench
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.26,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    final iconPaint = Paint()
      ..color = const Color(0xFF57B55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // simple wrench: diagonal line + open end
    canvas.drawLine(
      Offset(cx - w * 0.1, cy + w * 0.1),
      Offset(cx + w * 0.08, cy - w * 0.08),
      iconPaint,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.1, cy - w * 0.1),
      w * 0.06,
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(_ToolSparkPainter old) => old.t != t;
}
