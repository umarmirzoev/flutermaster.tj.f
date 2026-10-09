import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/motion.dart';
import '../providers/auth_provider.dart';
import '../utils/phone_formatter.dart';

const _authGreen = Color(0xFF57B55E);
const _hintGrey = Color(0xFF9CA3AF);
const _bodyGrey = Color(0xFF6B7280);
const _titleColor = Color(0xFF111827);

// ─── Floating service icon ──────────────────────────────────────────────────
class _FloatingIcon {
  _FloatingIcon(this.rng) { reset(initial: true); }

  final Random rng;
  late double x, y, speed, size, opacity, phase;
  late IconData icon;

  static const _icons = [
    LucideIcons.wrench, LucideIcons.hammer, LucideIcons.brush,
    LucideIcons.droplet, LucideIcons.zap, LucideIcons.paint_roller,
    LucideIcons.settings, LucideIcons.laptop, LucideIcons.smartphone,
    LucideIcons.headphones, LucideIcons.camera, LucideIcons.code,
  ];

  void reset({bool initial = false}) {
    x = rng.nextDouble();
    y = initial ? rng.nextDouble() : 1.0 + rng.nextDouble() * 0.1;
    speed = 0.03 + rng.nextDouble() * 0.05;
    size = 16 + rng.nextDouble() * 14;
    opacity = 0.06 + rng.nextDouble() * 0.1;
    phase = rng.nextDouble() * pi * 2;
    icon = _icons[rng.nextInt(_icons.length)];
  }

