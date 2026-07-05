import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/master_registration_draft_provider.dart';
import '../utils/phone_formatter.dart';

const _navy = Color(0xFF1C2438);
const _fieldFill = Color(0xFFF3F4F8);
const _hintGrey = Color(0xFF9CA3AF);
const _bodyGrey = Color(0xFF6B7280);
const _titleColor = Color(0xFF111827);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go(
                        widget.applicationMode ? '/login/master-code' : '/role',
                      );
                    },
                    icon: const Icon(LucideIcons.arrow_left, color: _titleColor),
                  ),
                  Text(
                    'master.tj',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.applicationMode ? 'Заявка мастера' : 'Как вас зовут?',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.applicationMode
                          ? 'Заполните данные для подачи заявки. После проверки вы получите код для входа в кабинет.'
                          : 'Пожалуйста, укажите ваши фамилию, имя и отчество точно '
                              'так, как указано в паспорте. Это необходимо для проверки.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _bodyGrey,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Номер телефона',
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
                        decoration: const InputDecoration(
                          labelText: 'Пароль (мин. 8 символов)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _NameField(
                      controller: _lastNameController,
                      hint: 'Фамилия',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _NameField(
                      controller: _firstNameController,
                      hint: 'Имя',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _NameField(
                      controller: _patronymicController,
                      hint: 'Отчество',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Я частный или самозанятый специалист',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
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
                        hint: 'Введите название компании *',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _TermsCheckbox(
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
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _canContinue ? _onContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: _navy.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Продолжить',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _titleColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _hintGrey,
        ),
        filled: true,
        fillColor: _fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _navy, width: 1.4),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
  });

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
                  color: _bodyGrey,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'Я принимаю '),
                  TextSpan(
                    text: 'Условия использования',
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
                              'Условия использования',
                              style: GoogleFonts.inter(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: ' и '),
                  TextSpan(
                    text: 'Политику конфиденциальности',
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
                              'Политика конфиденциальности',
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
