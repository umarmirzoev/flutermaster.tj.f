import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masterchas_app/core/widgets/motion.dart';
import 'package:masterchas_app/features/home/presentation/widgets/ai_call_sheet.dart';
import 'package:go_router/go_router.dart';
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
import 'package:masterchas_app/features/masters/presentation/master_reviews_page.dart';
import 'package:masterchas_app/features/masters/presentation/widgets/master_favorite_button.dart';
import 'package:masterchas_app/features/masters/providers/master_reviews_provider.dart';
import 'package:masterchas_app/features/services/data/services_catalog.dart';
import 'package:masterchas_app/features/services/presentation/category_detail_page.dart';
import 'package:masterchas_app/features/shop/presentation/shop_page.dart';
import 'package:masterchas_app/features/shop/data/shop_data.dart' show ShopProduct, buildShopProductImage;
import 'package:masterchas_app/features/shop/state/shop_state.dart' show shopCartProvider;
import 'package:masterchas_app/core/providers/catalog_provider.dart' show shopCatalogProvider;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:masterchas_app/features/auth/providers/auth_provider.dart';
import 'package:masterchas_app/features/auth/providers/master_registration_draft_provider.dart';
import 'package:masterchas_app/features/chat/presentation/chats_list_page.dart';
import 'package:masterchas_app/features/chat/providers/chat_provider.dart' show unreadChatsTotalProvider;
import 'package:masterchas_app/features/profile/presentation/profile_page.dart';
import 'package:masterchas_app/features/sos/presentation/sos_emergency_screen.dart';
import 'package:masterchas_app/features/auction/presentation/auction_screen.dart';
import 'package:masterchas_app/features/ai_diagnosis/presentation/ai_diagnosis_screen.dart';
import 'package:masterchas_app/features/stories/presentation/master_stories.dart';
import 'package:masterchas_app/core/theme/app_design.dart';
import 'package:masterchas_app/core/widgets/animated_illustrations.dart';
import 'package:masterchas_app/features/home/presentation/widgets/home_extras.dart';
import 'package:masterchas_app/features/bonus/presentation/wheel_of_fortune.dart';
import 'package:masterchas_app/features/notifications/presentation/client_notifications_page.dart';

/// Фильтр мастеров на главной.
class HomeMasterFilter {
  const HomeMasterFilter({
    this.category,
    this.district,
    this.onlineOnly = false,
    this.topOnly = false,
  });

  final String? category;
  final String? district;
  final bool onlineOnly;
  final bool topOnly;

  bool get isActive =>
      category != null || district != null || onlineOnly || topOnly;

  List<MasterItem> apply(Iterable<MasterItem> source) {
    return source.where((m) {
      if (category != null && !m.categories.contains(category)) return false;
      if (district != null && !m.districts.contains(district)) return false;
      if (onlineOnly && !m.isOnline) return false;
      if (topOnly && !m.isTop) return false;
      return true;
    }).toList();
  }

  HomeMasterFilter copyWith({
    String? category,
    bool clearCategory = false,
    String? district,
    bool clearDistrict = false,
    bool? onlineOnly,
    bool? topOnly,
  }) {
    return HomeMasterFilter(
      category: clearCategory ? null : (category ?? this.category),
      district: clearDistrict ? null : (district ?? this.district),
      onlineOnly: onlineOnly ?? this.onlineOnly,
      topOnly: topOnly ?? this.topOnly,
    );
  }
}

