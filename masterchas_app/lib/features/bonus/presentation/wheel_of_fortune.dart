import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_palette.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Колесо фортуны — ежедневный бонус. Крути раз в день, получай скидку.
/// ═══════════════════════════════════════════════════════════════════════════

class WheelOfFortuneSheet extends ConsumerStatefulWidget {
  const WheelOfFortuneSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WheelOfFortuneSheet(),
    );
  }

  @override
  ConsumerState<WheelOfFortuneSheet> createState() => _WheelOfFortuneSheetState();
}

class _WheelOfFortuneSheetState extends ConsumerState<WheelOfFortuneSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  final _rng = Random();
  bool _spun = false;
  int _resultIndex = 0;

  static const _prizeColors = <Color>[
    Color(0xFF57B55E),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
    Color(0xFF6B7280),
  ];

  List<String> _prizeLabels(HomeStrings s) => [
        '5%',
        '100 ${s.priceUnit}',
        '10%',
        '50 ${s.priceUnit}',
        '15%',
        '200 ${s.priceUnit}',
        '20%',
        s.wheelPrizeAgain,
      ];

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _doSpin() {
    if (_spun) return;
    HapticFeedback.mediumImpact();
    final labels = _prizeLabels(HomeStrings.of(ref.read(localeProvider)));
    _resultIndex = _rng.nextInt(labels.length);
    setState(() => _spun = true);
    _spin.forward(from: 0).then((_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final s = HomeStrings.of(ref.watch(localeProvider));
    final labels = _prizeLabels(s);
    final prizes = List.generate(
      labels.length,
      (i) => (label: labels[i], color: _prizeColors[i]),
    );
    final segAngle = 2 * pi / prizes.length;
    // Land pointer (top) on the result segment center
    final targetAngle = (2 * pi * 5) - (_resultIndex * segAngle) - segAngle / 2;

    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.gift, color: AppDesign.accentOrange, size: 22),
                const SizedBox(width: 8),
                Text(
                  s.wheelTitle,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: p.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _spun && _spin.isCompleted ? s.wheelCongrats : s.wheelSpinPrompt,
              style: GoogleFonts.inter(fontSize: 13, color: p.muted),
            ),
            const SizedBox(height: 24),
            // Wheel
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) {
                      final t = Curves.easeOutCubic.transform(_spin.value);
                      return Transform.rotate(
                        angle: t * targetAngle,
                        child: CustomPaint(
                          size: const Size(280, 280),
                          painter: _WheelPainter(prizes),
                        ),
                      );
                    },
                  ),
                  // Center cap
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppDesign.brandGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: AppDesign.brandGlow(),
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 24),
                  ),
                  // Pointer (top)
                  Positioned(
                    top: -4,
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(),
                      child: CustomPaint(
                        size: const Size(28, 28),
                        painter: _PointerPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Result or spin button
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                if (_spun && _spin.isCompleted) {
                  final prize = prizes[_resultIndex];
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: prize.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: prize.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.party_popper, color: prize.color, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              s.wheelPrizeLabel(prize.label),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: prize.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          label: s.wheelClaimBonus,
                          icon: LucideIcons.check,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ],
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: _spun ? s.wheelSpinning : s.wheelSpinWheelBtn,
                    icon: _spun ? null : LucideIcons.rotate_cw,
                    gradient: AppDesign.goldGradient,
                    glowColor: AppDesign.accentOrange,
                    loading: _spun && !_spin.isCompleted,
                    onPressed: _doSpin,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              s.wheelComeBackTomorrow,
              style: GoogleFonts.inter(fontSize: 11, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.prizes);
  final List<({String label, Color color})> prizes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = 2 * pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final start = -pi / 2 + i * segAngle - segAngle / 2;
      final paint = Paint()..color = prizes[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segAngle,
        true,
        paint,
      );
      // Segment border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segAngle,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label
      final labelAngle = start + segAngle / 2;
      final labelRadius = radius * 0.66;
      final lx = center.dx + cos(labelAngle) * labelRadius;
      final ly = center.dy + sin(labelAngle) * labelRadius;
      final tp = TextPainter(
        text: TextSpan(
          text: prizes[i].label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(labelAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF1C2438),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
