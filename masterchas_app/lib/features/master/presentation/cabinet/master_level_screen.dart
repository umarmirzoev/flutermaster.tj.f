import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import 'master_cabinet_shell.dart';

class MasterLevelScreen extends ConsumerWidget {
  const MasterLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(authProvider).masterProfile?.completedOrders ?? 0;
    const levels = [
      (name: 'Старт', min: 0, max: 10),
      (name: 'Бронза', min: 10, max: 50),
      (name: 'Серебро', min: 50, max: 150),
      (name: 'Золото', min: 150, max: 500),
      (name: 'Platinum', min: 500, max: 1000),
    ];

    var current = levels.first;
    var next = levels.length > 1 ? levels[1] : levels.first;
    for (var i = 0; i < levels.length; i++) {
      if (orders >= levels[i].min) {
        current = levels[i];
        next = i + 1 < levels.length ? levels[i + 1] : levels[i];
      }
    }

    final progress = current.max == current.min
        ? 1.0
        : ((orders - current.min) / (next.max - current.min)).clamp(0.0, 1.0);

    return MasterCabinetShell(
      title: 'Уровень мастера',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [masterNavy, masterNavyLight],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.award, size: 56, color: Colors.amber.shade400),
                const SizedBox(height: 12),
                Text(
                  current.name,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$orders выполненных заказов',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            next.name != current.name ? 'До ${next.name}' : 'Максимальный уровень',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: masterNavy,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8ECF1),
              color: masterNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next.name != current.name
                ? '${(progress * 100).round()}% · осталось ${(next.min - orders).clamp(0, next.min)} заказов'
                : 'Вы достигли высшего уровня',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          Text(
            'Все уровни',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: masterNavy,
            ),
          ),
          const SizedBox(height: 10),
          ...levels.map((l) {
            final reached = orders >= l.min;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: reached ? masterNavy : const Color(0xFFE8ECF1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    reached ? LucideIcons.circle_check : LucideIcons.circle,
                    color: reached ? masterNavy : const Color(0xFFD1D5DB),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: masterNavy,
                      ),
                    ),
                  ),
                  Text(
                    '${l.min}+ заказов',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
