import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// «ИИ-диспетчер 24/7» — как на сайте emaster.tj: звонок ИИ-диспетчеру,
/// который принимает заказ голосом и направляет мастера.
class AiCallSheet extends StatelessWidget {
  const AiCallSheet({super.key});

  static const phoneDisplay = '+992 079 33 01 10';
  static const phoneDial = '+992079330110';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiCallSheet(),
    );
  }

  Future<void> _call(BuildContext context) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phoneDial));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть звонок. Наберите $phoneDisplay')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const _PulsingPhoneIcon(),
          const SizedBox(height: 20),
          Text(
            'ИИ-диспетчер 24/7',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ответит сразу, круглосуточно. Расскажите, что случилось, — примем заказ и направим мастера.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: phoneDisplay));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Номер скопирован'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                children: [
                  Text(
                    phoneDisplay,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: const Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Нажмите на номер, чтобы скопировать',
                    style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _call(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.phone, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Позвонить',
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

class _PulsingPhoneIcon extends StatefulWidget {
  const _PulsingPhoneIcon();

  @override
  State<_PulsingPhoneIcon> createState() => _PulsingPhoneIconState();
}

class _PulsingPhoneIconState extends State<_PulsingPhoneIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final delay in const [0.0, 0.5])
                Builder(builder: (_) {
                  final v = (t + delay) % 1.0;
                  return Container(
                    width: 64 + 46 * v,
                    height: 64 + 46 * v,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.25 * (1 - v)),
                    ),
                  );
                }),
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF0D9488)],
                  ),
                ),
                child: const Icon(LucideIcons.bot, color: Colors.white, size: 32),
              ),
            ],
          );
        },
      ),
    );
  }
}
