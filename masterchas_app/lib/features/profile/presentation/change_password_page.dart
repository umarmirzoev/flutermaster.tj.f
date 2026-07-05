import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_result.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/phone_formatter.dart';
import '../../home/presentation/home_palette.dart';
import '../data/profile_l10n.dart';
import 'profile_shell.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<String?> _readStoredPassword(String phone) async {
    final json = await ref.read(secureStorageProvider).readClientPasswordsJson();
    if (json == null || json.isEmpty) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    final key = localDigitsFromPhone(phone);
    return map[key] as String?;
  }

  Future<void> _writeStoredPassword(String phone, String password) async {
    final storage = ref.read(secureStorageProvider);
    final json = await storage.readClientPasswordsJson();
    final map = <String, dynamic>{};
    if (json != null && json.isNotEmpty) {
      map.addAll(jsonDecode(json) as Map<String, dynamic>);
    }
    map[localDigitsFromPhone(phone)] = password;
    await storage.writeClientPasswordsJson(jsonEncode(map));
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    final phone = ref.read(authProvider).phone;

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите в аккаунт')),
      );
      return;
    }
    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новый пароль — минимум 6 символов')),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final stored = await _readStoredPassword(phone);
      if (stored != null) {
        if (stored != current) {
          throw Exception('Неверный текущий пароль');
        }
      } else {
        final result = await ref.read(authRepositoryProvider).login(phone, current);
        if (result is! ApiSuccess) {
          throw Exception('Неверный текущий пароль');
        }
      }

      await _writeStoredPassword(phone, newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: brandGreen,
            content: Text('Пароль успешно изменён'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);

    return ProfileSubPage(
      title: l.changePin,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            p: p,
            label: 'Текущий пароль',
            controller: _currentCtrl,
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _field(
            p: p,
            label: 'Новый пароль',
            controller: _newCtrl,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _field(
            p: p,
            label: 'Подтвердите новый пароль',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: brandGreen),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Сохранить', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required HomePalette p,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: p.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(obscure ? LucideIcons.eye_off : LucideIcons.eye, size: 18, color: p.muted),
            ),
          ),
        ),
      ],
    );
  }
}
