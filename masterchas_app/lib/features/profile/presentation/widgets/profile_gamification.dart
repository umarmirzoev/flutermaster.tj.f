import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_design.dart';
import '../../../home/presentation/home_palette.dart';
import '../../data/account_level.dart';
import '../../data/profile_l10n.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Геймификация профиля: уровень с прогрессом, рефералка, ежедневные задания.
/// ═══════════════════════════════════════════════════════════════════════════

({Color color, IconData icon, String label}) tierStyle(AccountTier t, ProfileL10n l) {
  switch (t) {
    case AccountTier.bronze:
      return (color: const Color(0xFFCD7F32), icon: LucideIcons.shield, label: l.tierBronze);
    case AccountTier.silver:
      return (color: const Color(0xFF9CA3AF), icon: LucideIcons.shield_half, label: l.tierSilver);
    case AccountTier.gold:
      return (color: const Color(0xFFF59E0B), icon: LucideIcons.crown, label: l.tierGold);
    case AccountTier.platinum:
      return (color: const Color(0xFF8B5CF6), icon: LucideIcons.gem, label: l.tierPlatinum);
  }
}

/// Большая карточка уровня с анимированным прогресс-баром.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.level,
    required this.p,
    required this.l,
  });

  final AccountLevelInfo level;
  final HomePalette p;
  final ProfileL10n l;

  @override
  Widget build(BuildContext context) {
    final style = tierStyle(level.tier, l);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.color, Color.lerp(style.color, Colors.black, 0.25)!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: style.color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(style.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.levelLine(level.tier),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      level.nextTier != null
                          ? l.pointsToNextLine(level.nextTier!, level.pointsToNext)
                          : l.maxLevel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: level.progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(value * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Карточка реферальной программы с QR-заглушкой.
class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key, required this.p, required this.l, this.code = 'MASTER-A7X9'});

  final HomePalette p;
  final ProfileL10n l;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppDesign.aiGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDesign.glowShadow(AppDesign.accentPurple),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: CustomPaint(painter: _QrPainter()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.gift, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      l.referFriend,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l.referBonus,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l.promoCopied(code),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          code,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppDesign.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.copy, size: 14, color: AppDesign.accentPurple),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1C2438);
    const cells = 7;
    final cell = size.width / cells;
    const pattern = [
      [1, 1, 1, 0, 1, 1, 1],
      [1, 0, 1, 0, 1, 0, 1],
      [1, 1, 1, 0, 1, 1, 1],
      [0, 0, 0, 1, 0, 0, 0],
      [1, 1, 0, 1, 0, 1, 1],
      [1, 0, 1, 0, 1, 0, 1],
      [1, 1, 1, 0, 1, 1, 1],
    ];
    for (int y = 0; y < cells; y++) {
      for (int x = 0; x < cells; x++) {
        if (pattern[y][x] == 1) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x * cell, y * cell, cell * 0.9, cell * 0.9),
              const Radius.circular(1),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => false;
}

/// Ежедневные задания за бонусы.
class DailyQuestsCard extends StatelessWidget {
  const DailyQuestsCard({
    super.key,
    required this.p,
    required this.ordersCount,
    required this.l,
  });

  final HomePalette p;
  final int ordersCount;
  final ProfileL10n l;

  @override
  Widget build(BuildContext context) {
    final quests = <({String label, int reward, IconData icon, bool done})>[
      (label: l.questReview, reward: 10, icon: LucideIcons.star, done: ordersCount >= 2),
      (label: l.questShare, reward: 20, icon: LucideIcons.share_2, done: false),
      (label: l.questOrderToday, reward: 30, icon: LucideIcons.calendar_check, done: false),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.target, size: 18, color: AppDesign.brand),
              const SizedBox(width: 6),
              Text(
                l.dailyQuests,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
              ),
              const Spacer(),
              Text(
                l.bonusesReward(quests.where((q) => !q.done).fold(0, (s, q) => s + q.reward)),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppDesign.brand),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...quests.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: q.done
                            ? AppDesign.brand.withValues(alpha: 0.12)
                            : p.muted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        q.done ? LucideIcons.circle_check : q.icon,
                        size: 18,
                        color: q.done ? AppDesign.brand : p.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.label,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: q.done ? p.muted : p.text,
                          decoration: q.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: q.done
                            ? p.muted.withValues(alpha: 0.12)
                            : AppDesign.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        q.done ? '✓' : '+${q.reward}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: q.done ? p.muted : AppDesign.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
