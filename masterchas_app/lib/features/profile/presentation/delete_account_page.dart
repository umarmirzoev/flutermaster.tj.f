import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/locale_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../data/profile_l10n.dart';
import 'profile_shell.dart';

/// Support contact used to process account-deletion requests.
const String _supportPhoneDisplay = '+992 97 911 70 07';
const String _supportPhoneDigits = '992979117007';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _submitting = false;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _supportPhoneDigits);
    await launchUrl(uri);
  }

  Future<void> _whatsApp(String phone) async {
    final text = Uri.encodeComponent(
      'Здравствуйте! Прошу удалить мой аккаунт MasterChas (телефон: $phone). Дата запроса: ${DateTime.now().toIso8601String().split('T').first}.',
    );
    final uri = Uri.parse('https://wa.me/$_supportPhoneDigits?text=$text');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить аккаунт?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Мы получим запрос на удаление и полностью удалим ваш аккаунт и данные в течение 3 рабочих дней. '
          'Сейчас вы будете выведены из аккаунта на этом устройстве.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отмена', style: GoogleFonts.inter())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text('Удалить', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final phone = ref.read(authProvider).phone ?? '—';
    await _whatsApp(phone);
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;
    setState(() => _submitting = false);
    context.go('/role');
  }

  @override
  Widget build(BuildContext context) {
    ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);

    return ProfileSubPage(
      title: 'Удаление аккаунта',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.triangle_alert, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Удаление аккаунта необратимо: вы потеряете историю заказов, отзывы, бонусы и сохранённые адреса.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7F1D1D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Как это работает', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          Text(
            'Нажмите «Отправить запрос на удаление» ниже — откроется WhatsApp с готовым сообщением в поддержку MasterChas. '
            'Мы обрабатываем такие запросы и полностью удаляем аккаунт со всеми данными в течение 3 рабочих дней. '
            'Вы также можете позвонить нам напрямую.',
            style: GoogleFonts.inter(fontSize: 13.5, color: p.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _call,
              icon: const Icon(LucideIcons.phone, size: 18),
              label: Text(_supportPhoneDisplay, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(foregroundColor: brandGreen, side: const BorderSide(color: brandGreen)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _confirmAndSignOut,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Отправить запрос на удаление', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
