import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../providers/auth_provider.dart';
import '../utils/phone_formatter.dart';
import '../../../core/widgets/motion.dart';
import 'auth_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final pass = _passwordController.text;
    final lenOk = pass.length >= 8;
    final digitOk = pass.contains(RegExp(r'[0-9]'));
    final phoneOk = _phoneController.text.trim().length >= 9;
    final isMaster = widget.role == 'Master';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Reveal(
                        offsetY: -10,
                        child: Row(
                          children: [
                            AuthBackButton(onTap: () => Navigator.maybePop(context)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: _authGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const LiveDot(color: _authGreen, size: 7),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Защищённое соединение',
                                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: _authGreen),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Reveal(
                        delay: Duration(milliseconds: 80),
                        offsetY: -12,
                        child: Center(child: AuthHeroIcon(icon: LucideIcons.user_plus)),
                      ),
                      const SizedBox(height: 22),
                      Reveal(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          isMaster ? 'Станьте мастером' : 'Создайте аккаунт',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF111827), height: 1.15),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Reveal(
                        delay: const Duration(milliseconds: 210),
                        child: Text(
                          'Без SMS-кодов — только номер и пароль. Займёт 30 секунд.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 14.5, color: const Color(0xFF6B7280), height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Reveal(
                        delay: const Duration(milliseconds: 270),
                        child: AuthGlowField(
                          controller: _phoneController,
                          label: 'Номер телефона',
                          hint: '900 00 00 00',
                          icon: LucideIcons.phone,
                          prefixText: '+992 ',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          trailing: _okBadge(phoneOk),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        delay: const Duration(milliseconds: 330),
                        child: AuthGlowField(
                          controller: _passwordController,
                          label: 'Пароль',
                          hint: 'Минимум 8 символов',
                          icon: LucideIcons.lock,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      // ── Сила пароля ──
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: pass.isEmpty
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: _passwordStrength),
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, v, _) => LinearProgressIndicator(
                                            value: v,
                                            backgroundColor: const Color(0xFFE5E7EB),
                                            valueColor: AlwaysStoppedAnimation(_strengthColor),
                                            minHeight: 5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      child: Text(
                                        _strengthLabel,
                                        key: ValueKey(_strengthLabel),
                                        style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w800, color: _strengthColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        delay: const Duration(milliseconds: 390),
                        child: AuthGlowField(
                          controller: _confirmController,
                          label: 'Повторите пароль',
                          hint: 'Ещё раз пароль',
                          icon: LucideIcons.lock_keyhole,
                          obscure: _obscure,
                          textInputAction: TextInputAction.done,
                          trailing: _confirmController.text.isEmpty ? null : _okBadge(_passwordsMatch, showError: true),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        delay: const Duration(milliseconds: 440),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AuthCheckChip(label: 'Номер', ok: phoneOk),
                            AuthCheckChip(label: '8+ символов', ok: lenOk),
                            AuthCheckChip(label: 'Есть цифра', ok: digitOk),
                            AuthCheckChip(label: 'Пароли совпадают', ok: _passwordsMatch),
                          ],
                        ),
                      ),
                      AuthErrorBox(message: _error),
                      const SizedBox(height: 24),
                      Reveal(
                        delay: const Duration(milliseconds: 500),
                        child: AuthPrimaryButton(
                          label: 'Создать аккаунт',
                          loadingLabel: 'Создаём...',
                          icon: LucideIcons.sparkles,
                          enabled: _canSubmit,
                          loading: _isSubmitting,
                          onTap: _submit,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Reveal(
                        delay: const Duration(milliseconds: 560),
                        child: Center(
                          child: TextButton(
                            onPressed: () => Navigator.maybePop(context),
                            child: Text.rich(
                              TextSpan(
                                style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B7280)),
                                children: [
                                  const TextSpan(text: 'Уже есть аккаунт? '),
                                  TextSpan(
                                    text: 'Войти',
                                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: _authGreen),
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
    );
  }

  Widget _okBadge(bool ok, {bool showError = false}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
      child: ok
          ? const Padding(
              key: ValueKey('ok'),
              padding: EdgeInsets.only(right: 12),
              child: Icon(LucideIcons.circle_check, color: _authGreen, size: 22),
            )
          : showError
              ? const Padding(
                  key: ValueKey('err'),
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(LucideIcons.circle_x, color: Color(0xFFEF4444), size: 22),
                )
              : const SizedBox(key: ValueKey('none'), width: 0),
    );
  }
}
