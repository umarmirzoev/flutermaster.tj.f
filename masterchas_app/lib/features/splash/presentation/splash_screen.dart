import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_flow_config.dart';
import '../../../core/providers/splash_completed_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Exact green from splash reference image.
const splashBackground = Color(0xFF57B55E);
const _splashIconColor = Colors.white;

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

  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final List<Animation<double>> _iconFadeAnimations;
  late final List<Animation<double>> _iconSlideAnimations;

  late final List<SplashIconConfig> _icons;
  bool _navigationStarted = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();

    _safetyTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) _finishSplash();
    });

    _textController = AnimationController(
      vsync: this,
      duration: _textDuration,
    );
    _iconsController = AnimationController(
      vsync: this,
      duration: _iconsDuration,
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _exitController = AnimationController(
      vsync: this,
      duration: _exitDuration,
    );

    _titleFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
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

  void _finishSplash() {
    if (_navigationStarted || !AppFlowConfig.postSplashFlowEnabled) return;
    _navigationStarted = true;
    _safetyTimer?.cancel();

    ref.read(splashCompletedProvider.notifier).complete();

    if (!mounted) return;

    final destination = AppFlowConfig.splashGoesToHome
        ? '/'
        : (ref.read(authProvider).isAuthenticated
            ? (ref.read(authProvider).isMaster
                ? '/master/cabinet/orders'
                : '/')
            : '/role');
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
    } catch (_) {
      // Auth init must never block leaving splash (e.g. secure storage on web).
    }

    unawaited(
      Future<void>.delayed(_iconsStart).then((_) async {
        if (mounted) await _iconsController.forward();
      }),
    );

    await Future<void>.delayed(_minSplashDuration);

    if (!mounted) return;

    final auth = ref.read(authProvider);
    final destination = auth.isAuthenticated
        ? (auth.isMaster ? '/master/cabinet/orders' : '/')
        : (AppFlowConfig.splashGoesToHome ? '/' : '/role');

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

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
            ...List.generate(_icons.length, (index) {
              final icon = _icons[index];
              return AnimatedBuilder(
                animation: Listenable.merge([
                  _iconFadeAnimations[index],
                  _iconSlideAnimations[index],
                ]),
                builder: (context, child) {
                  final fade = _iconFadeAnimations[index].value;
                  if (fade <= 0) return const SizedBox.shrink();

                  final dx = icon.alignment.x * size.width * 0.42;
                  final dy =
                      icon.alignment.y * size.height * 0.34 +
                      _iconSlideAnimations[index].value;

                  return Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(dx, dy),
                      child: Opacity(
                        opacity: fade * icon.finalOpacity,
                        child: IconTheme(
                          data: const IconThemeData(
                            color: Colors.white,
                            opacity: 1,
                          ),
                          child: icon.builder(icon.size),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            Center(
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleFade.value,
                    child: Transform.scale(
                      scale: _titleScale.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Master.tj',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'для клиентов',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _LoadingDots(controller: _dotsController),
                  ],
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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
          Transform.rotate(
            angle: -0.55,
            child: Icon(LucideIcons.wrench, size: size, color: _splashIconColor),
          ),
          Transform.rotate(
            angle: 0.55,
            child: Icon(LucideIcons.pencil, size: size * 0.92, color: _splashIconColor),
          ),
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
      width: size * 1.35,
      height: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.briefcase, size: size, color: _splashIconColor),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(LucideIcons.search, size: size * 0.45, color: _splashIconColor),
          ),
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
      width: size * 1.35,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.laptop, size: size, color: _splashIconColor),
          Positioned(
            top: size * 0.12,
            child: Icon(LucideIcons.code, size: size * 0.34, color: _splashIconColor),
          ),
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
      width: size * 1.35,
      height: size * 1.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.headphones, size: size, color: _splashIconColor),
          Positioned(
            bottom: 0,
            child: Icon(LucideIcons.smile, size: size * 0.42, color: _splashIconColor),
          ),
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
      width: size * 1.5,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Icon(LucideIcons.user, size: size * 0.72, color: _splashIconColor),
          Positioned(
            top: 0,
            child: SizedBox(
              width: size,
              height: size * 0.55,
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
      width: size * 1.35,
      height: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.smartphone, size: size, color: _splashIconColor),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(LucideIcons.settings, size: size * 0.42, color: _splashIconColor),
          ),
        ],
      ),
    );
  }
}
