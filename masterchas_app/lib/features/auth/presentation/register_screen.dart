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

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
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
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _phoneController.text.trim().length >= 9 &&
      _passwordController.text.length >= 8 &&
      _passwordController.text == _confirmController.text;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final phoneDigits = _phoneController.text.trim();
    debugPrint('REGISTER: starting, digits=$phoneDigits role=${widget.role}');
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _authGreen,
        elevation: 0,
        title: Text('Регистрация', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                prefixText: '+992 ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Пароль (мин. 8 символов)',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? LucideIcons.eye_off : LucideIcons.eye),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Повторите пароль'),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(backgroundColor: _authGreen),
                child: Text(_isSubmitting ? 'Регистрация...' : 'Создать аккаунт'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