const _homeDistricts = ['Сино', 'Фирдавси', 'Шохмансур', 'Исмоили Сомони'];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _nav = 0;
  final _homeSearchController = TextEditingController();
  String _homeQuery = '';
  HomeMasterFilter _masterFilter = const HomeMasterFilter();

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  void _openCategory(ServiceCategory cat) {
    final locale = ref.read(localeProvider);
    Navigator.of(context).push(
      SmoothRoute<void>(
        builder: (_) => CategoryDetailPage(category: cat, locale: locale),
      ),
    );
  }

  void _openServicesTab() => setState(() => _nav = 1);

  void _openNotifications() {
    Navigator.of(context).push(
      SmoothRoute<void>(builder: (_) => const ClientNotificationsPage()),
    );
  }

  void _openMastersFiltered(HomeMasterFilter filter) {
    Navigator.of(context).push(
      SmoothRoute<void>(
        builder: (_) => MastersPage(
          initialFilter: filter.category,
          initialDistrict: filter.district,
          initialOnlineOnly: filter.onlineOnly,
          initialTopOnly: filter.topOnly,
        ),
      ),
    );
  }

  void _showHomeFilterSheet(HomeStrings s) {
    final p = HomePalette.of(context);
    var draft = _masterFilter;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget sectionTitle(String text) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    text,
                    style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                  ),
                );

            Widget chip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              IconData? icon,
            }) {
              return Material(
                color: selected ? brandGreen : p.pageBg,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? brandGreen : p.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 14, color: selected ? Colors.white : p.muted),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : p.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final locale = ref.read(localeProvider);
            final categories = <(String?, String)>[
              (null, s.all),
              ('Электрика', localizedCategory('Электрика', locale)),
              ('Сантехника', localizedCategory('Сантехника', locale)),
              ('Мебель и двери', s.catFurniture),
              ('Отделка', s.catFinishing),
            ];

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
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
                    Row(
                      children: [
                        Text(
                          s.filterMastersTitle,
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
                        ),
                        const Spacer(),
                        if (draft.isActive)
                          TextButton(
                            onPressed: () => setSheetState(() => draft = const HomeMasterFilter()),
                            child: Text(
                              s.resetBtn,
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: brandGreen),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    sectionTitle(s.categoryLabel),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((item) {
                        final (key, label) = item;
                        return chip(
                          label: label,
                          selected: draft.category == key,
                          onTap: () {
                            if (key == null) {
                              setSheetState(() => draft = draft.copyWith(clearCategory: true));
                              return;
                            }
                            final next = draft.copyWith(category: key);
                            setState(() => _masterFilter = next);
                            Navigator.pop(ctx);
                            _openMastersFiltered(next);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    sectionTitle(s.districtsTitle),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: s.aiDistrictAny,
                          selected: draft.district == null,
                          onTap: () => setSheetState(() => draft = draft.copyWith(clearDistrict: true)),
                        ),
                        ..._homeDistricts.map(
                          (d) => chip(
                            label: d,
                            selected: draft.district == d,
                            onTap: () => setSheetState(() => draft = draft.copyWith(district: d)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    sectionTitle(s.extraFiltersLabel),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: s.onlineWord,
                          icon: LucideIcons.circle,
                          selected: draft.onlineOnly,
                          onTap: () => setSheetState(() => draft = draft.copyWith(onlineOnly: !draft.onlineOnly)),
                        ),
                        chip(
                          label: s.badgeTop,
                          icon: LucideIcons.star,
                          selected: draft.topOnly,
                          onTap: () => setSheetState(() => draft = draft.copyWith(topOnly: !draft.topOnly)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _masterFilter = draft);
                          Navigator.pop(ctx);
                          _openMastersFiltered(draft);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          s.showMastersBtn,
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  TextStyle _s(
    HomePalette p, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.3,
  }) =>
      GoogleFonts.manrope(
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
        var actionIndex = 0;
        Widget action({
          required IconData icon,
          required Color color,
          required String title,
          required String sub,
          required VoidCallback onTap,
        }) {
          final i = actionIndex++;
          return Reveal(
            delay: Duration(milliseconds: 90 + 80 * i),
            offsetY: 22,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HoverLift(
                radius: 18,
                glowColor: color,
                child: Material(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(18),
                    splashColor: color.withValues(alpha: 0.12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withValues(alpha: 0.22)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [p.cardBg, color.withValues(alpha: 0.06)],
                        ),
                      ),
                      child: Row(
                        children: [
                          FloatY(
                            amplitude: 2.5,
                            phase: i * 0.3,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5)),
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 25),
                            ),
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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.arrow_right, size: 16, color: color),
                          ),
                        ],
                      ),
                    ),
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
                Reveal(
                  offsetY: 10,
                  child: Row(
                    children: [
                      FloatY(
                        amplitude: 2,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: brandGreen.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(LucideIcons.sparkles, size: 18, color: brandGreen),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.fabTitle, style: _s(p, size: 20, weight: FontWeight.w800))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                action(
                  icon: LucideIcons.wrench,
                  color: brandGreen,
                  title: s.fabCallTitle,
                  sub: s.fabCallSub,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      SmoothRoute<void>(builder: (_) => const MastersPage()),
                    );
                  },
                ),
                action(
                  icon: LucideIcons.user_plus,
                  color: const Color(0xFFF59E0B),
                  title: s.fabBecomeTitle,
                  sub: s.fabBecomeSub,
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(masterRegistrationDraftProvider.notifier).reset();
                    final phone = ref.read(authProvider).phone;
                    context.push(
                      '/master/register?mode=application',
                      extra: phone != null ? {'phone': phone} : null,
                    );
                  },
                ),
                action(
                  icon: LucideIcons.shopping_bag,
                  color: const Color(0xFF3B82F6),
                  title: s.fabShopTitle,
                  sub: s.fabShopSub,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      SmoothRoute<void>(builder: (_) => const ShopPage()),
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
          RefreshIndicator(
            color: brandGreen,
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 900));
              if (mounted) setState(() {});
            },
            child: ListView(
            padding: EdgeInsets.only(
              bottom: 108 + MediaQuery.paddingOf(context).bottom,
            ),
                  children: [
                    _HeroHeader(
                      s: s,
                      p: p,
                      isDark: isDark,
                      topInset: topInset,
                      controller: _homeSearchController,
                      filterActive: _masterFilter.isActive,
                      onLanguage: () => _showLanguagePicker(s, locale),
                      onThemeToggle: () => ref.read(themeModeProvider.notifier).toggle(),
                      onFilter: () => _showHomeFilterSheet(s),
                      onNotifications: _openNotifications,
                      onChanged: (v) => setState(() => _homeQuery = v),
                      onClear: () {
                        _homeSearchController.clear();
                        setState(() => _homeQuery = '');
                      },
                    ),
                    if (_masterFilter.isActive && _homeQuery.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _ActiveFilterBar(
                          filter: _masterFilter,
                          s: s,
                          p: p,
                          locale: locale,
                          onClear: () => setState(() => _masterFilter = const HomeMasterFilter()),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
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
                    Reveal(
                      delay: const Duration(milliseconds: 60),
                      child: ActiveOrderBanner(
                      p: p,
                      s: s,
                      onTap: () {},
                    )),
                    const SizedBox(height: 14),
                    Reveal(
                      delay: const Duration(milliseconds: 140),
                      child: _WowFeaturesRow(s: s, p: p)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 220),
                      child: _Categories(
                      s: s,
                      p: p,
                      locale: locale,
                      onCategory: _openCategory,
                      onShowAll: _openServicesTab,
                    )),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 300),
                      child: _PopularMasters(s: s, p: p, locale: locale, filter: _masterFilter)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 380),
                      child: _PromoRow(s: s, p: p)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 460),
                      child: _DiscountBanner(s: s, p: p)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: _HowItWorks(s: s, p: p)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: _ClientReviews(s: s, p: p)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: _TrustRow(s: s, p: p)),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: _ToolsShop(
                      s: s,
                      p: p,
                      onOpenShop: () => Navigator.of(context).push(
                        SmoothRoute<void>(builder: (_) => const ShopPage()),
                      ),
                    )),
                    const SizedBox(height: 22),
                    const SizedBox(height: 24),
                    ],
                  ],
                        ),
                      ),
                  ],
                ),
          ),
                _ServicesPage(s: s, p: p, locale: locale),
                _ChatsTabPage(s: s, p: p),
          const ProfilePage(),
        ],
      ),
      floatingActionButton: PulseRing(
        color: brandGreen,
        child: HoverLift(
          radius: 28,
          scale: 1.1,
          lift: 2,
          child: SizedBox(
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
        GoogleFonts.manrope(fontSize: size, fontWeight: w, color: c ?? p.text);

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

class _SearchBar extends StatefulWidget {
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
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> with SingleTickerProviderStateMixin {
  late final AnimationController _hintAnim;
  int _hintIndex = 0;

  List<String> get _hints => widget.s.searchRotatingHints;

  @override
  void initState() {
    super.initState();
    _hintAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cycleHints();
  }

  void _cycleHints() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || widget.controller.text.isNotEmpty) continue;
      await _hintAnim.forward();
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      _hintAnim.reset();
    }
  }

  @override
  void dispose() {
    _hintAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = widget.controller.text.isNotEmpty;
    final currentHint = widget.controller.text.isEmpty ? _hints[_hintIndex] : widget.s.searchPlaceholder;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: widget.p.searchBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.p.border),
        boxShadow: [
          BoxShadow(
            color: brandGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 14, right: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(LucideIcons.search, color: brandGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              cursorColor: brandGreen,
              style: GoogleFonts.manrope(fontSize: 14, color: widget.p.text),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: currentHint,
                hintStyle: GoogleFonts.manrope(fontSize: 13, color: widget.p.muted),
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: widget.onClear,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.x, size: 15, color: Colors.red.shade400),
              ),
            )
          else
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4BAF50), Color(0xFF57B55E)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
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
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
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
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
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
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
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
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: brandGreen),
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
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
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
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            SmoothRoute<void>(builder: (_) => MasterDetailPage(master: master)),
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
                      style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      master.profession(locale),
                      style: GoogleFonts.manrope(fontSize: 11, color: p.muted),
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
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text),
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
                    style: GoogleFonts.manrope(
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
  Widget build(BuildContext context) => HoverLift(
        child: ShineSweep(delay: const Duration(milliseconds: 800), child: _buildCard(context)),
      );

  Widget _buildCard(BuildContext context) {
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
                right: 4,
                top: 22,
                bottom: 18,
                child: const Center(child: AiRobotIllustration(size: 90)),
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
                        style: GoogleFonts.manrope(
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
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.aiSubtitle,
                      style: GoogleFonts.manrope(
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
      SmoothRoute<void>(builder: (_) => const MastersPage()),
    );
  }

  @override
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
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
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.masterSubtitle,
                      style: GoogleFonts.manrope(fontSize: 9.5, color: p.muted, height: 1.3),
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
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onShowAll,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    s.all,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: brandGreen),
                  ),
                  const Icon(LucideIcons.chevron_right, size: 15, color: brandGreen),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = cats[i];
              return Reveal(
                delay: Duration(milliseconds: 520 + i * 80),
                offsetY: 0,
                offsetX: 30,
                child: HoverLift(
                  radius: 16,
                  scale: 1.06,
                  glowColor: c.$3,
                  child: Material(
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
                        FloatY(
                          amplitude: 2.5,
                          phase: i * 0.18,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: c.$3.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(c.$1, color: c.$3, size: 21),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            c.$2,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
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
  Widget build(BuildContext context) => HoverLift(
        child: ShineSweep(delay: const Duration(milliseconds: 1500), child: _buildCard(context)),
      );

  Widget _buildCard(BuildContext context) {
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
            right: 10,
            top: 0,
            bottom: 0,
            width: 120,
            child: const Center(child: ToolSparkIllustration(size: 100)),
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
                    style: GoogleFonts.manrope(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.discountTitle,
                  style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
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
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
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
                      style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(fontSize: 9, color: p.muted, height: 1.35),
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
        child: AnimatedScale(
          scale: on ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: on ? brandGreen.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: i == 2
                    ? Consumer(
                        builder: (context, ref, _) {
                          final unread = ref.watch(unreadChatsTotalProvider).value ?? 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(icon, size: 22, color: c),
                              if (unread > 0)
                                Positioned(
                                  right: -10,
                                  top: -8,
                                  child: UnreadBadge(count: unread, size: 18),
                                ),
                            ],
                          );
                        },
                      )
                    : Icon(icon, size: 22, color: c),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    color: c,
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
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: brandGreen),
              ),
              const Icon(LucideIcons.chevron_right, size: 15, color: brandGreen),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Active filter bar ────────────────────────────────────────────────────────

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.filter,
    required this.s,
    required this.p,
    required this.locale,
    required this.onClear,
  });

  final HomeMasterFilter filter;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filter.category != null) {
      chips.add(localizedCategory(filter.category!, locale));
    }
    if (filter.district != null) chips.add(filter.district!);
    if (filter.onlineOnly) chips.add(s.onlineWord);
    if (filter.topOnly) chips.add(s.badgeTop);

    return Row(
      children: [
        Icon(LucideIcons.sliders_horizontal, size: 16, color: brandGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            chips.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text),
          ),
        ),
        TextButton(
          onPressed: onClear,
          child: Text(
            s.resetBtn,
            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: brandGreen),
          ),
        ),
      ],
    );
  }
}

