import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../services/data/services_catalog.dart';
import '../data/masters_data.dart';
import '../providers/master_reviews_provider.dart';
import 'booking_page.dart';
import 'master_reviews_page.dart';
import 'widgets/master_favorite_button.dart';

class MasterDetailPage extends ConsumerWidget {
  const MasterDetailPage({
    super.key,
    required this.master,
    this.selectedService,
  });

  final MasterItem master;
  final ServiceItem? selectedService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);
    final m = master;
    return Scaffold(
      backgroundColor: p.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PhotoHeader(m: m, s: s, p: p)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NameBlock(m: m, s: s, p: p, locale: locale),
                  const SizedBox(height: 16),
                  _StatsRow(m: m, s: s, p: p, onReviews: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MasterReviewsPage(master: m),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  _Section(title: s.aboutTitle, p: p, child: Text(
                    m.bio,
                    style: GoogleFonts.inter(fontSize: 13, color: p.text, height: 1.5),
                  )),
                  const SizedBox(height: 18),
                  _PortfolioGallery(m: m, p: p),
                  const SizedBox(height: 18),
                  _ServicesPrices(m: m, s: s, p: p, locale: locale),
                  const SizedBox(height: 18),
                  _Section(
                    title: s.districtsTitle,
                    p: p,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: m.districts
                          .map((d) => _Pill(label: d, icon: LucideIcons.map_pin, p: p))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        m: m,
        s: s,
        p: p,
        locale: locale,
        selectedService: selectedService,
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.m, required this.s, required this.p});

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'master-photo-${m.fullName}',
            child: m.imageBytes != null
                ? Image.memory(m.imageBytes!, fit: BoxFit.cover, alignment: Alignment.topCenter)
                : Image.asset(m.image, fit: BoxFit.cover, alignment: Alignment.topCenter),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(LucideIcons.arrow_left, size: 19, color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  MasterFavoriteButton(masterKey: m.fullName, lightBg: false, size: 38, iconSize: 18),
                ],
              ),
            ),
          ),
          if (m.isOnline)
            Positioned(
              left: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.onlineWord,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

class _NameBlock extends ConsumerWidget {
  const _NameBlock({required this.m, required this.s, required this.p, required this.locale});

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = reviewStatsForMaster(ref, m.fullName, fallbackRating: m.rating);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                m.fullName,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.badge_check, size: 20, color: Color(0xFF2F80ED)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          m.categoriesLabel(locale),
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: brandGreen),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.star, size: 16, color: Color(0xFFFFC107)),
            const SizedBox(width: 4),
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(width: 4),
            Text(
              '(${stats.count} ${s.reviewsWord})',
              style: GoogleFonts.inter(fontSize: 12.5, color: p.muted),
            ),
            const SizedBox(width: 10),
            if (m.isTop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.star, size: 11, color: Color(0xFFB7791F)),
                    const SizedBox(width: 3),
                    Text(
                      s.badgeTop,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB7791F),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({
    required this.m,
    required this.s,
    required this.p,
    required this.onReviews,
  });

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = reviewStatsForMaster(ref, m.fullName, fallbackRating: m.rating);

    Widget cell(IconData icon, String value, String label, {VoidCallback? onTap}) {
      final child = Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: brandGreen),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, color: p.muted, height: 1.2),
            ),
          ],
        ),
      );
      return Expanded(
        child: onTap == null
            ? child
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
              ),
      );
    }

    return Row(
      children: [
        cell(LucideIcons.briefcase, '${m.experienceYears}+', '${s.expWord} (${s.yearsShort})'),
        const SizedBox(width: 10),
        cell(LucideIcons.clipboard_check, '${m.completedOrders}', s.completedWord),
        const SizedBox(width: 10),
        cell(
          LucideIcons.star,
          stats.averageRating.toStringAsFixed(1),
          '${s.reviewsTitle} (${stats.count})',
          onTap: onReviews,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, required this.p});

  final String title;
  final Widget child;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ── Portfolio gallery — horizontal scroll of work photos ──
class _PortfolioGallery extends StatelessWidget {
  const _PortfolioGallery({required this.m, required this.p});

  final MasterItem m;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    // Use master avatar + generic work images as portfolio placeholders
    final images = <String>[
      m.image,
      'assets/images/master_1.png',
      'assets/images/master_2.png',
      'assets/images/master_3.png',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Портфолио работ',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${images.length}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: brandGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => _openFullscreen(context, images, i),
                child: Hero(
                  tag: 'portfolio-${m.fullName}-$i',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        (m.imageBytes != null && i == 0)
                            ? Image.memory(m.imageBytes!, width: 130, height: 130, fit: BoxFit.cover)
                            : Image.asset(images[i], width: 130, height: 130, fit: BoxFit.cover),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.maximize_2, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, List<String> images, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullscreenGallery(
          images: images,
          initialIndex: index,
          heroPrefix: 'portfolio-${m.fullName}',
          imageBytes: m.imageBytes,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  const _FullscreenGallery({
    required this.images,
    required this.initialIndex,
    required this.heroPrefix,
    this.imageBytes,
  });

  final List<String> images;
  final int initialIndex;
  final String heroPrefix;
  final dynamic imageBytes;

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: images.length,
            itemBuilder: (context, i) {
              return Center(
                child: Hero(
                  tag: '$heroPrefix-$i',
                  child: InteractiveViewer(
                    child: (imageBytes != null && i == 0)
                        ? Image.memory(imageBytes!, fit: BoxFit.contain)
                        : Image.asset(images[i], fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.4),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(LucideIcons.x, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesPrices extends StatelessWidget {
  const _ServicesPrices({
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
  });

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final cats = masterServiceCategories(m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.servicesPricesTitle,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
        ),
        const SizedBox(height: 12),
        for (final cat in cats) ...[
          _CategoryServices(cat: cat, m: m, s: s, p: p, locale: locale),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CategoryServices extends StatelessWidget {
  const _CategoryServices({
    required this.cat,
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
  });

  final ServiceCategory cat;
  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, size: 18, color: cat.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.name(locale),
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.text),
                  ),
                ),
                Text(
                  '${cat.services.length} ${s.servicesCountWord}',
                  style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: p.border),
          for (var i = 0; i < cat.services.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: p.border.withValues(alpha: 0.6)),
            _ServicePriceRow(svc: cat.services[i], m: m, s: s, p: p, locale: locale),
          ],
        ],
      ),
    );
  }
}

class _ServicePriceRow extends StatelessWidget {
  const _ServicePriceRow({
    required this.svc,
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
  });

  final ServiceItem svc;
  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final unitSuffix = svc.unit == 'шт' ? '' : '/${svc.unitLabel(locale)}';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingPage(
              master: m,
              serviceName: svc.name(locale),
              serviceTitleRu: svc.ru,
              servicePrice: svc.priceAvg.toDouble(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                svc.name(locale),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: p.text),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${s.fromPrice} ${_money(svc.priceMin)} ${s.priceUnit}$unitSuffix',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: brandGreen),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevron_right, size: 16, color: p.muted),
          ],
        ),
      ),
    );
  }

  static String _money(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.p, this.icon});

  final String label;
  final HomePalette p;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: brandGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: brandGreen),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: brandGreen),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
    this.selectedService,
  });

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final ServiceItem? selectedService;

  @override
  Widget build(BuildContext context) {
    final svc = selectedService ?? defaultServiceForMaster(m);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: p.cardBg,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandGreen,
                    side: const BorderSide(color: brandGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.message_circle, size: 18),
                  label: Text(
                    s.chatBtn,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (svc == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BookingPage(
                          master: m,
                          serviceName: svc.name(locale),
                          serviceTitleRu: svc.ru,
                          servicePrice: svc.priceAvg.toDouble(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.calendar_check, size: 18),
                  label: Text(
                    s.bookBtn,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
