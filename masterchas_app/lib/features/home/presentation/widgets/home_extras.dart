import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/home_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_design.dart';
import '../home_palette.dart';

/// Плашка активного заказа — «Мастер в пути».
class ActiveOrderBanner extends StatefulWidget {
  const ActiveOrderBanner({
    super.key,
    required this.p,
    required this.s,
    this.masterName = 'Алишер Муродов',
    this.service,
    this.onTap,
  });

  final HomePalette p;
  final HomeStrings s;
  final String masterName;
  final String? service;
  final VoidCallback? onTap;

  @override
  State<ActiveOrderBanner> createState() => _ActiveOrderBannerState();
}

class _ActiveOrderBannerState extends State<ActiveOrderBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? widget.s.storyCaptionWiring;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppDesign.navyGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppDesign.navy.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppDesign.brand.withValues(alpha: 0.15 + _pulse.value * 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: AppDesign.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.navigation, color: Colors.white, size: 18),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppDesign.brand.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.s.activeOrderOnWay,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppDesign.brandLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '~15 ${widget.s.minShort}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.masterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.map, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Лента срочных заявок рядом.
class UrgentRequestsFeed extends ConsumerStatefulWidget {
  const UrgentRequestsFeed({super.key, required this.p});

  final HomePalette p;

  @override
  ConsumerState<UrgentRequestsFeed> createState() => _UrgentRequestsFeedState();
}

class _UrgentRequestsFeedState extends ConsumerState<UrgentRequestsFeed> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        final count = _requests.length;
        if (count > 0) setState(() => _index = (_index + 1) % count);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<({String text, String distance, IconData icon, Color color})> get _requests {
    final s = HomeStrings.of(ref.watch(localeProvider));
    return [
      (text: s.urgentElectrician, distance: '2 km', icon: LucideIcons.zap, color: const Color(0xFFF59E0B)),
      (text: s.urgentPlumber, distance: '800 m', icon: LucideIcons.droplet, color: const Color(0xFF3B82F6)),
      (text: s.urgentPainter, distance: '1.5 km', icon: LucideIcons.paint_roller, color: const Color(0xFF8B5CF6)),
      (text: s.urgentFurniture, distance: '3 km', icon: LucideIcons.armchair, color: const Color(0xFF14B8A6)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = HomeStrings.of(ref.watch(localeProvider));
    final requests = _requests;
    if (requests.isEmpty) return const SizedBox.shrink();
    final r = requests[_index % requests.length];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            s.urgentNearbyTitle,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: p.muted),
          ),
          const Spacer(),
          Expanded(
            flex: 5,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Row(
                key: ValueKey('$_index-${s.urgentNearbyTitle}'),
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(r.icon, size: 15, color: r.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      r.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${r.distance}',
                    style: GoogleFonts.inter(fontSize: 12, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка «Бонус дня» — открывает колесо фортуны.
class DailyBonusCard extends ConsumerStatefulWidget {
  const DailyBonusCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  ConsumerState<DailyBonusCard> createState() => _DailyBonusCardState();
}

class _DailyBonusCardState extends ConsumerState<DailyBonusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loop();
  }

  void _loop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      await _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = HomeStrings.of(ref.watch(localeProvider));
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppDesign.goldGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppDesign.glowShadow(AppDesign.accentOrange),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final wobble = _shake.value < 0.5
                    ? _shake.value * 2
                    : (1 - _shake.value) * 2;
                return Transform.rotate(
                  angle: wobble * 0.3 * (_shake.value * 10 % 2 < 1 ? 1 : -1),
                  child: child,
                );
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.gift, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.dailyBonusWaitingTitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    s.dailyBonusWaitingSub,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.spinBtn,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppDesign.accentOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