// ─── Popular masters ──────────────────────────────────────────────────────────

class _PopularMasters extends StatelessWidget {
  const _PopularMasters({
    required this.s,
    required this.p,
    required this.locale,
    required this.filter,
  });

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final HomeMasterFilter filter;

  @override
  Widget build(BuildContext context) {
    final base = filter.isActive ? filter.apply(masters) : masters.where((m) => m.isTop);
    final list = base.take(6).toList();

    void openMasters() {
      Navigator.of(context).push(
        SmoothRoute<void>(
          builder: (_) => MastersPage(
            initialFilter: filter.category,
            initialDistrict: filter.district,
            initialOnlineOnly: filter.onlineOnly,
            initialTopOnly: filter.topOnly,
          ),
        ),
      );
    }

    return Column(
      children: [
        _SectionHeader(
          title: s.popularMasters,
          action: s.all,
          p: p,
          onAction: openMasters,
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                s.nothingFoundMasters,
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted),
              ),
            ),
          )
        else
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
      SmoothRoute<void>(builder: (_) => MasterDetailPage(master: m)),
    );
  }

  @override
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
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
                              style: GoogleFonts.manrope(
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
                      child: MasterFavoriteButton(masterKey: m.fullName),
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
                              style: GoogleFonts.manrope(
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
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text, height: 1.2),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          m.rating.toStringAsFixed(1),
                          style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '(${m.reviews} ${s.reviewsWord})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 11, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      m.profession(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 12, color: p.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.fromPrice} ${m.priceMin} ${s.priceUnit}',
                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: brandGreen),
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
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
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

