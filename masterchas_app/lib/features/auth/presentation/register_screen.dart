import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../providers/auth_provider.dart';
import '../utils/phone_formatter.dart';

const _authGreen = Color(0xFF57B55E);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.initialPhone, this.role = 'Client'});

  final String? initialPhone;
  final String role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;
  String? _error;

  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  // Password strength
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.length >= 12) s += 0.15;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.2;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.2;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s += 0.2;
    return s.clamp(0, 1);
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.3) return Colors.red;
    if (_passwordStrength < 0.6) return Colors.orange;
    if (_passwordStrength < 0.8) return Colors.yellow.shade700;
    return _authGreen;
  }

  String get _strengthLabel {
    if (_passwordStrength < 0.3) return 'Слабый';
    if (_passwordStrength < 0.6) return 'Средний';
    if (_passwordStrength < 0.8) return 'Хороший';
    return 'Отличный';
  }

  @override
  void initState() {
    super.initState();
    final digits = localDigitsFromPhone(widget.initialPhone);
    _phoneController = TextEditingController(text: digits);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    _entryController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _phoneController.text.trim().length >= 9 &&
      _passwordController.text.length >= 8 &&
      _passwordController.text == _confirmController.text;

  bool get _passwordsMatch =>
      _confirmController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final phoneDigits = _phoneController.text.trim();
    debugPrint('REGISTER: starting, digits=$phoneDigits role=${widget.role}');
    setState(() { _isSubmitting = true; _error = null; });

    try {
      await ref.read(authProvider.notifier).registerWithPassword(
            phone: phoneDigits,
            password: _passwordController.text.trim(),
            role: widget.role,
          );
      debugPrint('REGISTER: success');
      if (!mounted) return;
      if (widget.role == 'Master') {
        context.go('/master/register');
      } else {
        context.go('/');
      }
    } catch (e, st) {
      debugPrint('REGISTER: ERROR $e\n$st');
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? showMatch,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _authGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscure : false,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFFD1D5DB)),
          prefixText: prefixText,
          prefixStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _authGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: _authGreen),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? LucideIcons.eye_off : LucideIcons.eye,
                    size: 20,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : showMatch == true
                  ? Container(
                      margin: const EdgeInsets.all(12),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _passwordsMatch ? _authGreen : Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _passwordsMatch ? LucideIcons.check : LucideIcons.x,
                        size: 14,
                        color: _passwordsMatch ? Colors.white : Colors.red,
                      ),
                    )
                  : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _authGreen, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: Stack(
        children: [
          // ── Gradient background accent ──
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _authGreen.withValues(alpha: 0.12),
                    _authGreen.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _authGreen.withValues(alpha: 0.08),
                    _authGreen.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(LucideIcons.arrow_left, color: _authGreen),
                      ),
                      Text(
                        'Регистрация',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                      const Spacer(),
                      // Step indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _authGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.shield_check, size: 14, color: _authGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Безопасно',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _authGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SlideTransition(
                    position: _entrySlide,
                    child: FadeTransition(
                      opacity: _entryFade,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Создайте аккаунт',
                              style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Заполните данные для быстрой регистрации',
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 28),
                            _buildField(
                              controller: _phoneController,
                              label: 'Номер телефона',
                              hint: '900 00 00 00',
                              icon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                              prefixText: '+992 ',
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _passwordController,
                              label: 'Пароль',
                              hint: 'Минимум 8 символов',
                              icon: LucideIcons.lock,
                              isPassword: true,
                            ),

                            // ── Password strength indicator ──
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        backgroundColor: const Color(0xFFE5E7EB),
                                        valueColor: AlwaysStoppedAnimation(_strengthColor),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _strengthLabel,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _strengthColor),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _confirmController,
                              label: 'Повторите пароль',
                              hint: 'Повторите пароль',
                              icon: LucideIcons.lock_keyhole,
                              showMatch: _confirmController.text.isNotEmpty,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.alert_circle, size: 18, color: Colors.red.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),

                            // ── Submit button ──
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: _canSubmit
                                    ? const LinearGradient(colors: [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)])
                                    : null,
                                color: _canSubmit ? null : _authGreen.withValues(alpha: 0.3),
                                boxShadow: _canSubmit
                                    ? [BoxShadow(color: _authGreen.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _canSubmit ? _submit : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isSubmitting)
                                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        else
                                          const Icon(LucideIcons.user_plus, size: 20, color: Colors.white),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isSubmitting ? 'Регистрация...' : 'Создать аккаунт',
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
