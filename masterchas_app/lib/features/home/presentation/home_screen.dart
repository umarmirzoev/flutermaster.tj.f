import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:masterchas_app/core/l10n/app_locale.dart';
import 'package:masterchas_app/core/l10n/home_strings.dart';
import 'package:masterchas_app/core/providers/home_tab_provider.dart';
import 'package:masterchas_app/core/providers/locale_provider.dart';
import 'package:masterchas_app/core/providers/theme_mode_provider.dart';
import 'package:masterchas_app/features/home/presentation/home_palette.dart';
import 'package:masterchas_app/features/masters/data/masters_data.dart';
import 'package:masterchas_app/features/masters/presentation/ai_master_picker_sheet.dart';
import 'package:masterchas_app/features/masters/presentation/master_detail_page.dart';
import 'package:masterchas_app/features/masters/presentation/masters_page.dart';
import 'package:masterchas_app/features/services/data/services_catalog.dart';
import 'package:masterchas_app/features/services/presentation/category_detail_page.dart';
import 'package:masterchas_app/features/shop/presentation/shop_page.dart';
import 'package:masterchas_app/features/chat/presentation/chats_list_page.dart';
import 'package:masterchas_app/features/profile/presentation/profile_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _nav = 0;
  final _homeSearchController = TextEditingController();
  String _homeQuery = '';

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  void _openCategory(ServiceCategory cat) {
    final locale = ref.read(localeProvider);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailPage(category: cat, locale: locale),
      ),
    );
  }

  void _openServicesTab() => setState(() => _nav = 1);

  TextStyle _s(
    HomePalette p, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.3,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? p.text,
        height: height,
      );

  void _showLanguagePicker(HomeStrings s, AppLocale current) {
    final p = HomePalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(s.chooseLanguage, style: _s(p, size: 17, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...AppLocale.values.map((locale) {
                final selected = locale == current;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected ? LucideIcons.circle_check : LucideIcons.circle,
                    color: selected ? brandGreen : p.muted,
                    size: 22,
                  ),
                  title: Text(
                    locale.label,
                    style: _s(
                      p,
                      size: 15,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? brandGreen : p.text,
                    ),
                  ),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(locale);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSheet(HomeStrings s) {
    final p = HomePalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.pageBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Widget action({
          required IconData icon,
          required Color color,
          required String title,
          required String sub,
          required VoidCallback onTap,
        }) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: _s(p, size: 16, weight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(sub, style: _s(p, size: 12, color: p.muted, height: 1.3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.chevron_right, size: 20, color: p.muted),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.fabTitle, style: _s(p, size: 20, weight: FontWeight.w800)),
                const SizedBox(height: 16),
                action(
                  icon: LucideIcons.wrench,
                  color: brandGreen,
                  title: s.fabCallTitle,
                  sub: s.fabCallSub,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MastersPage()),
                    );
                  },
                ),
                action(
                  icon: LucideIcons.user_plus,
                  color: const Color(0xFFF59E0B),
                  title: s.fabBecomeTitle,
                  sub: s.fabBecomeSub,
                  onTap: () => Navigator.pop(ctx),
                ),
                action(
                  icon: LucideIcons.shopping_bag,
                  color: const Color(0xFF3B82F6),
                  title: s.fabShopTitle,
                  sub: s.fabShopSub,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ShopPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeTabProvider, (previous, next) {
      if (next != _nav) setState(() => _nav = next);
    });

    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);
    final isDark = themeMode == ThemeMode.dark;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: p.pageBg,
      body: IndexedStack(
        index: _nav,
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 108),
                  children: [
                    _TopBar(
                      s: s,
                      p: p,
                      isDark: isDark,
                      onLanguage: () => _showLanguagePicker(s, locale),
                      onThemeToggle: () => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    const SizedBox(height: 12),
                    _SearchBar(
                      s: s,
                      p: p,
                      controller: _homeSearchController,
                      onChanged: (v) => setState(() => _homeQuery = v),
                      onClear: () {
                        _homeSearchController.clear();
                        setState(() => _homeQuery = '');
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_homeQuery.trim().isNotEmpty)
                      _HomeSearchResults(
                        query: _homeQuery,
                        s: s,
                        p: p,
                        locale: locale,
                        onCategory: _openCategory,
                        onShowAllServices: _openServicesTab,
                      )
                    else ...[
                    _TrustRow(s: s, p: p),
                    const SizedBox(height: 12),
                    _PromoRow(s: s, p: p),
                    const SizedBox(height: 18),
                    _Categories(
                      s: s,
                      p: p,
                      locale: locale,
                      onCategory: _openCategory,
                      onShowAll: _openServicesTab,
                    ),
                    const SizedBox(height: 16),
                    _DiscountBanner(s: s, p: p),
                    const SizedBox(height: 18),
                    _HowItWorks(s: s, p: p),
                    const SizedBox(height: 22),
                    _PopularMasters(s: s, p: p, locale: locale),
                    const SizedBox(height: 22),
                    _ClientReviews(s: s, p: p),
                    const SizedBox(height: 22),
                    _AiBigBanner(s: s, p: p, onPick: () => showAiMasterPickerSheet(context)),
                    const SizedBox(height: 16),
                    _StatsRow(s: s, p: p),
                    const SizedBox(height: 22),
                    _ToolsShop(s: s, p: p),
                    const SizedBox(height: 22),
                    _MoreFeatures(s: s, p: p),
                    const SizedBox(height: 18),
                    _DiscountBanner2(s: s, p: p),
                    const SizedBox(height: 18),
                    _AllToolsCard(s: s, p: p),
                    ],
                  ],
                ),
                _ServicesPage(s: s, p: p, locale: locale),
                _ChatsTabPage(p: p),
          const ProfilePage(),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () => _showActionSheet(s),
          backgroundColor: brandGreen,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        s: s,
        p: p,
        current: _nav,
        onTap: (i) => setState(() => _nav = i),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.s,
    required this.p,
    required this.isDark,
    required this.onLanguage,
    required this.onThemeToggle,
  });

  final HomeStrings s;
  final HomePalette p;
  final bool isDark;
  final VoidCallback onLanguage;
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    TextStyle ts({required double size, FontWeight w = FontWeight.w400, Color? c}) =>
        GoogleFonts.inter(fontSize: size, fontWeight: w, color: c ?? p.text);

    return Row(
      children: [
        const Icon(LucideIcons.map_pin, color: brandGreen, size: 17),
        const SizedBox(width: 4),
        Text(s.city, style: ts(size: 15, w: FontWeight.w600)),
        Icon(LucideIcons.chevron_down, size: 15, color: p.muted),
        const Spacer(),
        _IconBtn(p: p, icon: LucideIcons.globe, onTap: onLanguage),
        const SizedBox(width: 8),
        _IconBtn(
          p: p,
          icon: isDark ? LucideIcons.moon : LucideIcons.sun,
          onTap: onThemeToggle,
        ),
        const SizedBox(width: 8),
        _IconBtn(p: p, icon: LucideIcons.bell, onTap: () {}),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.p, required this.icon, required this.onTap});

  final HomePalette p;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, size: 16, color: p.text),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.s,
    required this.p,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final HomeStrings s;
  final HomePalette p;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.isNotEmpty;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: p.searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.only(left: 12, right: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: brandGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: brandGreen,
              style: GoogleFonts.inter(fontSize: 13, color: p.text),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: s.searchPlaceholder,
                hintStyle: GoogleFonts.inter(fontSize: 13, color: p.muted),
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(LucideIcons.x, size: 17, color: p.muted),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: brandGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.sliders_horizontal, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }
}

