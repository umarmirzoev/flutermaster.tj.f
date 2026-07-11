import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/home_strings.dart';
import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_palette.dart';
import '../../masters/presentation/masters_page.dart';
import '../data/services_catalog.dart';

class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({
    super.key,
    required this.category,
    required this.locale,
  });

  final ServiceCategory category;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final s = HomeStrings.of(locale);

    return Scaffold(
      backgroundColor: p.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(category: category, locale: locale, s: s, p: p)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList.separated(
              itemCount: category.services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => FadeSlideIn(
                delay: Duration(milliseconds: 50 * (i % 8)),
                child: _ServiceRow(
                  service: category.services[i],
                  categoryRu: category.ru,
                  accent: category.color,
                  locale: locale,
                  s: s,
                  p: p,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.category, required this.locale, required this.s, required this.p});

  final ServiceCategory category;
  final AppLocale locale;
  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.color, category.color.withValues(alpha: 0.75)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circleBtn(
                icon: LucideIcons.arrow_left,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              _circleBtn(icon: LucideIcons.search, onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name(locale),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${category.services.length} ${s.servicesCountWord}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.categoryRu,
    required this.accent,
    required this.locale,
    required this.s,
    required this.p,
  });

  final ServiceItem service;
  final String categoryRu;
  final Color accent;
  final AppLocale locale;
  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name(locale),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${s.perUnit} 1 ${service.unitLabel(locale)}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${service.priceAvg} ${s.priceUnit}',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: brandGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.priceMin}–${service.priceMax} ${s.priceUnit}',
                    style: GoogleFonts.inter(fontSize: 10.5, color: p.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MastersPage(
                    initialFilter: categoryRu,
                    initialService: service,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.search, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    s.orderBtn,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.arrow_right, size: 15, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
