import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/home_strings.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/motion.dart';
import '../../home/presentation/home_palette.dart';
import '../../masters/presentation/masters_page.dart';
import '../data/services_catalog.dart';

/// Страница категории услуг (Электрика, Сантехника и т.д.) — одна для всех категорий.
class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    super.key,
    required this.category,
    required this.locale,
  });

  final ServiceCategory category;
  final AppLocale locale;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchCtrl.clear();
      }
    });
    if (_searching) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  void _order(ServiceItem service) {
    Navigator.of(context).push(
      SmoothRoute<void>(
        builder: (_) => MastersPage(
          initialFilter: widget.category.ru,
          initialService: service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final s = HomeStrings.of(widget.locale);
    final category = widget.category;
    final all = category.services;
    final q = _query.trim().toLowerCase();
    final services = q.isEmpty
        ? all
        : all.where((sv) => sv.name(widget.locale).toLowerCase().contains(q) || sv.ru.toLowerCase().contains(q)).toList();
    final minPrice = all.isEmpty ? 0 : all.map((e) => e.priceMin).reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: p.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              category: category,
              locale: widget.locale,
              s: s,
              minPrice: minPrice,
              searching: _searching,
              searchCtrl: _searchCtrl,
              searchFocus: _searchFocus,
              onSearch: _toggleSearch,
              onQuery: (v) => setState(() => _query = v),
            ),
          ),
          if (services.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                child: Reveal(
                  child: Column(
                    children: [
                      FloatY(
                        amplitude: 5,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.search_x, color: category.color, size: 34),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ничего не найдено',
                        style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Попробуйте другое слово или посмотрите все услуги категории',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList.separated(
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Reveal(
                  key: ValueKey('svc-${services[i].ru}-$q'),
                  delay: Duration(milliseconds: 60 * (i % 10)),
                  offsetY: 24,
                  child: _ServiceCard(
                    service: services[i],
                    category: category,
                    locale: widget.locale,
                    s: s,
                    p: p,
                    index: i,
                    onOrder: () => _order(services[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Короткие подписи на 4 языках.
String _t(AppLocale l, String ru, String en, String tg, String zh) =>
    switch (l) { AppLocale.ru => ru, AppLocale.en => en, AppLocale.tg => tg, AppLocale.zh => zh };

// ─── Шапка категории ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.category,
    required this.locale,
    required this.s,
    required this.minPrice,
    required this.searching,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onSearch,
    required this.onQuery,
  });

  final ServiceCategory category;
  final AppLocale locale;
  final HomeStrings s;
  final int minPrice;
  final bool searching;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final VoidCallback onSearch;
  final ValueChanged<String> onQuery;

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(text, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(c, Colors.white, 0.08)!, c, Color.lerp(c, Colors.black, 0.18)!],
          ),
        ),
        child: Stack(
          children: [
            // Плавающие круги и большая полупрозрачная иконка категории
            Positioned(
              right: -30,
              top: -20,
              child: FloatY(
                amplitude: 8,
                period: const Duration(milliseconds: 4600),
                child: Icon(category.icon, size: 170, color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -50,
              child: FloatY(
                amplitude: 6,
                phase: 0.5,
                period: const Duration(milliseconds: 5400),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CircleBtn(icon: LucideIcons.arrow_left, onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 10),
                      // Поиск по услугам категории — раскрывается по нажатию на лупу.
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SizeTransition(sizeFactor: a, axis: Axis.horizontal, axisAlignment: 1, child: child),
                          ),
                          child: searching
                              ? Container(
                                  key: const ValueKey('search'),
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.search, size: 16, color: c),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: searchCtrl,
                                          focusNode: searchFocus,
                                          onChanged: onQuery,
                                          cursorColor: c,
                                          style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF111827)),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                            hintText: _t(locale, 'Найти услугу...', 'Find a service...', 'Ҷустуҷӯи хизмат...', '搜索服务...'),
                                            hintStyle: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF9CA3AF)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(key: ValueKey('none'), height: 40),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _CircleBtn(icon: searching ? LucideIcons.x : LucideIcons.search, onTap: onSearch),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Reveal(
                        offsetY: 0,
                        offsetX: -20,
                        child: FloatY(
                          amplitude: 3,
                          child: PulseRing(
                            color: Colors.white,
                            size: 62,
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Icon(category.icon, color: Colors.white, size: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Reveal(
                          delay: const Duration(milliseconds: 80),
                          offsetY: 0,
                          offsetX: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name(locale),
                                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _t(locale, 'Проверенные мастера · выезд по Душанбе', 'Verified masters · across Dushanbe',
                                    'Устоҳои санҷидашуда · дар Душанбе', '认证师傅 · 杜尚别上门'),
                                style: GoogleFonts.manrope(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Reveal(
                    delay: const Duration(milliseconds: 160),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(LucideIcons.layout_grid, '${category.services.length} ${s.servicesCountWord}'),
                        if (minPrice > 0) _chip(LucideIcons.tag, '${_t(locale, 'от', 'from', 'аз', '起')} $minPrice ${s.priceUnit}'),
                        _chip(LucideIcons.shield_check, _t(locale, 'Гарантия', 'Warranty', 'Кафолат', '保修')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 20,
      lift: 2,
      scale: 1.08,
      child: Material(
        color: Colors.white.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(a), child: c),
              child: Icon(icon, key: ValueKey(icon), color: Colors.white, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Карточка услуги ──────────────────────────────────────────────────────────

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({
    required this.service,
    required this.category,
    required this.locale,
    required this.s,
    required this.p,
    required this.index,
    required this.onOrder,
  });

  final ServiceItem service;
  final ServiceCategory category;
  final AppLocale locale;
  final HomeStrings s;
  final HomePalette p;
  final int index;
  final VoidCallback onOrder;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sv = widget.service;
    final p = widget.p;
    final s = widget.s;
    final accent = widget.category.color;
    final span = (sv.priceMax - sv.priceMin).clamp(1, 1 << 30);
    final avgPos = ((sv.priceAvg - sv.priceMin) / span).clamp(0.0, 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOrder,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hover ? 1.012 : 1),
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _hover ? accent.withValues(alpha: 0.5) : p.border, width: _hover ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: (_hover ? accent : Colors.black).withValues(alpha: _hover ? 0.18 : 0.05),
                  blurRadius: _hover ? 22 : 10,
                  offset: Offset(0, _hover ? 10 : 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Иконка категории
                    AnimatedRotation(
                      turns: _hover ? -0.03 : 0,
                      duration: const Duration(milliseconds: 260),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.08)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(widget.category.icon, color: accent, size: 21),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sv.name(widget.locale),
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text, height: 1.2),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${s.perUnit} 1 ${sv.unitLabel(widget.locale)}',
                              style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700, color: accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: sv.priceAvg.toDouble()),
                          duration: Duration(milliseconds: 700 + 60 * (widget.index % 6)),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Text(
                            '${v.round()} ${s.priceUnit}',
                            style: GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w900, color: brandGreen),
                          ),
                        ),
                        Text(
                          _t(widget.locale, 'средняя цена', 'average price', 'нархи миёна', '平均价格'),
                          style: GoogleFonts.manrope(fontSize: 10, color: p.muted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Полоска диапазона цен: от — средняя — до
                Row(
                  children: [
                    Text('${sv.priceMin}', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.muted)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          return SizedBox(
                            height: 14,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [brandGreen.withValues(alpha: 0.25), accent.withValues(alpha: 0.35)],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: avgPos),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutBack,
                                  builder: (context, t, _) => Positioned(
                                    left: (box.maxWidth - 14) * t.clamp(0.0, 1.0),
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: brandGreen, width: 3),
                                        boxShadow: [
                                          BoxShadow(color: brandGreen.withValues(alpha: 0.4), blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${sv.priceMax} ${s.priceUnit}', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.muted)),
                  ],
                ),
                const SizedBox(height: 14),
                // Кнопка «Заказать»
                ShineSweep(
                  radius: 13,
                  delay: Duration(milliseconds: 600 + 300 * (widget.index % 5)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: brandGreen.withValues(alpha: _hover ? 0.45 : 0.28),
                          blurRadius: _hover ? 16 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.user_round, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          s.orderBtn,
                          style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        AnimatedSlide(
                          offset: Offset(_hover ? 0.4 : 0, 0),
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(LucideIcons.arrow_right, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
