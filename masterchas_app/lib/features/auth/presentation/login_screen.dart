import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Animated background with floating icons ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _FloatingIconsPainter(_floatingIcons, _authGreen),
                );
              },
            ),
          ),

          // ── Top gradient accent ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _authGreen.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: AnimatedBuilder(
                animation: _formAnimController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _formSlide.value),
                    child: Opacity(opacity: _formFade.value, child: child),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo pill ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _authGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _authGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: _authGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.wrench, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Master.tj',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _authGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Добро пожаловать!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Введите номер телефона для входа',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _bodyGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Phone field with enhanced design ──
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _authGreen.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _PhoneField(
                        controller: _phoneController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _TermsCheckbox(
                      value: _agreedToTerms,
                      onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                    ),
                    const SizedBox(height: 24),

                    // ── Enhanced button ──
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _canConfirm
                            ? const LinearGradient(
                                colors: [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)],
                              )
                            : null,
                        color: _canConfirm ? null : _authGreen.withValues(alpha: 0.3),
                        boxShadow: _canConfirm
                            ? [
                                BoxShadow(
                                  color: _authGreen.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _canConfirm ? _onConfirm : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSubmitting)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  const Icon(LucideIcons.log_in, size: 20, color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  _isSubmitting ? 'Вход...' : 'Подтвердить',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _OrDivider(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _AltLoginCard(
                            icon: LucideIcons.log_in,
                            label: 'Войти через\nлогин и пароль',
                            onTap: () => context.push('/login/password'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AltLoginCard(
                            icon: LucideIcons.user,
                            label: 'Войти\nкак гость',
                            onTap: _signInAsGuest,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    final paint = Paint();
    for (final icon in icons) {
      final x = icon.x * size.width + sin(icon.phase) * 12;
      final y = icon.y * size.height;
      paint.color = color.withValues(alpha: icon.opacity);
      // Draw as circles (simple representation of floating icons)
      canvas.drawCircle(Offset(x, y), icon.size / 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: _titleColor),
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
                  style: GoogleFonts.inter(
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
        hintText: '900 00 00 00',
        hintStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w400, color: _hintGrey),
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
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: _bodyGrey, height: 1.45),
                children: [
                  const TextSpan(text: 'Я согласен с '),
                  TextSpan(
                    text: 'пользовательским соглашением',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _authGreen),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Пользовательское соглашение', style: GoogleFonts.inter()), behavior: SnackBarBehavior.floating),
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
            child: Text('или', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _hintGrey)),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
      ],
    );
  }
}

class _AltLoginCard extends StatelessWidget {
  const _AltLoginCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 118,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF9FAFB),
                _authGreen.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _authGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _authGreen),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _titleColor, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