class _HomeSearchResults extends StatelessWidget {
  const _HomeSearchResults({
    required this.query,
    required this.s,
    required this.p,
    required this.locale,
    required this.onCategory,
    required this.onShowAllServices,
  });

  final String query;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final ValueChanged<ServiceCategory> onCategory;
  final VoidCallback onShowAllServices;

  bool _nameHas(String ru, String tj, String en, String q) =>
      ru.toLowerCase().contains(q) ||
      tj.toLowerCase().contains(q) ||
      en.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    final matchedCats = serviceCatalog.where((c) => _nameHas(c.ru, c.tj, c.en, q)).toList();

    final matchedServices = <(ServiceCategory, ServiceItem)>[];
    for (final cat in serviceCatalog) {
      for (final svc in cat.services) {
        if (_nameHas(svc.ru, svc.tj, svc.en, q)) {
          matchedServices.add((cat, svc));
        }
      }
    }

    final matchedMasters = masters.where((m) {
      if (m.fullName.toLowerCase().contains(q)) return true;
      if (m.bio.toLowerCase().contains(q)) return true;
      if (m.profession(locale).toLowerCase().contains(q)) return true;
      return m.categories.any((c) => localizedCategory(c, locale).toLowerCase().contains(q));
    }).toList();

    final nothingFound =
        matchedCats.isEmpty && matchedServices.isEmpty && matchedMasters.isEmpty;

