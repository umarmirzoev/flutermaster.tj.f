import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/home_tab_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/master_registration_draft_provider.dart';
import '../utils/phone_formatter.dart';
import '../data/master_reg_l10n.dart';
import '../../home/presentation/home_palette.dart';

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
    final locale = ref.watch(localeProvider);
    final l = MasterRegL10n.of(locale);
    final p = HomePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: p.pageBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium navy→green gradient header
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 14, 20, 26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? p.headerGradient
                    : const [Color(0xFF1C2438), Color(0xFF2A4A3A), Color(0xFF3B8F42)],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.go('/role'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(LucideIcons.arrow_left, size: 19, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF57B55E), Color(0xFF6DD674)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF57B55E).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(LucideIcons.hammer, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  l.loginTitle,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.loginSub,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text(
                l.phoneLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 8),
              _PhoneField(
                controller: _phoneController,
                p: p,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(
                l.codeLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 8),
              _CodeField(
                controller: _codeController,
                p: p,
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
              GestureDetector(
                onTap: _canLogin ? _onLogin : null,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _canLogin
                        ? const LinearGradient(colors: [Color(0xFF1C2438), Color(0xFF2A4A3A), Color(0xFF3B8F42)])
                        : null,
                    color: _canLogin ? null : _masterNavy.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canLogin
                        ? [BoxShadow(color: const Color(0xFF3B8F42).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _isSubmitting ? l.loggingIn : l.loginBtn,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.codeHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _hintGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _OrDivider(label: l.orDivider),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _onApply,
                  icon: const Icon(LucideIcons.user_plus, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B8F42),
                    side: const BorderSide(color: Color(0xFF57B55E), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: Text(
                    l.becomeMaster,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.applySub,
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
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
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
    required this.p,
    required this.onChanged,
  });

  final TextEditingController controller;
  final HomePalette p;
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
        color: p.text,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.inputFill,
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
                  color: p.text,
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.only(left: 12),
                color: p.border,
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '900 00 00 00',
        hintStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: p.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border, width: 1.5),
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
    required this.p,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final HomePalette p;
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
        color: p.text,
        letterSpacing: 12,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.inputFill,
        hintText: '••••',
        hintStyle: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: p.muted,
          letterSpacing: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _masterNavy, width: 1.8),
        ),
      ),
    );
  }
}
