import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Набор «живых» анимаций для главной: появление блоков, ховер, блик, парение.

/// Плавное появление: прозрачность + подъём снизу + лёгкое увеличение.
/// Срабатывает один раз при первом показе.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.offsetY = 28,
    this.offsetX = 0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double offsetX;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(widget.offsetX * (1 - v), widget.offsetY * (1 - v)),
            child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
          ),
        );
      },
    );
  }
}

/// Ховер (мышь) и нажатие (палец): карточка приподнимается, увеличивается
/// и светится; при нажатии слегка «вдавливается». Нажатия не перехватывает.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.scale = 1.03,
    this.lift = 4,
    this.radius = 18,
    this.glowColor,
  });

  final Widget child;
  final double scale;
  final double lift;
  final double radius;
  final Color? glowColor;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? const Color(0xFF57B55E);
    final scale = _pressed ? 0.97 : (_hover ? widget.scale : 1.0);
    final dy = _pressed ? 0.0 : (_hover ? -widget.lift : 0.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, dy)
            ..scale(scale),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.28),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Блик, который время от времени пробегает по карточке (для градиентных плашек).
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.radius = 18,
    this.period = const Duration(milliseconds: 3600),
    this.delay = Duration.zero,
  });

  final Widget child;
  final double radius;
  final Duration period;
  final Duration delay;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  // Блик идёт в первые 35% цикла, остальное время — пауза.
                  final t = (_c.value / 0.35).clamp(0.0, 1.0);
                  if (t >= 1.0) return const SizedBox.shrink();
                  return LayoutBuilder(
                    builder: (context, box) {
                      final w = box.maxWidth;
                      final x = -w * 0.6 + (w * 2.2) * Curves.easeInOut.transform(t);
                      return Transform.translate(
                        offset: Offset(x, 0),
                        child: Transform.rotate(
                          angle: -math.pi / 8,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                            width: w * 0.35,
                            height: box.maxHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.28),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Мягкое «парение» вверх-вниз (для иконок).
class FloatY extends StatefulWidget {
  const FloatY({
    super.key,
    required this.child,
    this.amplitude = 3,
    this.period = const Duration(milliseconds: 2400),
    this.phase = 0,
  });

  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amplitude,
        ),
        child: child,
      ),
    );
  }
}

/// Пульсирующее кольцо вокруг круглой кнопки.
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    required this.child,
    required this.color,
    this.size = 56,
  });

  final Widget child;
  final Color color;
  final double size;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              return IgnorePointer(
                child: Container(
                  width: widget.size + 22 * v,
                  height: widget.size + 22 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.30 * (1 - v)),
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Плавный переход между экранами: новая страница проявляется,
/// выезжает снизу и чуть увеличивается; фото мастера «перелетает» через Hero.
class SmoothRoute<T> extends PageRouteBuilder<T> {
  SmoothRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
                child: ScaleTransition(
                  scale: Tween(begin: 0.97, end: 1.0).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Пульсирующая точка «онлайн».
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color = Colors.white, this.size = 7});

  final Color color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.4,
      height: widget.size * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * (1 + 1.4 * _c.value),
              height: widget.size * (1 + 1.4 * _c.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
