import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_flow_config.dart';
import '../../../core/providers/home_tab_provider.dart';
import '../../../core/providers/splash_completed_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Exact green from splash reference image.
const splashBackground = Color(0xFF57B55E);
const _splashIconColor = Colors.white;

// ─── Floating particle data ───────────────────────────────────────────────
class _Particle {
  _Particle({required this.rng}) {
    reset(initial: true);
  }

  final Random rng;
  late double x, y, size, speed, opacity;

  void reset({bool initial = false}) {
    x = rng.nextDouble();
    y = initial ? rng.nextDouble() : 1.0 + rng.nextDouble() * 0.2;
    size = 2 + rng.nextDouble() * 4;
    speed = 0.15 + rng.nextDouble() * 0.35;
    opacity = 0.15 + rng.nextDouble() * 0.4;
  }

  void update(double dt) {
    y -= speed * dt;
    x += sin(y * 6) * 0.001;
    if (y < -0.05) reset();
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      paint.color = Colors.white.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─── Splash icon config ───────────────────────────────────────────────────
class SplashIconConfig {
  const SplashIconConfig({
    required this.alignment,
    required this.finalOpacity,
    required this.builder,
    this.size = 34,
  });

  final Alignment alignment;
  final double finalOpacity;
  final double size;
  final Widget Function(double size) builder;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _textDuration = Duration(milliseconds: 600);
  static const _iconsStart = Duration(milliseconds: 500);
  static const _iconsDuration = Duration(milliseconds: 2000);
  static const _minSplashDuration = Duration(milliseconds: 4200);
  static const _exitDuration = Duration(milliseconds: 700);
  static const _staggerStep = 0.085;
  static const _iconAnimSpan = 0.32;

  late final AnimationController _textController;
  late final AnimationController _iconsController;
  late final AnimationController _dotsController;
  late final AnimationController _exitController;
  late final AnimationController _gradientController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;
  late final AnimationController _orbitController;

  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final List<Animation<double>> _iconFadeAnimations;
  late final List<Animation<double>> _iconSlideAnimations;

  late final List<SplashIconConfig> _icons;
  bool _navigationStarted = false;
  Timer? _safetyTimer;

  // Particles
  final _particles = <_Particle>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();

    // Create particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(rng: _rng));
    }

    _safetyTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) _finishSplash();
    });

    _textController = AnimationController(vsync: this, duration: _textDuration);
    _iconsController = AnimationController(vsync: this, duration: _iconsDuration);
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _exitController = AnimationController(vsync: this, duration: _exitDuration);

    // Gradient animation — shifts colors smoothly
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // Pulse glow behind logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Particle ticker
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleController.addListener(_updateParticles);

    // Медленное вращение кольца иконок вокруг логотипа
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();

    _titleFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _titleScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );

    _icons = _buildIconConfigs()
      ..sort((a, b) => a.alignment.y.compareTo(b.alignment.y));

    _iconFadeAnimations = List.generate(_icons.length, (index) {
      final start = index * _staggerStep;
      final end = (start + _iconAnimSpan).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _iconsController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _iconSlideAnimations = List.generate(_icons.length, (index) {
      final start = index * _staggerStep;
      final end = (start + _iconAnimSpan).clamp(0.0, 1.0);
      return Tween<double>(begin: -18, end: 0).animate(
        CurvedAnimation(
          parent: _iconsController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _textController.forward();
    unawaited(_startBootstrap());
  }

  double _lastTime = 0;
  void _updateParticles() {
    final now = _particleController.value;
    final dt = (now - _lastTime).abs();
    _lastTime = now;
    for (final p in _particles) {
      p.update(dt * 2);
    }
  }

  void _finishSplash() {
    if (_navigationStarted || !AppFlowConfig.postSplashFlowEnabled) return;
    _navigationStarted = true;
    _safetyTimer?.cancel();

    ref.read(splashCompletedProvider.notifier).complete();

    if (!mounted) return;

    final destination = AppFlowConfig.splashGoesToHome
        ? '/'
        : (ref.read(authProvider).isAuthenticated ? '/' : '/role');
    if (ref.read(authProvider).isMaster) {
      ref.read(homeTabProvider.notifier).openProfile();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(destination);
    });
  }

  Future<void> _startBootstrap() async {
    try {
      await ref
          .read(authProvider.notifier)
          .initializeAuth(restoreSession: true)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    unawaited(
      Future<void>.delayed(_iconsStart).then((_) async {
        if (mounted) await _iconsController.forward();
      }),
    );

    await Future<void>.delayed(_minSplashDuration);

    if (!mounted) return;

    final auth = ref.read(authProvider);
    final destination =
        auth.isAuthenticated ? '/' : (AppFlowConfig.splashGoesToHome ? '/' : '/role');
    if (auth.isMaster) {
      ref.read(homeTabProvider.notifier).openProfile();
    }

    unawaited(_exitController.forward());
    _navigationStarted = true;
    _safetyTimer?.cancel();
    ref.read(splashCompletedProvider.notifier).complete();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(destination);
    });
  }

  List<SplashIconConfig> _buildIconConfigs() {
    return [
      SplashIconConfig(
        alignment: const Alignment(0, -0.78),
        finalOpacity: 0.72,
        size: 38,
        builder: (size) => _CrossedTools(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(-0.58, -0.58),
        finalOpacity: 0.68,
        builder: (size) => _BriefcaseSearch(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(0.58, -0.58),
        finalOpacity: 0.68,
        builder: (size) => _BriefcaseSearch(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(0, -0.48),
        finalOpacity: 0.78,
        size: 30,
        builder: (size) => Icon(LucideIcons.brush, size: size, color: _splashIconColor),
      ),
      SplashIconConfig(
        alignment: const Alignment(-0.68, -0.12),
        finalOpacity: 0.95,
        size: 36,
        builder: (size) => Icon(LucideIcons.hammer, size: size, color: _splashIconColor),
      ),
      SplashIconConfig(
        alignment: const Alignment(0.68, -0.08),
        finalOpacity: 0.95,
        size: 36,
        builder: (size) => _LaptopCode(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(-0.62, 0.34),
        finalOpacity: 0.88,
        size: 34,
        builder: (size) => _SupportHeadset(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(0, 0.44),
        finalOpacity: 0.92,
        size: 34,
        builder: (size) => _DeskCoder(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(0.62, 0.34),
        finalOpacity: 0.88,
        size: 34,
        builder: (size) => _PhoneSettings(size: size),
      ),
      SplashIconConfig(
        alignment: const Alignment(-0.48, 0.74),
        finalOpacity: 0.68,
        size: 32,
        builder: (size) => Icon(LucideIcons.users, size: size, color: _splashIconColor),
      ),
      SplashIconConfig(
        alignment: const Alignment(0, 0.78),
        finalOpacity: 0.7,
        size: 30,
        builder: (size) => Transform.rotate(
          angle: -0.45,
          child: Icon(LucideIcons.hammer, size: size, color: _splashIconColor),
        ),
      ),
      SplashIconConfig(
        alignment: const Alignment(0.48, 0.74),
        finalOpacity: 0.68,
        size: 32,
        builder: (size) => Icon(LucideIcons.camera, size: size, color: _splashIconColor),
      ),
    ];
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _textController.dispose();
    _iconsController.dispose();
    _dotsController.dispose();
    _exitController.dispose();
    _gradientController.dispose();
    _pulseController.dispose();
    _particleController.removeListener(_updateParticles);
    _particleController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: splashBackground,
      body: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
        ),
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Animated gradient background ──
                AnimatedBuilder(
                  animation: _gradientController,
                  builder: (context, _) {
                    final t = _gradientController.value;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            -0.3 + t * 0.6,
                            -0.5 + t * 1.0,
                          ),
                          radius: 1.4 + t * 0.4,
                          colors: [
                            const Color(0xFF6DD674).withValues(alpha: 0.6),
                            splashBackground,
                            const Color(0xFF3A8F42),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ── Floating particles ──
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) =>
                      CustomPaint(painter: _ParticlePainter(_particles)),
                ),

                // ── Кольцо иконок услуг, медленно вращается вокруг логотипа ──
                LayoutBuilder(
                  builder: (context, box) {
                    final radius = min(box.maxWidth, box.maxHeight) * 0.36;
                    return AnimatedBuilder(
                      animation: Listenable.merge([_orbitController, _iconsController, _pulseController]),
                      builder: (context, _) {
                        final rot = _orbitController.value * 2 * pi;
                        return Stack(
                          children: List.generate(_icons.length, (index) {
                            final icon = _icons[index];
                            final appear = _iconFadeAnimations[index].value;
                            if (appear <= 0) return const SizedBox.shrink();
                            final angle = rot + index * 2 * pi / _icons.length;
                            final bob = sin(_pulseController.value * pi + index) * 4;
                            final r = radius * (0.7 + 0.3 * appear) + (index.isEven ? 0 : radius * 0.12);
                            final dx = cos(angle) * r;
                            final dy = sin(angle) * r * 1.15 + bob;
                            final bubble = 52.0 + (index % 3) * 6;
                            return Positioned(
                              left: box.maxWidth / 2 + dx - bubble / 2,
                              top: box.maxHeight / 2 + dy - bubble / 2,
                              child: Opacity(
                                opacity: appear.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.4 + 0.6 * Curves.easeOutBack.transform(appear.clamp(0.0, 1.0)),
                                  child: Container(
                                    width: bubble,
                                    height: bubble,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Opacity(
                                      opacity: icon.finalOpacity.clamp(0.8, 1.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: icon.builder(bubble * 0.46),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    );
                  },
                ),

                // ── Логотип в центре ──
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_textController, _exitController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _titleFade.value,
                        child: Transform.scale(
                          scale: _titleScale.value * (1 + _exitController.value * 0.15),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulse = _pulseController.value;
                            return Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.25 + pulse * 0.2),
                                    blurRadius: 30 + pulse * 30,
                                    spreadRadius: 4 + pulse * 10,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: sin(pulse * pi) * 0.12,
                                child: child,
                              ),
                            );
                          },
                          child: const Icon(LucideIcons.wrench, size: 44, color: splashBackground),
                        ),
                        const SizedBox(height: 18),
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE8FFE9), Colors.white],
                          ).createShader(rect),
                          child: Text(
                            'Master.tj',
                            style: GoogleFonts.manrope(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 4)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            'Мастера рядом · 24/7',
                            style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _LoadingDots(controller: _dotsController),
                      ],
                    ),
                  ),
                ),

                // ── Bottom tagline ──
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _titleFade.value * 0.6,
                        child: child,
                      );
                    },
                    child: Text(
                      'Найди мастера • Закажи услугу • Купи инструмент',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (controller.value + index / 3) % 1.0;
            final pulse = phase <= 0.5
                ? Curves.easeInOut.transform(phase * 2)
                : Curves.easeInOut.transform(2 - phase * 2);

            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
              child: Transform.scale(
                scale: 1 + pulse * 0.4,
                child: Opacity(
                  opacity: 0.35 + pulse * 0.65,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4 * pulse),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Icon composites (unchanged from original) ──────────────────────────────

class _CrossedTools extends StatelessWidget {
  const _CrossedTools({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.4,
      height: size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(angle: -0.55, child: Icon(LucideIcons.wrench, size: size, color: _splashIconColor)),
          Transform.rotate(angle: 0.55, child: Icon(LucideIcons.pencil, size: size * 0.92, color: _splashIconColor)),
        ],
      ),
    );
  }
}

class _BriefcaseSearch extends StatelessWidget {
  const _BriefcaseSearch({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35, height: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.briefcase, size: size, color: _splashIconColor),
          Positioned(right: 0, bottom: 0, child: Icon(LucideIcons.search, size: size * 0.45, color: _splashIconColor)),
        ],
      ),
    );
  }
}

class _LaptopCode extends StatelessWidget {
  const _LaptopCode({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35, height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.laptop, size: size, color: _splashIconColor),
          Positioned(top: size * 0.12, child: Icon(LucideIcons.code, size: size * 0.34, color: _splashIconColor)),
        ],
      ),
    );
  }
}

class _SupportHeadset extends StatelessWidget {
  const _SupportHeadset({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35, height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.headphones, size: size, color: _splashIconColor),
          Positioned(bottom: 0, child: Icon(LucideIcons.face_grinning, size: size * 0.42, color: _splashIconColor)),
        ],
      ),
    );
  }
}

class _DeskCoder extends StatelessWidget {
  const _DeskCoder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5, height: size * 1.25,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Icon(LucideIcons.user, size: size * 0.72, color: _splashIconColor),
          Positioned(
            top: 0,
            child: SizedBox(
              width: size, height: size * 0.55,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(LucideIcons.monitor, size: size * 0.72, color: _splashIconColor),
                  Icon(LucideIcons.code, size: size * 0.24, color: _splashIconColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneSettings extends StatelessWidget {
  const _PhoneSettings({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35, height: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.smartphone, size: size, color: _splashIconColor),
          Positioned(right: 0, bottom: 0, child: Icon(LucideIcons.settings, size: size * 0.42, color: _splashIconColor)),
        ],
      ),
    );
  }
}
