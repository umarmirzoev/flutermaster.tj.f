import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../providers/auth_provider.dart';
import '../utils/phone_formatter.dart';

const _authGreen = Color(0xFF57B55E);
const _hintGrey = Color(0xFF9CA3AF);
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
      context.go(auth.isMaster ? '/master/cabinet/orders' : '/');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    LucideIcons.chevron_left,
                    color: _authGreen,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Вход',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 28),
              _AuthInputField(
                controller: _phoneController,
                hint: '900 00 00 00',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _AuthInputField(
                controller: _passwordController,
                hint: 'Пароль',
                icon: LucideIcons.lock,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                    color: _authGreen,
                    size: 22,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _canLogin ? _onLogin : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _authGreen,
                    disabledBackgroundColor: _authGreen.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Вход...' : 'Войти',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push(
                  '/login/register',
                  extra: {
                    'phone': _phoneController.text.trim(),
                    'role': widget.role,
                  },
                ),
                child: Text(
                  'Нет аккаунта? Зарегистрироваться',
                  style: GoogleFonts.inter(color: _authGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _titleColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _hintGrey),
        prefixIcon: Icon(icon, color: _authGreen, size: 22),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _authGreen.withValues(alpha: 0.55), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _authGreen, width: 1.8),
        ),
      ),
    );
  }
}
