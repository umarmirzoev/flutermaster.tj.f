import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/providers/home_tab_provider.dart';
import '../../../core/widgets/motion.dart';
import '../providers/auth_provider.dart';
import '../utils/phone_formatter.dart';
import 'auth_widgets.dart';

/// Восстановление пароля: номер → SMS-код → новый пароль → сразу вход.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _phone =
      TextEditingController(text: localDigitsFromPhone(widget.initialPhone));
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  int _step = 0; // 0 — номер, 1 — код и новый пароль
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;
  int _resendIn = 0;
  bool _viaTelegram = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  String _messageFrom(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return 'Нет соединения с сервером. Проверьте интернет.';
      }
    }
    return 'Что-то пошло не так. Попробуйте ещё раз.';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (_phone.text.trim().length < 9) {
      setState(() => _error = 'Введите номер полностью (9 цифр)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final res = await ref.read(dioProvider).post<dynamic>(
            '/auth/password/forgot',
            data: {'phoneNumber': '+992${_phone.text.trim()}'},
          );
      final data = res.data;
      setState(() {
        _step = 1;
        _viaTelegram = false;
        _info = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Мы отправили SMS с кодом.';
      });
      _startTimer();
    } catch (e) {
      setState(() => _error = _messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Бесплатно: код приходит в Telegram-бот после «Поделиться номером».
  Future<void> _sendTelegram() async {
    if (_phone.text.trim().length < 9) {
      setState(() => _error = 'Введите номер полностью (9 цифр)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final res = await ref.read(dioProvider).post<dynamic>(
            '/auth/password/forgot-telegram',
            data: {'phoneNumber': '+992${_phone.text.trim()}'},
          );
      var data = res.data;
      final message = data is Map && data['message'] != null ? data['message'].toString() : null;
      if (data is Map && data['data'] is Map) data = data['data'];
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) throw Exception('Нет ссылки на бота');
      setState(() {
        _step = 1;
        _viaTelegram = true;
        _info = message ?? 'Откройте Telegram-бота и нажмите «Поделиться номером».';
      });
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      setState(() => _error = e is DioException ? _messageFrom(e) : e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Введите 6-значный код из SMS');
      return;
    }
    if (_pass.text.length < 8) {
      setState(() => _error = 'Пароль должен быть не короче 8 символов');
      return;
    }
    if (_pass.text != _pass2.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(dioProvider).post<dynamic>(
            '/auth/password/reset',
            data: {
              'phoneNumber': '+992${_phone.text.trim()}',
              'code': _code.text.trim(),
              'newPassword': _pass.text,
            },
          );
      // Пароль сменён — сразу входим с новым паролем.
      await ref.read(authProvider.notifier).loginWithPassword(
            phone: _phone.text.trim(),
            password: _pass.text,
          );
      if (!mounted) return;
      if (ref.read(authProvider).isMaster) {
        ref.read(homeTabProvider.notifier).openProfile();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: authGreen,
          behavior: SnackBarBehavior.floating,
          content: Text('Пароль изменён, вы вошли в аккаунт', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        ),
      );
      context.go('/');
    } catch (e) {
      setState(() => _error = e is DioException ? _messageFrom(e) : e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _callSupport() async {
    await launchUrl(Uri(scheme: 'tel', path: AppConfig.masterHotline));
  }

  @override
  Widget build(BuildContext context) {
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AuthBackButton(
                          onTap: () {
                            if (_step == 1) {
                              setState(() {
                                _step = 0;
                                _error = null;
                              });
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: AuthHeroIcon(icon: _step == 0 ? LucideIcons.key_round : LucideIcons.shield_check),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(_step),
                          children: [
                            Text(
                              _step == 0 ? 'Забыли пароль?' : 'Новый пароль',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: authTitle),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _step == 0
                                  ? 'Введите номер — пришлём код для восстановления в Telegram или по SMS'
                                  : _viaTelegram
                                      ? 'Введите код, который прислал Telegram-бот, и придумайте новый пароль'
                                      : 'Введите код из SMS на +992 ${_phone.text} и придумайте новый пароль',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(fontSize: 14.5, color: authBody, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (_step == 0)
                        Reveal(
                          child: AuthGlowField(
                            controller: _phone,
                            label: 'Номер телефона',
                            hint: '900 00 00 00',
                            icon: LucideIcons.phone,
                            prefixText: '+992 ',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _sendCode(),
                          ),
                        )
                      else ...[
                        Reveal(
                          child: AuthGlowField(
                            controller: _code,
                            label: _viaTelegram ? 'Код из Telegram' : 'Код из SMS',
                            hint: '••••••',
                            icon: LucideIcons.message_circle,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Reveal(
                          delay: const Duration(milliseconds: 60),
                          child: AuthGlowField(
                            controller: _pass,
                            label: 'Новый пароль',
                            hint: 'Минимум 8 символов',
                            icon: LucideIcons.lock,
                            obscure: _obscure,
                            onToggleObscure: () => setState(() => _obscure = !_obscure),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Reveal(
                          delay: const Duration(milliseconds: 120),
                          child: AuthGlowField(
                            controller: _pass2,
                            label: 'Повторите пароль',
                            hint: 'Ещё раз',
                            icon: LucideIcons.lock_keyhole,
                            obscure: _obscure,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _reset(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AuthCheckChip(label: 'Код 6 цифр', ok: _code.text.length == 6),
                            AuthCheckChip(label: '8+ символов', ok: _pass.text.length >= 8),
                            AuthCheckChip(label: 'Пароли совпадают', ok: _pass.text.isNotEmpty && _pass.text == _pass2.text),
                          ],
                        ),
                      ],
                      if (_info != null && _error == null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: authGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: authGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.circle_check, size: 18, color: authGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_info!, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32))),
                              ),
                            ],
                          ),
                        ),
                      ],
                      AuthErrorBox(message: _error),
                      const SizedBox(height: 22),
                      if (_step == 0) ...[
                        AuthPrimaryButton(
                          label: 'Получить код в Telegram',
                          loadingLabel: 'Открываем Telegram...',
                          icon: LucideIcons.send,
                          enabled: _phone.text.trim().length == 9,
                          loading: _loading,
                          onTap: _sendTelegram,
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Бесплатно · нужен Telegram на этом номере',
                            style: GoogleFonts.manrope(fontSize: 11.5, color: authHint, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _loading || _phone.text.trim().length != 9 ? null : _sendCode,
                          icon: const Icon(LucideIcons.message_circle, size: 18, color: authGreen),
                          label: Text('Получить код по SMS', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: authGreen)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: authGreen.withValues(alpha: 0.5), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ] else
                        AuthPrimaryButton(
                          label: 'Сохранить и войти',
                          loadingLabel: 'Сохраняем...',
                          icon: LucideIcons.log_in,
                          enabled: _code.text.length == 6 && _pass.text.length >= 8 && _pass.text == _pass2.text,
                          loading: _loading,
                          onTap: _reset,
                        ),
                      if (_step == 1) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: _viaTelegram
                                ? (_loading ? null : _sendTelegram)
                                : (_resendIn > 0 || _loading ? null : _sendCode),
                            child: Text(
                              _viaTelegram
                                  ? 'Открыть Telegram-бота ещё раз'
                                  : (_resendIn > 0 ? 'Отправить код снова через $_resendIn с' : 'Отправить код снова'),
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: !_viaTelegram && _resendIn > 0 ? authHint : authGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: _callSupport,
                          icon: const Icon(LucideIcons.headphones, size: 16, color: authBody),
                          label: Text(
                            'Не приходит код? Поддержка ${AppConfig.masterHotlineLabel}',
                            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: authBody),
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
