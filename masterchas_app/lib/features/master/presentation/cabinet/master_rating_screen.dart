import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import 'master_cabinet_shell.dart';

class MasterRatingScreen extends ConsumerWidget {
  const MasterRatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).masterProfile;
    final rating = profile?.rating ?? 0;
    final reviews = profile?.reviewCount ?? 0;

    return MasterCabinetShell(
      title: 'Рейтинг',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF1)),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.star,
                  size: 48,
                  color: rating > 0 ? Colors.amber.shade600 : const Color(0xFFD1D5DB),
                ),
                const SizedBox(height: 12),
                Text(
                  rating > 0 ? rating.toStringAsFixed(1) : '—',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: masterNavy,
                  ),
                ),
                Text(
                  reviews > 0 ? '$reviews отзывов' : 'Пока нет отзывов',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF1)),
            ),
            child: Text(
              reviews == 0
                  ? 'Рейтинг появится после первых отзывов клиентов. '
                      'Качественная работа поможет быстрее набрать доверие.'
                  : 'Спасибо за отличную работу! Продолжайте получать положительные отзывы.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
