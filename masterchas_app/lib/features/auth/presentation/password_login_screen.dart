import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/providers/home_tab_provider.dart';
import '../../../core/widgets/motion.dart';
import '../data/master_credentials.dart';
import '../providers/auth_provider.dart';
import '../utils/phone_formatter.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';

const _authGreen = Color(0xFF57B55E);
const _bodyGrey = Color(0xFF6B7280);
const _titleColor = Color(0xFF111827);

class PasswordLoginScreen extends ConsumerStatefulWidget {
  const PasswordLoginScreen({super.key, this.initialPhone, this.role = 'Client'});

  final String? initialPhone;
  final String role;

  @override
  ConsumerState<PasswordLoginScreen> createState() =>
      _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends ConsumerState<PasswordLoginScreen> {
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final digits = localDigitsFromPhone(widget.initialPhone);
    _phoneController = TextEditingController(text: digits);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canLogin =>
      !_isSubmitting &&
      _phoneController.text.trim().length >= 9 &&
      _passwordController.text.trim().isNotEmpty;

  Future<void> _onLogin() async {
    if (!_canLogin) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).loginWithPassword(
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isMaster) {
        ref.read(homeTabProvider.notifier).openProfile();
      }
      context.go('/');
    } catch (e) {
      final phone = _phoneController.text.trim();
      final code = _passwordController.text.trim();
      if (isKnownMasterPhone(phone) && code.length == 4) {
        try {
          await ref.read(authProvider.notifier).loginMasterWithCode(
                phone: phone,
                code: code,
              );
          if (!mounted) return;
          ref.read(homeTabProvider.notifier).openProfile();
          context.go('/');
          return;
        } catch (_) {}
      }

      if (mounted) {
        final message = isKnownMasterPhone(phone)
            ? 'Неверный код входа. Для мастеров используйте 4-значный код.'
            : e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = message);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Reveal(
                        offsetY: 0,
                        offsetX: -16,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AuthBackButton(
                            onTap: () => context.canPop() ? context.pop() : context.go('/login'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Reveal(
                        delay: Duration(milliseconds: 80),
                        offsetY: -12,
                        child: Center(child: AuthHeroIcon(icon: LucideIcons.lock_keyhole)),
                      ),
                      const SizedBox(height: 22),
                      Reveal(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          'С возвращением!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: _titleColor, height: 1.15),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Reveal(
                        delay: const Duration(milliseconds: 210),
                        child: Text(
                          isMaster
                              ? 'Войдите по номеру и паролю (или 4-значному коду мастера)'
                              : 'Войдите по номеру телефона и паролю',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 14.5, color: _bodyGrey, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Reveal(
                        delay: const Duration(milliseconds: 280),
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        delay: const Duration(milliseconds: 340),
                        child: AuthGlowField(
                          controller: _passwordController,
                          label: 'Пароль',
                          hint: 'Введите пароль',
                          icon: LucideIcons.lock,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _onLogin(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            SmoothRoute<void>(
                              builder: (_) => ForgotPasswordScreen(initialPhone: _phoneController.text.trim()),
                            ),
                          ),
                          child: Text(
                            'Забыли пароль?',
                            style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: _authGreen),
                          ),
                        ),
                      ),
                      AuthErrorBox(message: _error),
                      const SizedBox(height: 16),
                      Reveal(
                        delay: const Duration(milliseconds: 400),
                        child: AuthPrimaryButton(
                          label: 'Войти',
                          loadingLabel: 'Входим...',
                          icon: LucideIcons.log_in,
                          enabled: _canLogin,
                          loading: _isSubmitting,
                          onTap: _onLogin,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Reveal(
                        delay: const Duration(milliseconds: 470),
                        child: _RegisterLink(
                          onTap: () => context.push(
                            '/login/register',
                            extra: {
                              'phone': _phoneController.text.trim(),
                              'role': widget.role,
                            },
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
}

class _RegisterLink extends StatelessWidget {
  const _RegisterLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 16,
      lift: 2,
      glowColor: _authGreen,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _authGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _authGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.user_plus, size: 18, color: _authGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Нет аккаунта?', style: GoogleFonts.manrope(fontSize: 12.5, color: _bodyGrey)),
                      Text('Зарегистрироваться за 30 секунд', style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w800, color: _titleColor)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.arrow_right, size: 18, color: _authGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