    if (nothingFound) {
      return Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 24),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.search_x, size: 40, color: p.muted),
              const SizedBox(height: 10),
              Text(
                '«$query»',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matchedCats.isNotEmpty) ...[
          Text(
            s.categories,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 10),
          ...matchedCats.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HomeSearchCategoryRow(
                cat: cat,
                locale: locale,
                p: p,
                onTap: () => onCategory(cat),
              ),
            ),
          ),
        ],
        if (matchedServices.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            s.navServices,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 10),
          ...matchedServices.map(
            (pair) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ServiceResultRow(
                cat: pair.$1,
                svc: pair.$2,
                s: s,
                p: p,
                locale: locale,
                onTap: () => onCategory(pair.$1),
              ),
            ),
          ),
        ],
        if (matchedMasters.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            s.popularMasters,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 10),
          ...matchedMasters.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HomeSearchMasterRow(
                master: m,
                s: s,
                p: p,
                locale: locale,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onShowAllServices,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(
                s.all,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: brandGreen),
              ),
              const Icon(LucideIcons.chevron_right, size: 15, color: brandGreen),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HomeSearchCategoryRow extends StatelessWidget {
  const _HomeSearchCategoryRow({
    required this.cat,
    required this.locale,
    required this.p,
    required this.onTap,
  });

  final ServiceCategory cat;
  final AppLocale locale;
  final HomePalette p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(cat.icon, size: 20, color: cat.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat.name(locale),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
                ),
              ),
              Icon(LucideIcons.chevron_right, size: 18, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSearchMasterRow extends StatelessWidget {
  const _HomeSearchMasterRow({
    required this.master,
    required this.s,
    required this.p,
    required this.locale,
  });

  final MasterItem master;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => MasterDetailPage(master: master)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(master.image, width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      master.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      master.profession(locale),
                      style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFC107)),
                  const SizedBox(width: 3),
                  Text(
                    master.rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.shield_check, s.trustWarranty),
      (LucideIcons.users, s.trustVerified),
      (LucideIcons.clock, s.trustResponse),
      (LucideIcons.file_text, s.trustPe),
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (icon, label) = items[i];
          return Container(
            width: 128,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: brandGreen),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: p.text,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PromoRow extends StatelessWidget {
  const _PromoRow({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(child: _AiCard(s: s, onTap: () => showAiMasterPickerSheet(context))),
          const SizedBox(width: 8),
          Expanded(child: _MasterCard(s: s, p: p)),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.s, required this.onTap});

  final HomeStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const RadialGradient(
              center: Alignment(0.55, -0.1),
              radius: 1.1,
              colors: [Color(0xFF1C5743), Color(0xFF0C271D)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _SparklePainter())),
              Positioned(
                right: -10,
                top: 22,
                bottom: 18,
                child: Image.asset(
                  'assets/images/home_ai_robot.png',
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: brandGreen,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        s.badgeNew,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.aiTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.aiSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(right: 10, bottom: 10, child: _ArrowBtn(dark: true)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const dots = [
      (0.62, 0.16, 1.6, 0.9),
      (0.78, 0.10, 1.1, 0.7),
      (0.90, 0.22, 1.4, 0.8),
      (0.70, 0.30, 1.0, 0.6),
      (0.84, 0.40, 1.3, 0.7),
      (0.58, 0.42, 0.9, 0.5),
      (0.94, 0.55, 1.0, 0.6),
      (0.66, 0.62, 1.2, 0.6),
      (0.80, 0.72, 1.0, 0.5),
      (0.50, 0.22, 0.8, 0.5),
    ];
    for (final (dx, dy, r, a) in dots) {
      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(size.width * dx, size.height * dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  void _openMasters(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MastersPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openMasters(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF26312B), Color(0xFF1C2A22)]
                  : const [Color(0xFFF6FAF4), Color(0xFFD8ECD2)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: 0,
                top: 6,
                child: Image.asset(
                  'assets/images/home_handyman.png',
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.masterTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.masterSubtitle,
                      style: GoogleFonts.inter(fontSize: 9.5, color: p.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 13, color: Colors.white),
                ),
              ),
              const Positioned(right: 10, bottom: 10, child: _ArrowBtn(dark: false)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.18) : brandGreen,
        shape: BoxShape.circle,
        border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.5)) : null,
      ),
      child: const Icon(LucideIcons.arrow_right, color: Colors.white, size: 15),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({
    required this.s,
    required this.p,
    required this.locale,
    required this.onCategory,
    required this.onShowAll,
  });

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final ValueChanged<ServiceCategory> onCategory;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final featured = serviceCatalog.take(4).toList();
    final cats = <(IconData, String, Color, ServiceCategory?)>[
      (LucideIcons.zap, s.catElectrical, const Color(0xFFF59E0B), featured[0]),
      (LucideIcons.droplet, s.catPlumbing, const Color(0xFF3B82F6), featured[1]),
      (LucideIcons.paint_roller, s.catFinishing, brandGreen, featured[2]),
      (LucideIcons.armchair, s.catFurniture, const Color(0xFF8B5CF6), featured[3]),
      (LucideIcons.ellipsis, s.catMore, p.muted, null),
    ];

    return Column(
      children: [
        Row(
          children: [
            Text(
              s.categories,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onShowAll,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    s.all,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: brandGreen),
                  ),
                  const Icon(LucideIcons.chevron_right, size: 15, color: brandGreen),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = cats[i];
              return Material(
                color: p.cardBg,
                borderRadius: BorderRadius.circular(16),
                elevation: Theme.of(context).brightness == Brightness.light ? 1 : 0,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                child: InkWell(
                  onTap: () {
                    if (c.$4 != null) {
                      onCategory(c.$4!);
                    } else {
                      onShowAll();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.$1, color: c.$3, size: 24),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            c.$2,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: p.text,
                              height: 1.1,
                            ),
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
}

class _DiscountBanner extends StatelessWidget {
  const _DiscountBanner({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4BAF50), Color(0xFF57B55E)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 130,
            child: Image.asset(
              'assets/images/home_cleaner.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF4BAF50),
                  const Color(0xFF57B55E).withValues(alpha: 0.85),
                  const Color(0xFF57B55E).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    s.discountBadge,
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.discountTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.promoCodeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.promoCodeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: p.promoCodeText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(right: 12, bottom: 12, child: _ArrowBtn()),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (s.step1Title, s.step1Sub),
      (s.step2Title, s.step2Sub),
      (s.step3Title, s.step3Sub),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.howItWorks,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (i) {
            final (title, sub) = steps[i];
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 9, color: p.muted, height: 1.35),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.s,
    required this.p,
    required this.current,
    required this.onTap,
  });

  final HomeStrings s;
  final HomePalette p;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (0, LucideIcons.house, s.navHome),
      (1, LucideIcons.layout_grid, s.navServices),
      (2, LucideIcons.message_circle, s.navChats),
      (3, LucideIcons.user, s.navProfile),
    ];

    return SafeArea(
      top: false,
      child: BottomAppBar(
        color: p.cardBg,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        notchMargin: 6,
        height: 72,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            Expanded(child: _item(items[0].$1, items[0].$2, items[0].$3)),
            Expanded(child: _item(items[1].$1, items[1].$2, items[1].$3)),
            const SizedBox(width: 52),
            Expanded(child: _item(items[2].$1, items[2].$2, items[2].$3)),
            Expanded(child: _item(items[3].$1, items[3].$2, items[3].$3)),
          ],
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final on = current == i;
    final c = on ? brandGreen : p.muted;
    return InkWell(
      onTap: () => onTap(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.p, this.onAction});

  final String title;
  final String action;
  final HomePalette p;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(
                action,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: brandGreen),
              ),
              const Icon(LucideIcons.chevron_right, size: 15, color: brandGreen),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Popular masters ──────────────────────────────────────────────────────────

class _PopularMasters extends StatelessWidget {
  const _PopularMasters({required this.s, required this.p, required this.locale});

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final list = masters.where((m) => m.isTop).take(6).toList();

    void openMasters() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MastersPage()),
      );
    }

    return Column(
      children: [
        _SectionHeader(
          title: s.popularMasters,
          action: s.allMasters,
          p: p,
          onAction: openMasters,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 340,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _PopularMasterCard(m: list[i], s: s, p: p, locale: locale),
          ),
        ),
      ],
    );
  }
}

class _PopularMasterCard extends StatelessWidget {
  const _PopularMasterCard({
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
  });

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MasterDetailPage(master: m)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: Theme.of(context).brightness == Brightness.light ? 1.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                height: 125,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(m.image, fit: BoxFit.cover, alignment: Alignment.topCenter),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: m.isTop ? const Color(0xFFFFC107) : brandGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.isTop ? LucideIcons.star : LucideIcons.shield_check,
                              size: 11,
                              color: m.isTop ? const Color(0xFF1C1C1C) : Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              m.isTop ? s.badgeTop : s.badgeVerified,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: m.isTop ? const Color(0xFF1C1C1C) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.heart, size: 15, color: Color(0xFF8B95A5)),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(masterArrivalIcon(m), size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${s.arrivalPrefix} 20 ${s.minShort}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text, height: 1.2),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          m.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '(${m.reviews} ${s.reviewsWord})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      m.profession(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: p.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.fromPrice} ${m.priceMin} ${s.priceUnit}',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: brandGreen),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _open(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(LucideIcons.phone, size: 15),
                        label: Text(
                          s.callBtn,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Client reviews ───────────────────────────────────────────────────────────

class _ReviewData {
  const _ReviewData({
    required this.author,
    required this.date,
    required this.body,
    required this.accent,
  });

  final String author;
  final String date;
  final String body;
  final Color accent;
}

class _ClientReviews extends StatelessWidget {
  const _ClientReviews({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final reviews = <_ReviewData>[
      _ReviewData(author: 'Анна К.', date: '20.05.2024', body: s.review1, accent: const Color(0xFFEC4899)),
      _ReviewData(author: 'Жахонгир И.', date: '18.05.2024', body: s.review2, accent: const Color(0xFF3B82F6)),
      _ReviewData(author: 'Мадина С.', date: '15.05.2024', body: s.review3, accent: const Color(0xFF8B5CF6)),
    ];

    return Column(
      children: [
        _SectionHeader(title: s.clientReviews, action: s.allReviews, p: p),
        const SizedBox(height: 12),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ReviewCard(r: reviews[i], p: p),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.r, required this.p});

  final _ReviewData r;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: r.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  r.author.characters.first,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: r.accent),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.author,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(
                      5,
                      (_) => const Icon(LucideIcons.star, size: 11, color: Color(0xFFFFC107)),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                r.date,
                style: GoogleFonts.inter(fontSize: 10, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              r.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12.5, color: p.text, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI big banner ────────────────────────────────────────────────────────────

class _AiBigBanner extends StatelessWidget {
  const _AiBigBanner({required this.s, required this.p, required this.onPick});

  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF12241B) : const Color(0xFFEAF5EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: brandGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/images/home_ai_robot.png', fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.aiBigTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.aiBigSub,
                      style: GoogleFonts.inter(fontSize: 11, color: p.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _aiStep(LucideIcons.pencil, s.aiStepDescribe, p),
              _aiArrow(p),
              _aiStep(LucideIcons.users, s.aiStepGet, p),
              _aiArrow(p),
              _aiStep(LucideIcons.shield_check, s.aiStepCompare, p),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPick,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                s.aiBigBtn,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiStep(IconData icon, String label, HomePalette p) {
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: brandGreen),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 8.5, color: p.muted, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _aiArrow(HomePalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Icon(LucideIcons.chevron_right, size: 14, color: p.muted),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (LucideIcons.users, '184', s.statMastersLabel),
      (LucideIcons.clipboard_check, '3500+', s.statOrdersLabel),
      (LucideIcons.shield_check, '98%', s.statClientsLabel),
      (LucideIcons.clock, s.statResponseValue, s.statResponseLabel),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (icon, value, label) = stats[i];
          return Container(
            width: 128,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: brandGreen),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 9.5, color: p.muted, height: 1.15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Tools shop ─────────────────────────────────────────────────────────────

class _ProductData {
  const _ProductData({required this.name, required this.image, required this.price});

  final String name;
  final String image;
  final int price;
}

class _ToolsShop extends StatelessWidget {
  const _ToolsShop({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final products = <_ProductData>[
      _ProductData(name: s.prodDrill, image: 'assets/images/tool_drill.png', price: 520),
      _ProductData(name: s.prodHammer, image: 'assets/images/tool_hammer.png', price: 120),
      _ProductData(name: s.prodToolSet, image: 'assets/images/tool_set.png', price: 290),
      _ProductData(name: s.prodLevel, image: 'assets/images/tool_level.png', price: 85),
    ];

    return Column(
      children: [
        _SectionHeader(title: s.toolsShop, action: s.all, p: p),
        const SizedBox(height: 12),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ProductCard(prod: products[i], s: s, p: p),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.prod, required this.s, required this.p});

  final _ProductData prod;
  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: Image.asset(prod.image, fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 34,
                  child: Text(
                    prod.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: p.text, height: 1.2),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${prod.price} ${s.priceUnit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.plus, size: 17, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── More features ────────────────────────────────────────────────────────────

class _MoreFeatures extends StatelessWidget {
  const _MoreFeatures({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final feats = [
      (LucideIcons.bot, s.featAiTitle, s.featAiSub),
      (LucideIcons.user_round, s.featPickTitle, s.featPickSub),
      (LucideIcons.file_text, s.featPeTitle, s.featPeSub),
      (LucideIcons.clipboard_list, s.featRequestsTitle, s.featRequestsSub),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.moreFeatures,
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: feats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final (icon, title, sub) = feats[i];
              return Container(
                width: 148,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 22, color: brandGreen),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text, height: 1.15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 9, color: p.muted, height: 1.2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Discount banner 2 ──────────────────────────────────────────────────────────

class _DiscountBanner2 extends StatelessWidget {
  const _DiscountBanner2({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: Image.asset('assets/images/home_cleaner.png', fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF2E7D32),
                  const Color(0xFF2E7D32).withValues(alpha: 0.85),
                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.disc2Title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.disc2Sub,
                  style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'MASTER20',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                      letterSpacing: 1,
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

// ─── All tools card ─────────────────────────────────────────────────────────────

class _AllToolsCard extends StatelessWidget {
  const _AllToolsCard({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final items = [
      s.toolPower,
      s.toolHand,
      s.toolMeasure,
      s.toolConsumable,
      s.toolProtection,
      s.toolMoreItem,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
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
                      s.allToolsTitle,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.allToolsSub,
                      style: GoogleFonts.inter(fontSize: 11, color: p.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                height: 70,
                child: Image.asset('assets/images/toolbox.png', fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: items.map((label) {
              return SizedBox(
                width: (MediaQuery.sizeOf(context).width - 64) / 2,
                child: Row(
                  children: [
                    const Icon(LucideIcons.circle_check, size: 16, color: brandGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, color: p.text, height: 1.2),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Services page (bottom-nav tab) ─────────────────────────────────────────────

class _ServicesPage extends StatefulWidget {
  const _ServicesPage({required this.s, required this.p, required this.locale});

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  State<_ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<_ServicesPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _nameHas(String ru, String tj, String en, String q) =>
      ru.toLowerCase().contains(q) ||
      tj.toLowerCase().contains(q) ||
      en.toLowerCase().contains(q);

  void _openCategory(ServiceCategory cat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailPage(category: cat, locale: widget.locale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = widget.p;
    final locale = widget.locale;
    final q = _query.trim().toLowerCase();

    final matchedCats = q.isEmpty
        ? serviceCatalog
        : serviceCatalog.where((c) => _nameHas(c.ru, c.tj, c.en, q)).toList();

    final matchedServices = <(ServiceCategory, ServiceItem)>[];
    if (q.isNotEmpty) {
      for (final cat in serviceCatalog) {
        for (final svc in cat.services) {
          if (_nameHas(svc.ru, svc.tj, svc.en, q)) {
            matchedServices.add((cat, svc));
          }
        }
      }
    }

    final nothingFound = q.isNotEmpty && matchedCats.isEmpty && matchedServices.isEmpty;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 108),
      children: [
        Text(
          s.navServices,
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: p.text),
        ),
        const SizedBox(height: 3),
        Text(
          s.servicesSubtitle,
          style: GoogleFonts.inter(fontSize: 13, color: p.muted),
        ),
        const SizedBox(height: 14),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(LucideIcons.search, size: 18, color: p.muted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  cursorColor: brandGreen,
                  style: GoogleFonts.inter(fontSize: 13, color: p.text),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: s.servicesSearch,
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: p.muted),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  child: Icon(LucideIcons.x, size: 17, color: p.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (nothingFound)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.search_x, size: 40, color: p.muted),
                  const SizedBox(height: 10),
                  Text(
                    '«$_query»',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
                  ),
                ],
              ),
            ),
          ),
        if (matchedCats.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchedCats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (_, i) => _ServiceCard(
              cat: matchedCats[i],
              s: s,
              p: p,
              locale: locale,
            ),
          ),
        if (matchedServices.isNotEmpty) ...[
          const SizedBox(height: 18),
          ...matchedServices.map(
            (pair) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ServiceResultRow(
                cat: pair.$1,
                svc: pair.$2,
                s: s,
                p: p,
                locale: locale,
                onTap: () => _openCategory(pair.$1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceResultRow extends StatelessWidget {
  const _ServiceResultRow({
    required this.cat,
    required this.svc,
    required this.s,
    required this.p,
    required this.locale,
    required this.onTap,
  });

  final ServiceCategory cat;
  final ServiceItem svc;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      elevation: Theme.of(context).brightness == Brightness.light ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(cat.icon, size: 20, color: cat.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      svc.name(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.name(locale),
                      style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${svc.priceAvg} ${s.priceUnit}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: brandGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.cat,
    required this.s,
    required this.p,
    required this.locale,
  });

  final ServiceCategory cat;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: Theme.of(context).brightness == Brightness.light ? 1.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CategoryDetailPage(category: cat, locale: locale),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(cat.icon, size: 24, color: cat.color),
              ),
              const SizedBox(height: 8),
              Text(
                cat.name(locale),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text, height: 1.1),
              ),
              const SizedBox(height: 3),
              Text(
                '${cat.services.length} ${s.servicesCountWord}',
                style: GoogleFonts.inter(fontSize: 9.5, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatsTabPage extends ConsumerWidget {
  const _ChatsTabPage({required this.p});

  final HomePalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Чаты',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
            ),
          ),
        ),
        Expanded(child: ChatsListPage(p: p)),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.icon, required this.title, required this.p});

  final IconData icon;
  final String title;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: brandGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: brandGreen),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
          ),
        ],
      ),
    );
  }
}
