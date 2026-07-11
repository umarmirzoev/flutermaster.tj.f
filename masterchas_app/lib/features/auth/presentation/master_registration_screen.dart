import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/master_registration_draft_provider.dart';
import '../utils/phone_formatter.dart';
import '../../../core/providers/locale_provider.dart';
import '../data/master_reg_l10n.dart';
import '../../home/presentation/home_palette.dart';

const _navy = Color(0xFF1C2438);
const _hintGrey = Color(0xFF9CA3AF);
const _linkBlue = Color(0xFF2563EB);

class MasterRegistrationScreen extends ConsumerStatefulWidget {
  const MasterRegistrationScreen({
    super.key,
    this.applicationMode = false,
    this.initialPhone,
  });

  final bool applicationMode;
  final String? initialPhone;

  @override
  ConsumerState<MasterRegistrationScreen> createState() =>
      _MasterRegistrationScreenState();
}

class _MasterRegistrationScreenState
    extends ConsumerState<MasterRegistrationScreen> {
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSelfEmployed = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final digits = localDigitsFromPhone(widget.initialPhone);
    if (digits.isNotEmpty) {
      _phoneController.text = digits;
    }
    _restoreSavedProfile();
  }

  Future<void> _restoreSavedProfile() async {
    if (widget.applicationMode) return;

    final saved = await ref.read(authProvider.notifier).readSavedMasterProfile();
    if (!mounted || saved == null) return;

    _lastNameController.text = saved.lastName;
    _firstNameController.text = saved.firstName;
    _patronymicController.text = saved.patronymic;
    _companyController.text = saved.companyName ?? '';
    setState(() => _isSelfEmployed = saved.isSelfEmployed);

    ref.read(masterRegistrationDraftProvider.notifier).saveProfile(
          lastName: saved.lastName,
          firstName: saved.firstName,
          patronymic: saved.patronymic,
          isSelfEmployed: saved.isSelfEmployed,
          companyName: saved.companyName,
        );
    ref
        .read(masterRegistrationDraftProvider.notifier)
        .setSelectedServices(saved.selectedServices.toSet());
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_isSubmitting || !_agreedToTerms) return false;
    if (_phoneController.text.trim().length < 9) return false;
    if (!widget.applicationMode && _passwordController.text.trim().length < 8) {
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) return false;
    if (_firstNameController.text.trim().isEmpty) return false;
    if (_patronymicController.text.trim().isEmpty) return false;
    if (_isSelfEmployed && _companyController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _onContinue() async {
    if (!_canContinue) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (widget.applicationMode) {
        await ref
            .read(authProvider.notifier)
            .signInWithPhone(_phoneController.text.trim());

        ref.read(masterRegistrationDraftProvider.notifier).saveProfile(
              lastName: _lastNameController.text,
              firstName: _firstNameController.text,
              patronymic: _patronymicController.text,
              isSelfEmployed: _isSelfEmployed,
              companyName: _isSelfEmployed ? _companyController.text.trim() : null,
            );

        if (mounted) context.go('/master/skills');
        return;
      }

      await ref.read(authProvider.notifier).registerWithPassword(
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
            role: 'Master',
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );

      ref.read(masterRegistrationDraftProvider.notifier).saveProfile(
            lastName: _lastNameController.text,
            firstName: _firstNameController.text,
            patronymic: _patronymicController.text,
            isSelfEmployed: _isSelfEmployed,
            companyName: _isSelfEmployed ? _companyController.text.trim() : null,
          );

      if (mounted) context.go('/master/skills');
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
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 14, 20, 22),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(widget.applicationMode ? '/login/master-code' : '/role');
                      },
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
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF57B55E), Color(0xFF6DD674)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.hammer, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l.becomeMaster,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Step progress
                Row(
                  children: [
                    _stepDot('1', l.stepData, true),
                    _stepLine(),
                    _stepDot('2', l.stepSkills, false),
                    _stepLine(),
                    _stepDot('3', l.stepPhoto, false),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.applicationMode ? l.applicationTitle : l.nameTitle,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.applicationMode ? l.applicationSub : l.nameSub,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: p.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l.phoneLabel,
                        prefixText: '+992 ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (!widget.applicationMode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l.passwordLabel,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _NameField(
                      controller: _lastNameController,
                      hint: l.lastName,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _NameField(
                      controller: _firstNameController,
                      hint: l.firstName,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _NameField(
                      controller: _patronymicController,
                      hint: l.patronymic,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            l.selfEmployed,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: p.text,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _isSelfEmployed,
                          onChanged: (value) =>
                              setState(() => _isSelfEmployed = value),
                          activeTrackColor: _navy.withValues(alpha: 0.35),
                          activeThumbColor: _navy,
                          inactiveTrackColor: const Color(0xFFE5E7EB),
                          inactiveThumbColor: Colors.white,
                        ),
                      ],
                    ),
                    if (_isSelfEmployed) ...[
                      const SizedBox(height: 16),
                      _NameField(
                        controller: _companyController,
                        hint: l.companyHint,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _TermsCheckbox(
                      l: l,
                      p: p,
                      value: _agreedToTerms,
                      onChanged: (value) =>
                          setState(() => _agreedToTerms = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: GestureDetector(
                onTap: _canContinue ? _onContinue : null,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _canContinue
                        ? const LinearGradient(colors: [Color(0xFF1C2438), Color(0xFF2A4A3A), Color(0xFF3B8F42)])
                        : null,
                    color: _canContinue ? null : _navy.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canContinue
                        ? [BoxShadow(color: const Color(0xFF3B8F42).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.continueBtn,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrow_right, size: 18, color: Colors.white),
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

  Widget _stepDot(String num, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: active ? 1 : 0.3), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? const Color(0xFF2A4A3A) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withValues(alpha: active ? 1 : 0.7),
          ),
        ),
      ],
    );
  }

  Widget _stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: p.text,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: p.muted,
        ),
        filled: true,
        fillColor: p.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandGreen, width: 1.4),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.l,
    required this.p,
    required this.value,
    required this.onChanged,
  });

  final MasterRegL10n l;
  final HomePalette p;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _navy,
            side: BorderSide(
              color: value ? _navy : _hintGrey,
              width: 1.6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: p.muted,
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: l.termsPrefix),
                  TextSpan(
                    text: l.termsOfUse,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _linkBlue,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l.termsOfUse,
                              style: GoogleFonts.inter(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                  ),
                  TextSpan(text: l.termsAnd),
                  TextSpan(
                    text: l.privacyPolicy,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _linkBlue,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l.privacyPolicy,
                              style: GoogleFonts.inter(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
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
