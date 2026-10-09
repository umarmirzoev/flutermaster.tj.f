import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/motion.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/home_tab_provider.dart';
import '../../../core/theme/master_palette.dart';

class MasterApplicationSubmittedScreen extends ConsumerWidget {
  const MasterApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: PulseRing(
                  color: const Color(0xFF10B981),
                  size: 120,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
                      ),
                    ),
                    child: const FloatY(
                      amplitude: 3,
                      child: Icon(LucideIcons.check, size: 56, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Reveal(
                delay: const Duration(milliseconds: 350),
                child: Text(
                'Заявка принята',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: masterNavy,
                ),
              ),
              ),
              const SizedBox(height: 12),
              Reveal(
                delay: const Duration(milliseconds: 480),
                child: Text(
                'Ожидайте обратной связи после проверки. '
                'Статус заявки можно посмотреть в профиле.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    for (final (icon, text) in const [
                      (LucideIcons.search, 'Проверим данные — обычно до 24 часов'),
                      (LucideIcons.bell, 'Пришлём уведомление о решении'),
                      (LucideIcons.briefcase, 'После одобрения начнёте получать заказы'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, size: 17, color: const Color(0xFF059669)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: masterNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    ref.read(homeTabProvider.notifier).openProfile();
                    context.go('/');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: masterNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Перейти в профиль',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