// ─── All masters ──────────────────────────────────────────────────────────────

class _AllMastersSection extends StatelessWidget {
  const _AllMastersSection({
    required this.s,
    required this.p,
    required this.locale,
    required this.filter,
  });

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final HomeMasterFilter filter;

  @override
  Widget build(BuildContext context) {
    void openMasters() {
      Navigator.of(context).push(
        SmoothRoute<void>(
          builder: (_) => MastersPage(
            initialFilter: filter.category,
            initialDistrict: filter.district,
            initialOnlineOnly: filter.onlineOnly,
            initialTopOnly: filter.topOnly,
          ),
        ),
      );
    }

    final list = filter.apply(masters).take(8).toList();

    return Column(
      children: [
        _SectionHeader(
          title: s.allMasters,
          action: s.all,
          p: p,
          onAction: openMasters,
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                s.nothingFoundMasters,
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted),
              ),
            ),
          )
        else
          ...list.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AllMasterRow(m: m, s: s, p: p, locale: locale),
            ),
          ),
      ],
    );
  }
}

class _AllMasterRow extends StatelessWidget {
  const _AllMasterRow({
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
      SmoothRoute<void>(builder: (_) => MasterDetailPage(master: m)),
    );
  }

  @override
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(m.image, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.profession(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 12, color: p.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.fromPrice} ${m.priceMin} ${s.priceUnit}',
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: brandGreen),
                    ),
                  ],
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

  factory _ReviewData.fromMasterReview(dynamic review, Color accent) {
    return _ReviewData(
      author: review.authorName as String,
      date: review.dateLabel as String,
      body: review.body as String,
      accent: accent,
    );
  }
}

