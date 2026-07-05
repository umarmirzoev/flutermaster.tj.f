import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/home_tab_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/master_registration_draft_provider.dart';
import '../utils/phone_formatter.dart';

const _masterNavy = Color(0xFF1C2438);
const _hintGrey = Color(0xFF9CA3AF);
const _bodyGrey = Color(0xFF6B7280);
const _titleColor = Color(0xFF111827);

class MasterCodeLoginScreen extends ConsumerStatefulWidget {
  const MasterCodeLoginScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<MasterCodeLoginScreen> createState() =>
      _MasterCodeLoginScreenState();
}

class _MasterCodeLoginScreenState extends ConsumerState<MasterCodeLoginScreen> {
  late final TextEditingController _phoneController;
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final digits = localDigitsFromPhone(widget.initialPhone);
    _phoneController = TextEditingController(text: digits);
    _restoreSavedPhone();
  }

  Future<void> _restoreSavedPhone() async {
    if (_phoneController.text.isNotEmpty) return;

    final saved = await ref.read(authProvider.notifier).readSavedPhone();
    final digits = localDigitsFromPhone(saved);
    if (!mounted || digits.isEmpty) return;

    _phoneController.text = digits;
    setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _canLogin =>
      !_isSubmitting &&
      _phoneController.text.trim().length >= 9 &&
      _codeController.text.trim().length == 4;

  Future<void> _onLogin() async {
    if (!_canLogin) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).loginMasterWithCode(
            phone: _phoneController.text.trim(),
            code: _codeController.text.trim(),
          );
      if (!mounted) return;
      ref.read(homeTabProvider.notifier).openProfile();
      context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onApply() async {
    ref.read(masterRegistrationDraftProvider.notifier).reset();

    final phone = _phoneController.text.trim();
    if (phone.length >= 9) {
      await ref.read(authProvider.notifier).signInWithPhone(phone);
    }

    if (!mounted) return;
    context.push(
      '/master/register?mode=application',
      extra: phone.length >= 9 ? {'phone': phone} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/role'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    LucideIcons.chevron_left,
                    color: _masterNavy,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _masterNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.hammer,
                  color: _masterNavy,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Вход для мастера',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Введите номер телефона и код входа из личного кабинета',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _bodyGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Номер телефона',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 8),
              _PhoneField(
                controller: _phoneController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(
                'Код входа',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 8),
              _CodeField(
                controller: _codeController,
                onChanged: (_) => setState(() {}),
                onSubmitted: _canLogin ? _onLogin : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.circle_alert,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFDC2626),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _canLogin ? _onLogin : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _masterNavy,
                    disabledBackgroundColor: _masterNavy.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Вход...' : 'Войти в кабинет',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Код выдаётся при регистрации мастера. Если забыли код — обратитесь в поддержку.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _hintGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              const _OrDivider(),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _onApply,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _masterNavy,
                    side: const BorderSide(color: _masterNavy, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Подать заявку',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Станьте мастером на Master.tj — укажите ФИО, услуги и дождитесь одобрения',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _bodyGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
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
          child: Text(
            'или',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _hintGrey,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.onChanged,
  });

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
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: _titleColor,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+992',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.only(left: 12),
                color: const Color(0xFFE5E7EB),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '900 00 00 00',
        hintStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: _hintGrey,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _masterNavy.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _masterNavy, width: 1.8),
        ),
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      style: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _titleColor,
        letterSpacing: 12,
      ),
      decoration: InputDecoration(
        hintText: '••••',
        hintStyle: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _hintGrey,
          letterSpacing: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _masterNavy.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _masterNavy, width: 1.8),
        ),
      ),
    );
  }
}
