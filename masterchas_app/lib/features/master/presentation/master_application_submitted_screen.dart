import 'package:flutter/material.dart';import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: masterNavy.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  LucideIcons.clock,
                  size: 52,
                  color: masterNavy,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Заявка принята',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: masterNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ожидайте обратной связи после проверки. '
                'Статус заявки можно посмотреть в профиле.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
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
                    style: GoogleFonts.inter(
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