class _ClientReviews extends ConsumerWidget {
  const _ClientReviews({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  static const _accents = [
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allMasterReviewsProvider);
    final reviews = all.take(3).toList();

    return Column(
      children: [
        _SectionHeader(
          title: s.clientReviews,
          action: s.allReviews,
          p: p,
          onAction: () => Navigator.of(context).push(
            SmoothRoute<void>(builder: (_) => const AllReviewsPage()),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 162,
          child: reviews.isEmpty
              ? Center(child: Text(s.noReviewsYet, style: GoogleFonts.manrope(color: p.muted)))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _ReviewCard(
                    r: _ReviewData.fromMasterReview(reviews[i], _accents[i % _accents.length]),
                    p: p,
                  ),
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
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
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
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: r.accent),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.author,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: p.text),
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
                style: GoogleFonts.manrope(fontSize: 10, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              r.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 12.5, color: p.text, height: 1.4),
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
  Widget build(BuildContext context) => HoverLift(
        child: ShineSweep(delay: const Duration(milliseconds: 2900), child: _buildCard(context)),
      );

  Widget _buildCard(BuildContext context) {
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
                child: const Center(child: AiRobotIllustration(size: 50)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.aiBigTitle,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.aiBigSub,
                      style: GoogleFonts.manrope(fontSize: 11, color: p.muted, height: 1.3),
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
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
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
            style: GoogleFonts.manrope(fontSize: 8.5, color: p.muted, height: 1.2),
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
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 9.5, color: p.muted, height: 1.15),
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

class _ToolsShop extends ConsumerWidget {
  const _ToolsShop({required this.s, required this.p, required this.onOpenShop});

  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Настоящие товары магазина — те же, что в разделе «Магазин».
    final catalog = ref.watch(shopCatalogProvider);
    final locale = ref.watch(localeProvider);
    final count = catalog.length < 8 ? catalog.length : 8;
    if (count == 0) return const SizedBox.shrink();

    return Column(
      children: [
        _SectionHeader(title: s.toolsShop, action: s.all, p: p, onAction: onOpenShop),
        const SizedBox(height: 12),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final product = catalog[i];
              return _ProductCard(
                product: product,
                name: product.name(locale),
                s: s,
                p: p,
                onOpen: () => Navigator.of(context).push(
                  SmoothRoute<void>(builder: (_) => ShopPage(initialProduct: product)),
                ),
                onAdd: () {
                  HapticFeedback.lightImpact();
                  ref.read(shopCartProvider.notifier).add(i);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        backgroundColor: brandGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(milliseconds: 2500),
                        content: Row(
                          children: [
                            const Icon(LucideIcons.circle_check, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '«${product.name(locale)}» в корзине',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        action: SnackBarAction(
                          label: 'Открыть',
                          textColor: Colors.white,
                          onPressed: onOpenShop,
                        ),
                      ),
                    );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.name,
    required this.s,
    required this.p,
    required this.onOpen,
    required this.onAdd,
  });

  final ShopProduct product;
  final String name;
  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _added = false;

  void _add() {
    widget.onAdd();
    setState(() => _added = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final prod = widget.product;
    return HoverLift(
      child: Material(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onOpen,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      color: p.productImageBg,
                      padding: const EdgeInsets.all(10),
                      child: Hero(
                        tag: 'home-prod-${prod.image}-${prod.ru}',
                        child: buildShopProductImage(prod),
                      ),
                    ),
                    if (prod.discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '−${prod.discountPercent}%',
                            style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: p.text, height: 1.2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (prod.oldPrice > prod.price)
                                  Text(
                                    '${prod.oldPrice} ${widget.s.priceUnit}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10.5,
                                      color: p.muted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '${prod.price} ${widget.s.priceUnit}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'В корзину',
                            child: GestureDetector(
                              onTap: _add,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _added ? const Color(0xFF2E9E4F) : brandGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: brandGreen.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                  child: Icon(
                                    _added ? LucideIcons.check : LucideIcons.plus,
                                    key: ValueKey(_added),
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
          style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: feats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final (icon, title, sub) = feats[i];
              return Container(
                width: 162,
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
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 10, color: p.muted, height: 1.2),
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
  Widget build(BuildContext context) => HoverLift(
        child: ShineSweep(delay: const Duration(milliseconds: 2200), child: _buildCard(context)),
      );

  Widget _buildCard(BuildContext context) {
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
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '20%',
                    style: GoogleFonts.manrope(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
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
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.disc2Sub,
                  style: GoogleFonts.manrope(fontSize: 10.5, color: Colors.white70),
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
                    style: GoogleFonts.manrope(
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
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
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
                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.allToolsSub,
                      style: GoogleFonts.manrope(fontSize: 11, color: p.muted, height: 1.3),
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
                        style: GoogleFonts.manrope(fontSize: 11, color: p.text, height: 1.2),
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
      SmoothRoute<void>(
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
      padding: const EdgeInsets.only(bottom: 108),
      children: [
        // Premium green header
        Reveal(
          offsetY: -18,
          duration: const Duration(milliseconds: 550),
          child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Stack(
          children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: p.headerGradient,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: brandGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const FloatY(
                      amplitude: 2,
                      child: Icon(LucideIcons.layout_grid, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.navServices,
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          s.servicesSubtitle,
                          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Search bar
              Container(
                height: 52,
                padding: const EdgeInsets.only(left: 8, right: 6),
                decoration: BoxDecoration(
                  color: p.headerCardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4BAF50), Color(0xFF57B55E)]),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(LucideIcons.search, color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (v) => setState(() => _query = v),
                        cursorColor: brandGreen,
                        style: GoogleFonts.manrope(fontSize: 14, color: p.text),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintText: s.servicesSearch,
                          hintStyle: GoogleFonts.manrope(fontSize: 13, color: p.muted),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.x, size: 15, color: Colors.red.shade400),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
            // декоративные «пузыри» в шапке
            Positioned(
              right: -30,
              top: -20,
              child: IgnorePointer(
                child: FloatY(
                  amplitude: 6,
                  period: const Duration(milliseconds: 4200),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 70,
              top: MediaQuery.paddingOf(context).top + 6,
              child: IgnorePointer(
                child: FloatY(
                  amplitude: 4,
                  phase: 0.4,
                  period: const Duration(milliseconds: 3000),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
            ),
          ],
          ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        if (q.isEmpty) ...[
          Reveal(
            delay: const Duration(milliseconds: 120),
            child: _PopularServicesStrip(
              p: p,
              locale: locale,
              onOpen: _openCategory,
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Text(
                  'Все категории',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${serviceCatalog.length}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: brandGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
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
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
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
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, i) => Reveal(
              delay: Duration(milliseconds: 260 + 55 * (i % 12)),
              child: _ServiceCard(
                cat: matchedCats[i],
                s: s,
                p: p,
                locale: locale,
              ),
            ),
          ),
        if (matchedServices.isNotEmpty) ...[
          const SizedBox(height: 18),
          ...matchedServices.indexed.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Reveal(
                delay: Duration(milliseconds: 40 * (e.$1 % 10)),
                offsetY: 14,
                child: _ServiceResultRow(
                cat: e.$2.$1,
                svc: e.$2.$2,
                s: s,
                p: p,
                locale: locale,
                onTap: () => _openCategory(e.$2.$1),
              ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 150),
          child: HoverLift(
            glowColor: const Color(0xFF10B981),
            child: ShineSweep(
              delay: const Duration(milliseconds: 1200),
              child: GestureDetector(
                onTap: () => AiCallSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const FloatY(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          child: Icon(LucideIcons.bot, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Не нашли нужную услугу?',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Позвоните ИИ-диспетчеру — подберём мастера за минуту',
                              style: GoogleFonts.manrope(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
            ],
          ),
        ),
      ],
    );
  }
}

/// «Популярное» — горизонтальная лента частых услуг с ценой.
class _PopularServicesStrip extends StatelessWidget {
  const _PopularServicesStrip({
    required this.p,
    required this.locale,
    required this.onOpen,
  });

  final HomePalette p;
  final AppLocale locale;
  final ValueChanged<ServiceCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = <(ServiceCategory, ServiceItem)>[
      for (final cat in serviceCatalog.take(8))
        if (cat.services.isNotEmpty) (cat, cat.services.first),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.flame, size: 18, color: Color(0xFFF97316)),
            const SizedBox(width: 6),
            Text(
              'Популярное',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.text,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final (cat, svc) = items[i];
              return Reveal(
                delay: Duration(milliseconds: 160 + i * 70),
                offsetY: 0,
                offsetX: 26,
                child: HoverLift(
                  glowColor: cat.color,
                  radius: 16,
                  child: GestureDetector(
                    onTap: () => onOpen(cat),
                    child: Container(
                      width: 168,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cat.color.withValues(alpha: 0.16),
                            cat.color.withValues(alpha: 0.04),
                          ],
                        ),
                        border: Border.all(color: cat.color.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const Spacer(),
                              Text(
                                'от ${svc.priceAvg} с.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: cat.color,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            svc.name(locale),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.text,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
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
  Widget build(BuildContext context) => HoverLift(child: _buildCard(context));

  Widget _buildCard(BuildContext context) {
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
                      style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.name(locale),
                      style: GoogleFonts.manrope(fontSize: 11, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${svc.priceAvg} ${s.priceUnit}',
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: brandGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
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
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final p = widget.p;
    final minPrice = cat.services.isEmpty
        ? null
        : cat.services.map((e) => e.priceAvg).reduce((a, b) => a < b ? a : b);
    final active = _hover || _pressed;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Navigator.of(context).push(
          SmoothRoute<void>(
            builder: (_) => CategoryDetailPage(category: cat, locale: widget.locale),
          ),
        );
      },
      child: AnimatedSlide(
        offset: Offset(0, _hover && !_pressed ? -0.03 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
        scale: _pressed ? 0.94 : (_hover ? 1.05 : 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? Color.alphaBlend(cat.color.withValues(alpha: 0.06), p.cardBg) : p.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? cat.color.withValues(alpha: 0.55) : p.border,
              width: active ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cat.color.withValues(alpha: active ? 0.28 : 0.08),
                blurRadius: active ? 22 : 10,
                offset: Offset(0, active ? 10 : 4),
                spreadRadius: active ? -2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cat.color.withValues(alpha: 0.9),
                      Color.lerp(cat.color, Colors.black, 0.18)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: cat.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatY(
                  amplitude: 1.8,
                  phase: (cat.ru.length % 10) / 10,
                  child: AnimatedRotation(
                    turns: _hover ? -0.04 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: Icon(cat.icon, size: 25, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat.name(widget.locale),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text, height: 1.1),
              ),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _hover && minPrice != null
                    ? Text(
                        'от $minPrice с.',
                        key: const ValueKey('price'),
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: cat.color,
                        ),
                      )
                    : Text(
                        '${cat.services.length} ${widget.s.servicesCountWord}',
                        key: const ValueKey('count'),
                        style: GoogleFonts.manrope(fontSize: 9.5, color: p.muted),
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

class _ChatsTabPage extends ConsumerWidget {
  const _ChatsTabPage({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Reveal(
          offsetY: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                FloatY(
                  amplitude: 2.5,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF57B55E), Color(0xFF2E9E4F)],
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF57B55E).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: const Icon(LucideIcons.message_circle, color: Colors.white, size: 21),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.navChats,
                        style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: p.text, height: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Consumer(
                        builder: (context, ref, _) {
                          final unread = ref.watch(unreadChatsTotalProvider).asData?.value ?? 0;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              key: ValueKey(unread),
                              children: [
                                const LiveDot(color: Color(0xFF57B55E), size: 7),
                                const SizedBox(width: 6),
                                Text(
                                  unread > 0 ? '$unread непрочитанных' : 'Все сообщения прочитаны',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: unread > 0 ? const Color(0xFFEF4444) : p.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WOW FEATURES ROW — SOS, ИИ-звонок, AI-диагностика
// ═══════════════════════════════════════════════════════════════════════════
class _WowFeaturesRow extends StatelessWidget {
  const _WowFeaturesRow({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Row(
        children: [
          Expanded(
            child: _WowCard(
              icon: LucideIcons.siren,
              title: 'SOS',
              subtitle: s.sosSubtitle,
              gradient: AppDesign.sosGradient,
              glow: AppDesign.accentRed,
              onTap: () => Navigator.of(context).push(
                SmoothRoute<void>(builder: (_) => const SosEmergencyScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _WowCard(
              icon: LucideIcons.phone,
              title: s.auctionTitle,
              subtitle: s.auctionSubtitle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
              ),
              glow: AppDesign.accentTeal,
              onTap: () => AiCallSheet.show(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _WowCard(
              icon: LucideIcons.scan_eye,
              title: s.aiPhotoTitle,
              subtitle: s.aiPhotoSubtitle,
              gradient: AppDesign.aiGradient,
              glow: AppDesign.accentPurple,
              onTap: () => Navigator.of(context).push(
                SmoothRoute<void>(builder: (_) => const AiDiagnosisScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WowCard extends StatefulWidget {
  const _WowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glow,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color glow;
  final VoidCallback onTap;

  @override
  State<_WowCard> createState() => _WowCardState();
}

class _WowCardState extends State<_WowCard> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        offset: Offset(0, _hover && !_pressed ? -0.04 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
        scale: _pressed ? 0.95 : (_hover ? 1.05 : 1.0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.glow.withValues(alpha: _pressed ? 0.2 : (_hover ? 0.55 : 0.35)),
                blurRadius: _hover ? 26 : 16,
                offset: Offset(0, _hover ? 10 : 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ShineSweep(
          radius: 18,
          delay: Duration(milliseconds: widget.title.length * 137 % 1500),
          child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: FloatY(
                  amplitude: 2,
                  child: AnimatedRotation(
                    turns: _hover ? -0.03 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO HEADER — премиум зелёная шапка с приветствием, локацией и поиском
// ═══════════════════════════════════════════════════════════════════════════
class _HeroHeader extends StatefulWidget {
  const _HeroHeader({
    required this.s,
    required this.p,
    required this.isDark,
    required this.topInset,
    required this.controller,
    required this.filterActive,
    required this.onLanguage,
    required this.onThemeToggle,
    required this.onFilter,
    required this.onNotifications,
    required this.onChanged,
    required this.onClear,
  });

  final HomeStrings s;
  final HomePalette p;
  final bool isDark;
  final double topInset;
  final TextEditingController controller;
  final bool filterActive;
  final VoidCallback onLanguage;
  final VoidCallback onThemeToggle;
  final VoidCallback onFilter;
  final VoidCallback onNotifications;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hintAnim;
  int _hintIndex = 0;

  List<String> get _hints => widget.s.searchRotatingHints;

  @override
  void initState() {
    super.initState();
    _hintAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cycle();
  }

  void _cycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || widget.controller.text.isNotEmpty) continue;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    }
  }

  @override
  void dispose() {
    _hintAnim.dispose();
    super.dispose();
  }

  String _greeting(HomeStrings s) {
    final h = DateTime.now().hour;
    if (h < 6) return s.goodNight;
    if (h < 12) return s.goodMorning;
    if (h < 18) return s.goodAfternoon;
    return s.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final hasQuery = widget.controller.text.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(20, widget.topInset + 16, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.headerGradient,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: brandGreen.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: greeting + icons
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(widget.s),
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(LucideIcons.map_pin, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.s.city,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Icon(LucideIcons.chevron_down, size: 18,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ],
                    ),
                  ],
                ),
              ),
              _glassIcon(LucideIcons.globe, widget.onLanguage),
              const SizedBox(width: 8),
              _glassIcon(
                widget.isDark ? LucideIcons.moon : LucideIcons.sun,
                widget.onThemeToggle,
              ),
              const SizedBox(width: 8),
              _glassIcon(LucideIcons.bell, widget.onNotifications, badge: true),
            ],
          ),
          const SizedBox(height: 18),
          // Search bar
          Container(
            height: 54,
            padding: const EdgeInsets.only(left: 8, right: 6),
            decoration: BoxDecoration(
              color: p.headerCardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4BAF50), Color(0xFF57B55E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.search, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    onChanged: widget.onChanged,
                    cursorColor: brandGreen,
                    style: GoogleFonts.manrope(fontSize: 14, color: p.text),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: hasQuery ? widget.s.searchPlaceholder : _hints[_hintIndex],
                      hintStyle: GoogleFonts.manrope(fontSize: 13, color: p.muted),
                    ),
                  ),
                ),
                if (hasQuery)
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.x, size: 16, color: Colors.red.shade400),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: widget.onFilter,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.filterActive
                                ? brandGreen
                                : brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.sliders_horizontal,
                            color: widget.filterActive ? Colors.white : brandGreen,
                            size: 18,
                          ),
                        ),
                        if (widget.filterActive)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIcon(IconData icon, VoidCallback onTap, {bool badge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          if (badge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