  void update(double dt) {
    y -= speed * dt;
    phase += dt * 2;
    if (y < -0.05) reset();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  bool _phoneFocused = false;

  late final AnimationController _bgAnimController;
  late final AnimationController _formAnimController;
  late final Animation<double> _formSlide;
  late final Animation<double> _formFade;

  final _floatingIcons = <_FloatingIcon>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _restoreSavedPhone();

    // Floating icons
    for (int i = 0; i < 15; i++) {
      _floatingIcons.add(_FloatingIcon(_rng));
    }

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _bgAnimController.addListener(() {
      for (final icon in _floatingIcons) {
        icon.update(0.016);
      }
    });

    // Form entrance animation
    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _formAnimController, curve: Curves.easeOutCubic),
    );
    _formFade = CurvedAnimation(parent: _formAnimController, curve: Curves.easeOut);
    _formAnimController.forward();
  }

  Future<void> _restoreSavedPhone() async {
    final saved = await ref.read(authProvider.notifier).readSavedPhone();
    final digits = localDigitsFromPhone(saved);
    if (!mounted || digits.isEmpty) return;
    _phoneController.text = digits;
    setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bgAnimController.dispose();
    _formAnimController.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      !_isSubmitting && _agreedToTerms && _phoneController.text.trim().length >= 9;

  Future<void> _signInAsGuest() async {
    await ref.read(authProvider.notifier).signInAsGuest();
    if (mounted) context.go('/');
  }

  Future<void> _onConfirm() async {
    if (!_canConfirm) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).signInWithPhone(_phoneController.text.trim());
      if (mounted) {
        final role = GoRouterState.of(context).uri.queryParameters['role'] ?? 'Client';
        if (role == 'Master') {
          context.push('/login/master-code', extra: {'phone': _phoneController.text.trim()});
        } else {
          context.push('/login/password', extra: {'phone': _phoneController.text.trim(), 'role': role});
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _phoneController.text.trim().length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Плавающие иконки услуг на фоне ──
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _bgAnimController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FloatingIconsPainter(_floatingIcons, _authGreen),
                  );
                },
              ),
            ),
          ),

          // ── Мягкие цветные пятна ──
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: FloatY(
                amplitude: 10,
                period: const Duration(milliseconds: 5200),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_authGreen.withValues(alpha: 0.18), _authGreen.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: IgnorePointer(
              child: FloatY(
                amplitude: 8,
                phase: 0.5,
                period: const Duration(milliseconds: 6000),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF3B82F6).withValues(alpha: 0.10), const Color(0xFF3B82F6).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Контент ──
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Логотип ──
                      Reveal(
                        offsetY: -16,
                        child: Center(
                          child: FloatY(
                            amplitude: 4,
                            child: PulseRing(
                              color: _authGreen,
                              size: 76,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF6DD674), Color(0xFF2E9E4F)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: _authGreen.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: const Icon(LucideIcons.wrench, size: 34, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        delay: const Duration(milliseconds: 80),
                        offsetY: 10,
                        child: Center(
                          child: Text(
                            'Master.tj',
                            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w900, color: _authGreen, letterSpacing: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Reveal(
                        delay: const Duration(milliseconds: 160),
                        child: Text(
                          'Добро пожаловать! 👋',
                          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: _titleColor, height: 1.15),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Reveal(
                        delay: const Duration(milliseconds: 220),
                        child: Text(
                          'Введите номер телефона, чтобы войти или создать аккаунт',
                          style: GoogleFonts.manrope(fontSize: 15, color: _bodyGrey, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // ── Телефон ──
                      Reveal(
                        delay: const Duration(milliseconds: 300),
                        child: Focus(
                          onFocusChange: (f) => setState(() => _phoneFocused = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _authGreen.withValues(alpha: _phoneFocused ? 0.25 : 0.08),
                                  blurRadius: _phoneFocused ? 26 : 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _PhoneField(
                              controller: _phoneController,
                              complete: digits >= 9,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Прогресс ввода номера
                      Reveal(
                        delay: const Duration(milliseconds: 340),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: (digits / 9).clamp(0, 1).toDouble()),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 3,
                              backgroundColor: const Color(0xFFF1F5F2),
                              color: _authGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Reveal(
                        delay: const Duration(milliseconds: 380),
                        child: _TermsCheckbox(
                          value: _agreedToTerms,
                          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Кнопка ──
                      Reveal(
                        delay: const Duration(milliseconds: 440),
                        child: _ConfirmButton(
                          enabled: _canConfirm,
                          loading: _isSubmitting,
                          onTap: _onConfirm,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Reveal(delay: const Duration(milliseconds: 500), child: const _OrDivider()),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Reveal(
                              delay: const Duration(milliseconds: 560),
                              offsetX: -20,
                              offsetY: 0,
                              child: _AltLoginCard(
                                icon: LucideIcons.key_round,
                                label: 'Войти через\nлогин и пароль',
                                tint: _authGreen,
                                onTap: () => context.push('/login/password'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Reveal(
                              delay: const Duration(milliseconds: 620),
                              offsetX: 20,
                              offsetY: 0,
                              child: _AltLoginCard(
                                icon: LucideIcons.user,
                                label: 'Войти\nкак гость',
                                tint: const Color(0xFF3B82F6),
                                onTap: _signInAsGuest,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Reveal(
                        delay: const Duration(milliseconds: 700),
                        child: const _TrustRow(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Кнопка «Подтвердить» ─────────────────────────────────────────────────────
class _ConfirmButton extends StatefulWidget {
  const _ConfirmButton({required this.enabled, required this.loading, required this.onTap});

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final button = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: enabled
                ? const [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)]
                : [_authGreen.withValues(alpha: 0.32), _authGreen.withValues(alpha: 0.28)],
          ),
          boxShadow: enabled
              ? [BoxShadow(color: _authGreen.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 7))]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: widget.loading
                    ? const SizedBox(
                        key: ValueKey('l'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        key: const ValueKey('t'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Продолжить',
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          AnimatedSlide(
                            offset: Offset(enabled ? 0 : -0.3, 0),
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(LucideIcons.arrow_right, size: 20, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!enabled) return button;
    return HoverLift(
      radius: 16,
      scale: 1.02,
      glowColor: _authGreen,
      child: ShineSweep(radius: 16, child: button),
    );
  }
}

// ─── Строка доверия ───────────────────────────────────────────────────────────
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (LucideIcons.shield_check, 'Безопасно'),
      (LucideIcons.badge_check, 'Проверенные\nмастера'),
      (LucideIcons.clock, 'Поддержка\n24/7'),
    ];
    return Row(
      children: [
        for (final (i, it) in items.indexed)
          Expanded(
            child: FloatY(
              amplitude: 2,
              phase: i * 0.33,
              child: Column(
                children: [
                  Icon(it.$1, size: 18, color: _authGreen),
                  const SizedBox(height: 4),
                  Text(
                    it.$2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: _bodyGrey, height: 1.25),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Floating icons painter ───────────────────────────────────────────────────
class _FloatingIconsPainter extends CustomPainter {
  _FloatingIconsPainter(this.icons, this.color);
  final List<_FloatingIcon> icons;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final icon in icons) {
      final x = icon.x * size.width + sin(icon.phase) * 12;
      final y = icon.y * size.height;
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.icon.codePoint),
          style: TextStyle(
            fontSize: icon.size,
            fontFamily: icon.icon.fontFamily,
            package: icon.icon.fontPackage,
            color: color.withValues(alpha: icon.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(sin(icon.phase * 0.5) * 0.25);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      tp.dispose();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.onChanged, this.complete = false});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      onChanged: onChanged,
      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w500, color: _titleColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _authGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🇹🇯 +992',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),
              ),
              Container(width: 1, height: 22, margin: const EdgeInsets.only(left: 12), color: const Color(0xFFE5E7EB)),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
          child: complete
              ? const Padding(
                  key: ValueKey('ok'),
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(LucideIcons.circle_check, color: _authGreen, size: 22),
                )
              : const SizedBox(key: ValueKey('no'), width: 0),
        ),
        hintText: '900 00 00 00',
        hintStyle: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w400, color: _hintGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _authGreen.withValues(alpha: 0.35), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _authGreen, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _authGreen.withValues(alpha: 0.35), width: 1.5),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24, height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _authGreen,
            side: BorderSide(color: value ? _authGreen : _authGreen.withValues(alpha: 0.7), width: 1.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, color: _bodyGrey, height: 1.45),
                children: [
                  const TextSpan(text: 'Я согласен с '),
                  TextSpan(
                    text: 'пользовательским соглашением',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: _authGreen),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Пользовательское соглашение', style: GoogleFonts.manrope()), behavior: SnackBarBehavior.floating),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('или', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: _hintGrey)),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
      ],
    );
  }
}

class _AltLoginCard extends StatelessWidget {
  const _AltLoginCard({required this.icon, required this.label, required this.onTap, this.tint = _authGreen});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 18,
      glowColor: tint,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 118,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tint.withValues(alpha: 0.18)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, tint.withValues(alpha: 0.06)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatY(
                  amplitude: 3,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tint.withValues(alpha: 0.2), tint.withValues(alpha: 0.08)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 22, color: tint),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: _titleColor, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
