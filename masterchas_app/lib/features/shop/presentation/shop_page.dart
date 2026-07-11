import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../data/shop_checkout.dart';
import '../data/shop_data.dart';
import '../state/shop_state.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  int _cat = 0;
  int _nav = 0;
  String _query = '';
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ShopProduct> _catalog = shopProducts;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggleFav(int idx) => ref.read(shopFavoritesProvider.notifier).toggle(idx);

  void _toggleRentalFav(int idx) => ref.read(rentalFavoritesProvider.notifier).toggle(idx);

  void _toTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  void _toast(String text, {Color color = brandGreen}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          content: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      );
  }

  List<ShopProduct> _search() {
    final q = _query.trim().toLowerCase();
    return [
      for (final p in _catalog)
        if (p.ru.toLowerCase().contains(q) || p.en.toLowerCase().contains(q)) p,
    ];
  }

  void _add(int productIndex, ShopL10n l) {
    HapticFeedback.lightImpact();
    ref.read(shopCartProvider.notifier).add(productIndex);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
          content: Row(
            children: [
              const Icon(LucideIcons.circle_check, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                l.addedToCart,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      );
  }

  List<ShopProduct> _filtered(ProductBadge badge) {
    return [
      for (var i = 0; i < _catalog.length; i++)
        if (_catalog[i].badge == badge && (_cat == 0 || _catalog[i].categoryIndex == _cat)) _catalog[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    _catalog = ref.watch(shopCatalogProvider);
    final locale = ref.watch(localeProvider);
    final l = ShopL10n.of(locale);
    final p = HomePalette.of(context);

    final fav = ref.watch(shopFavoritesProvider);
    final rentalFav = ref.watch(rentalFavoritesProvider);
    final cartCount = ref.watch(shopCartProvider).values.fold(0, (a, b) => a + b);

    final hits = _filtered(ProductBadge.hit);
    final news = _filtered(ProductBadge.isNew);
    final searching = _query.trim().isNotEmpty;
    final results = searching ? _search() : const <ShopProduct>[];
    final deals = [for (final pr in _catalog) if (pr.discountPercent > 0) pr];

    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              l: l,
              p: p,
              cartCount: cartCount,
              favCount: fav.length,
              controller: _searchCtrl,
              onCart: () => _openCart(l, locale),
              onFavorites: () => _openFavorites(l, locale),
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() {
                _query = '';
                _searchCtrl.clear();
              }),
            ),
            Expanded(
              child: searching
                  ? _SearchResults(
                      results: results,
                      l: l,
                      p: p,
                      locale: locale,
                      fav: fav,
                      onAdd: (i) => _add(i, l),
                      onFav: _toggleFav,
                      onOpen: _openProduct,
                    )
                  : _nav == 1
                  ? _TileListView(
                      title: l.dealsTitle,
                      products: deals,
                      l: l,
                      p: p,
                      locale: locale,
                      fav: fav,
                      onAdd: (i) => _add(i, l),
                      onFav: _toggleFav,
                      onOpen: _openProduct,
                    )
                  : _nav == 2
                  ? _TileListView(
                      title: l.navRent,
                      products: rentalProducts,
                      catalogList: rentalProducts,
                      priceUnit: l.rentPriceUnit,
                      l: l,
                      p: p,
                      locale: locale,
                      fav: rentalFav,
                      onAdd: (_) {},
                      onFav: _toggleRentalFav,
                      onOpen: _openRentalProduct,
                      headerIcon: LucideIcons.hammer,
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        const SizedBox(height: 8),
                        _Categories(
                          l: l,
                          p: p,
                          selected: _cat,
                          onSelect: (i) => setState(() => _cat = i),
                        ),
                        const SizedBox(height: 16),
                        _Promos(
                          l: l,
                          p: p,
                          onTap: (i) {
                            if (i == 0) {
                              setState(() => _cat = 1);
                              _toTop();
                            } else if (i == 2) {
                              setState(() => _cat = 4);
                              _toTop();
                            } else {
                              _toast(l.promoSubs[1]);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        if (hits.isNotEmpty) ...[
                          _SectionHeader(
                            title: l.bestSellers,
                            action: l.seeAll,
                            p: p,
                            onAction: () => _openAll(l.bestSellers, hits, l, p, locale),
                          ),
                          const SizedBox(height: 12),
                          _ProductRow(
                            products: hits,
                            l: l,
                            p: p,
                            locale: locale,
                            fav: fav,
                            onAdd: (i) => _add(i, l),
                            onFav: _toggleFav,
                            onOpen: _openProduct,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _Brands(l: l, p: p, onTap: (name) => _toast(name)),
                        const SizedBox(height: 20),
                        if (news.isNotEmpty) ...[
                          _SectionHeader(
                            title: l.recommended,
                            action: l.seeAll,
                            p: p,
                            onAction: () => _openAll(l.recommended, news, l, p, locale),
                          ),
                          const SizedBox(height: 12),
                          _ProductRow(
                            products: news,
                            l: l,
                            p: p,
                            locale: locale,
                            fav: fav,
                            onAdd: (i) => _add(i, l),
                            onFav: _toggleFav,
                            onOpen: _openProduct,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _Advantages(l: l, p: p),
                        const SizedBox(height: 18),
                        _Newsletter(l: l, p: p),
                        const SizedBox(height: 18),
                        _Footer(l: l),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ShopBottomNav(
        l: l,
        p: p,
        current: _nav,
        onTap: (i) => setState(() => _nav = i),
      ),
    );
  }

  void _openAll(String title, List<ShopProduct> products, ShopL10n l, HomePalette p, AppLocale locale) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AllProductsPage(
          title: title,
          products: products,
          l: l,
          p: p,
          locale: locale,
          onOpen: _openProduct,
        ),
      ),
    );
  }

  void _openProduct(ShopProduct prod) {
    final locale = ref.read(localeProvider);
    final l = ShopL10n.of(locale);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: prod,
          l: l,
          locale: locale,
          onAdd: (i) => _add(i, l),
          onOpen: _openProduct,
        ),
      ),
    );
  }

  void _openRentalProduct(ShopProduct prod) {
    final locale = ref.read(localeProvider);
    final l = ShopL10n.of(locale);
    final index = rentalProducts.indexOf(prod);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: prod,
          l: l,
          locale: locale,
          isRental: true,
          productIndex: index,
          priceUnit: l.rentPriceUnit,
          similarCatalog: rentalProducts,
          onAdd: (_) {},
          onOpen: _openRentalProduct,
        ),
      ),
    );
  }

  void _openFavorites(ShopL10n l, AppLocale locale) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopFavoritesPage(l: l, locale: locale, onOpen: _openProduct),
      ),
    );
  }

  void _openCart(ShopL10n l, AppLocale locale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(l: l, locale: locale),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.l,
    required this.p,
    required this.cartCount,
    required this.favCount,
    required this.controller,
    required this.onCart,
    required this.onFavorites,
    required this.onChanged,
    required this.onClear,
  });

  final ShopL10n l;
  final HomePalette p;
  final int cartCount;
  final int favCount;
  final TextEditingController controller;
  final VoidCallback onCart;
  final VoidCallback onFavorites;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 20),
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
        children: [
          Row(
            children: [
              _circleGlass(LucideIcons.arrow_left, () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Text(
                l.title,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const Spacer(),
              _FavButton(p: p, count: favCount, onTap: onFavorites),
              const SizedBox(width: 8),
              _CartButton(p: p, count: cartCount, onTap: onCart),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              color: p.headerCardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.12,
                  ),
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
                  child: const Icon(LucideIcons.search, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.inter(fontSize: 14, color: p.text),
                    cursorColor: brandGreen,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: l.searchHint,
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: p.muted),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
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
    );
  }

  Widget _circleGlass(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  const _FavButton({required this.p, required this.count, required this.onTap});

  final HomePalette p;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFav = count > 0;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: Icon(
                hasFav ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: Colors.white,
              ),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.p, required this.count, required this.onTap});

  final HomePalette p;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Icon(LucideIcons.shopping_cart, size: 18, color: Colors.white),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -3,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(count),
                  tween: Tween(begin: 0.4, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4BAF50), Color(0xFF57B55E)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: brandGreen.withValues(alpha: 0.4), blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
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

// ─── Categories ─────────────────────────────────────────────────────────────

class _Categories extends StatelessWidget {
  const _Categories({required this.l, required this.p, required this.selected, required this.onSelect});

  final ShopL10n l;
  final HomePalette p;
  final int selected;
  final ValueChanged<int> onSelect;

  static const _catColors = [
    Color(0xFF57B55E), // Все
    Color(0xFFF59E0B), // Электроинструмент
    Color(0xFF3B82F6), // Ручной инструмент
    Color(0xFF8B5CF6), // Расходники
    Color(0xFF14B8A6), // Садовая техника
    Color(0xFFEC4899), // Освещение
    Color(0xFFEF4444), // Измерительный
    Color(0xFF6366F1), // Хранение
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: l.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final on = i == selected;
          final color = _catColors[i % _catColors.length];
          return GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: on ? 0.45 : 0.25),
                          blurRadius: on ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: on ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Icon(shopCategoryIcons[i], size: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l.categories[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                      color: on ? color : p.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Promos ───────────────────────────────────────────────────────────────────

class _Promos extends StatelessWidget {
  const _Promos({required this.l, required this.p, required this.onTap});

  final ShopL10n l;
  final HomePalette p;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _promo(0, const [Color(0xFF2E7D32), Color(0xFF57B55E)], 'assets/images/tool_drill.png', Colors.white, true),
      _promo(1, [p.cardBg, p.cardBg], null, p.text, false, icon: LucideIcons.truck),
      _promo(2, const [Color(0xFF1B5E20), Color(0xFF2E7D32)], 'assets/images/shop_mower.png', Colors.white, true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionHeader(title: l.promosTitle, action: l.seeAll, p: p, onAction: () => onTap(0)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }

  Widget _promo(int i, List<Color> colors, String? img, Color fg, bool light, {IconData? icon}) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        border: light ? null : Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (img != null)
            Positioned(
              right: -6,
              top: 6,
              bottom: 6,
              width: 104,
              child: Image.asset(img, fit: BoxFit.contain, alignment: Alignment.centerRight),
            ),
          if (icon != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: Icon(icon, size: 64, color: brandGreen.withValues(alpha: 0.18)),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 148,
                child: Text(
                  l.promoTitles[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: fg, height: 1.1),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 148,
                child: Text(
                  l.promoSubs[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: light ? Colors.white.withValues(alpha: 0.9) : p.muted,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: light ? Colors.white : brandGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    l.promoBtns[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: light ? const Color(0xFF2E7D32) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
          ),
        ),
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

// ─── Product row + card ───────────────────────────────────────────────────────

class _ProductRow extends ConsumerWidget {
  const _ProductRow({
    required this.products,
    required this.l,
    required this.p,
    required this.locale,
    required this.fav,
    required this.onAdd,
    required this.onFav,
    required this.onOpen,
  });

  final List<ShopProduct> products;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final Set<int> fav;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onFav;
  final ValueChanged<ShopProduct> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(shopCatalogProvider);
    return SizedBox(
      height: 278,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final prod = products[i];
          final globalIndex = catalog.indexOf(prod);
          return _ProductCard(
            prod: prod,
            l: l,
            p: p,
            locale: locale,
            isFav: fav.contains(globalIndex),
            onAdd: () => onAdd(globalIndex),
            onFav: () => onFav(globalIndex),
            onOpen: () => onOpen(prod),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.prod,
    required this.l,
    required this.p,
    required this.locale,
    required this.isFav,
    required this.onAdd,
    required this.onFav,
    required this.onOpen,
  });

  final ShopProduct prod;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final bool isFav;
  final VoidCallback onAdd;
  final VoidCallback onFav;
  final VoidCallback onOpen;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final prod = widget.prod;
    final l = widget.l;
    final p = widget.p;
    final locale = widget.locale;
    final isFav = widget.isFav;
    final light = Theme.of(context).brightness == Brightness.light;
    final discount = prod.discountPercent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onOpen,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 158,
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
            boxShadow: light
                ? [BoxShadow(color: Colors.black.withValues(alpha: _pressed ? 0.1 : 0.05), blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 116,
                    width: double.infinity,
                    color: p.productImageBg,
                    padding: const EdgeInsets.all(10),
                    child: buildShopProductImage(prod, fit: BoxFit.contain),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-$discount%',
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        if (prod.badge != ProductBadge.none) ...[
                          if (discount > 0) const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: prod.badge == ProductBadge.hit ? const Color(0xFFF59E0B) : brandGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prod.badge == ProductBadge.hit ? l.badgeHit : l.badgeNew,
                              style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: widget.onFav,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: p.cardBg,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isFav ? const Color(0xFFEF4444) : p.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 34,
                      child: Text(
                        prod.name(locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: p.text, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          prod.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: p.text),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${prod.orders} ${l.ordersWord}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 9.5, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (prod.oldPrice > 0)
                                Text(
                                  '${shopMoney(prod.oldPrice)} ${l.priceUnit}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: p.muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '${shopMoney(prod.price)} ${l.priceUnit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: prod.oldPrice > 0 ? const Color(0xFFEF4444) : p.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onAdd,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4BAF50), Color(0xFF57B55E)],
                              ),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: brandGreen.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
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
    );
  }
}

// ─── Brands ───────────────────────────────────────────────────────────────────

class _Brands extends StatelessWidget {
  const _Brands({required this.l, required this.p, required this.onTap});

  final ShopL10n l;
  final HomePalette p;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionHeader(title: l.brandsTitle, action: l.seeAll, p: p, onAction: () => onTap(l.brandsTitle)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shopBrands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final b = shopBrands[i];
              return GestureDetector(
                onTap: () => onTap(b.name),
                child: Container(
                  width: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    b.name,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: b.color, letterSpacing: 0.5),
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

// ─── Advantages ─────────────────────────────────────────────────────────────

class _Advantages extends StatelessWidget {
  const _Advantages({required this.l, required this.p});

  final ShopL10n l;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final icons = [LucideIcons.truck, LucideIcons.shield_check, LucideIcons.rotate_ccw, LucideIcons.headphones];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.advantagesTitle,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: List.generate(4, (i) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icons[i], size: 19, color: brandGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l.advTitles[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: p.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.advSubs[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 9, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Newsletter ───────────────────────────────────────────────────────────────

class _Newsletter extends StatelessWidget {
  const _Newsletter({required this.l, required this.p});

  final ShopL10n l;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.headerGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.newsletterTitle,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            l.newsletterSub,
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9), height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(color: p.headerCardBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    l.emailHint,
                    style: GoogleFonts.inter(fontSize: 13, color: p.muted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1B5E20),
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          l.subscribed,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    l.subscribeBtn,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.l});

  final ShopL10n l;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      color: const Color(0xFF111315),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.title,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.phone, size: 15, color: brandGreen),
              const SizedBox(width: 8),
              Text(
                '+992 90 123 45 67',
                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.map_pin, size: 15, color: brandGreen),
              const SizedBox(width: 8),
              Text(
                l.storeAddress,
                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final ic in [LucideIcons.send, LucideIcons.camera, LucideIcons.play, LucideIcons.message_circle])
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(ic, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom nav ─────────────────────────────────────────────────────────────

class _ShopBottomNav extends StatelessWidget {
  const _ShopBottomNav({required this.l, required this.p, required this.current, required this.onTap});

  final ShopL10n l;
  final HomePalette p;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.store, l.navShop),
      (LucideIcons.tag, l.navDeals),
      (LucideIcons.hammer, l.navRent),
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final on = i == current;
              final c = on ? brandGreen : p.muted;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].$1, size: 22, color: c),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i].$2,
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
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Cart sheet ─────────────────────────────────────────────────────────────

class _CartSheet extends ConsumerWidget {
  const _CartSheet({required this.l, required this.locale});

  final ShopL10n l;
  final AppLocale locale;

  void _set(WidgetRef ref, int idx, int qty) => ref.read(shopCartProvider.notifier).setQty(idx, qty);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final cart = ref.watch(shopCartProvider);
    final catalog = ref.watch(shopCatalogProvider);
    final entries = cart.entries.toList();
    final total = entries.fold<int>(0, (a, e) => a + catalog[e.key].price * e.value);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      decoration: BoxDecoration(
        color: p.pageBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l.cartTitle,
                    style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: p.text),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.shopping_cart, size: 20, color: p.muted),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  children: [
                    Icon(LucideIcons.shopping_cart, size: 44, color: p.muted),
                    const SizedBox(height: 12),
                    Text(l.cartEmpty, style: GoogleFonts.inter(fontSize: 14, color: p.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final idx = entries[i].key;
                    final qty = entries[i].value;
                    final prod = catalog[idx];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            color: p.productImageBg,
                            padding: const EdgeInsets.all(4),
                            child: buildShopProductImage(prod, fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.name(locale),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${shopMoney(prod.price)} ${l.priceUnit}',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: brandGreen),
                                ),
                              ],
                            ),
                          ),
                          _qtyBtn(LucideIcons.minus, p, () => _set(ref, idx, qty - 1)),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
                            ),
                          ),
                          _qtyBtn(LucideIcons.plus, p, () => _set(ref, idx, qty + 1)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: p.cardBg,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(l.total, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: p.muted)),
                      const Spacer(),
                      Text(
                        '${shopMoney(total)} ${l.priceUnit}',
                        style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: entries.isEmpty
                          ? null
                          : () async {
                              final discount = entries.fold<int>(0, (a, e) {
                                final pr = catalog[e.key];
                                return a + (pr.oldPrice > pr.price ? (pr.oldPrice - pr.price) * e.value : 0);
                              });
                              final ok = await completeShopCheckout(
                                context: context,
                                ref: ref,
                                items: Map<int, int>.from(cart),
                                total: total,
                                discount: discount,
                                catalog: catalog,
                                l: l,
                                clearCart: true,
                              );
                              if (ok && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: brandGreen.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        l.checkout,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
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

  Widget _qtyBtn(IconData icon, HomePalette p, VoidCallback onTap) {
    return Material(
      color: p.pageBg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
          child: Icon(icon, size: 14, color: p.text),
        ),
      ),
    );
  }
}

// ─── Horizontal product tile (search & "see all") ──────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.prod,
    required this.l,
    required this.p,
    required this.locale,
    required this.isFav,
    required this.onAdd,
    required this.onFav,
    required this.onOpen,
    this.priceUnit,
  });

  final ShopProduct prod;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final bool isFav;
  final VoidCallback onAdd;
  final VoidCallback onFav;
  final VoidCallback onOpen;
  final String? priceUnit;

  @override
  Widget build(BuildContext context) {
    final discount = prod.discountPercent;
    final unit = priceUnit ?? l.priceUnit;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(color: p.productImageBg, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(6),
                  child: buildShopProductImage(prod, fit: BoxFit.contain),
                ),
                if (discount > 0)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '-$discount%',
                        style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          prod.name(locale),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text, height: 1.2),
                        ),
                      ),
                      GestureDetector(
                        onTap: onFav,
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 17,
                          color: isFav ? const Color(0xFFEF4444) : p.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 3),
                      Text(
                        prod.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: p.text),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${prod.orders} ${l.ordersWord}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 10, color: p.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prod.oldPrice > 0)
                              Text(
                                '${shopMoney(prod.oldPrice)} $unit',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: p.muted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '${shopMoney(prod.price)} $unit',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: prod.oldPrice > 0 ? const Color(0xFFEF4444) : p.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: brandGreen,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onAdd,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(LucideIcons.plus, size: 18, color: Colors.white),
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
    );
  }
}

// ─── Search results ───────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.results,
    required this.l,
    required this.p,
    required this.locale,
    required this.fav,
    required this.onAdd,
    required this.onFav,
    required this.onOpen,
  });

  final List<ShopProduct> results;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final Set<int> fav;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onFav;
  final ValueChanged<ShopProduct> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(shopCatalogProvider);
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.search_x, size: 48, color: p.muted),
            const SizedBox(height: 12),
            Text(l.notFound, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: p.muted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final prod = results[i];
        final idx = catalog.indexOf(prod);
        return _ProductTile(
          prod: prod,
          l: l,
          p: p,
          locale: locale,
          isFav: fav.contains(idx),
          onAdd: () => onAdd(idx),
          onFav: () => onFav(idx),
          onOpen: () => onOpen(prod),
        );
      },
    );
  }
}

// ─── Tile list (deals / generic) ──────────────────────────────────────────────

class _TileListView extends ConsumerWidget {
  const _TileListView({
    required this.title,
    required this.products,
    required this.l,
    required this.p,
    required this.locale,
    required this.fav,
    required this.onAdd,
    required this.onFav,
    required this.onOpen,
    this.catalogList,
    this.priceUnit,
    this.headerIcon = LucideIcons.tag,
  });

  final String title;
  final List<ShopProduct> products;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final Set<int> fav;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onFav;
  final ValueChanged<ShopProduct> onOpen;
  final List<ShopProduct>? catalogList;
  final String? priceUnit;
  final IconData headerIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ShopProduct> catalog = catalogList ?? ref.watch(shopCatalogProvider);
    final unit = priceUnit ?? l.priceUnit;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: products.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
                  child: Icon(headerIcon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
                ),
              ],
            ),
          );
        }
        final prod = products[i - 1];
        final idx = catalog.indexOf(prod);
        return _ProductTile(
          prod: prod,
          l: l,
          p: p,
          locale: locale,
          priceUnit: unit,
          isFav: fav.contains(idx),
          onAdd: () => onAdd(idx),
          onFav: () => onFav(idx),
          onOpen: () => onOpen(prod),
        );
      },
    );
  }
}

// ─── "See all" page ─────────────────────────────────────────────────────────

class _AllProductsPage extends ConsumerWidget {
  const _AllProductsPage({
    required this.title,
    required this.products,
    required this.l,
    required this.p,
    required this.locale,
    required this.onOpen,
  });

  final String title;
  final List<ShopProduct> products;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final ValueChanged<ShopProduct> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final fav = ref.watch(shopFavoritesProvider);
    final catalog = ref.watch(shopCatalogProvider);
    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
              decoration: BoxDecoration(
                color: p.cardBg,
                border: Border(bottom: BorderSide(color: p.border)),
              ),
              child: Row(
                children: [
                  Material(
                    color: p.pageBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
                        child: Icon(LucideIcons.arrow_left, size: 17, color: p.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final prod = products[i];
                  final idx = catalog.indexOf(prod);
                  return _ProductTile(
                    prod: prod,
                    l: l,
                    p: p,
                    locale: locale,
                    isFav: fav.contains(idx),
                    onAdd: () {
                      ref.read(shopCartProvider.notifier).add(idx);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          backgroundColor: brandGreen,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 1100),
                          content: Text(l.addedToCart,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        ));
                    },
                    onFav: () => ref.read(shopFavoritesProvider.notifier).toggle(idx),
                    onOpen: () => onOpen(prod),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product detail page ──────────────────────────────────────────────────────

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.l,
    required this.locale,
    required this.onAdd,
    required this.onOpen,
    this.isRental = false,
    this.productIndex,
    this.priceUnit,
    this.similarCatalog,
  });

  final ShopProduct product;
  final ShopL10n l;
  final AppLocale locale;
  final ValueChanged<int> onAdd;
  final ValueChanged<ShopProduct> onOpen;
  final bool isRental;
  final int? productIndex;
  final String? priceUnit;
  final List<ShopProduct>? similarCatalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final List<ShopProduct> catalog = similarCatalog ?? ref.watch(shopCatalogProvider);
    final index = productIndex ?? catalog.indexOf(product);
    final unit = priceUnit ?? (isRental ? l.rentPriceUnit : l.priceUnit);
    final discount = product.discountPercent;
    final similar = [
      for (final pr in catalog)
        if (pr != product && pr.categoryIndex == product.categoryIndex) pr,
    ];
    final more = [
      for (final pr in catalog)
        if (pr != product && pr.categoryIndex != product.categoryIndex) pr,
    ];
    final related = [...similar, ...more].take(6).toList();

    void buy() async {
      if (index < 0) return;
      final disc = product.oldPrice > product.price ? product.oldPrice - product.price : 0;
      await completeShopCheckout(
        context: context,
        ref: ref,
        items: {index: 1},
        total: product.price,
        discount: disc,
        catalog: catalog,
        l: l,
        kind: isRental ? l.checkoutKindRent : l.checkoutKindShop,
      );
    }

    return Scaffold(
      backgroundColor: p.pageBg,
      body: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DetailHeader(
                  product: product,
                  productIndex: index,
                  p: p,
                  discount: discount,
                  l: l,
                  isRental: isRental,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${shopMoney(product.price)} $unit',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: discount > 0 ? const Color(0xFFEF4444) : p.text,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (product.oldPrice > 0) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${shopMoney(product.oldPrice)} $unit',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: p.muted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '-$discount%',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.star, size: 18, color: Color(0xFFFFC107)),
                            const SizedBox(width: 5),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${product.ratingsCount} ${l.ratingsWord}',
                              style: GoogleFonts.inter(fontSize: 12, color: p.muted),
                            ),
                            const Spacer(),
                            const Icon(LucideIcons.package_check, size: 16, color: brandGreen),
                            const SizedBox(width: 5),
                            Text(
                              '${product.orders} ${l.ordersWord}',
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _featChip(LucideIcons.shield_check, l.warranty, p),
                          _featChip(LucideIcons.badge_check, l.original, p),
                          _featChip(LucideIcons.truck, l.fastDelivery, p),
                          _featChip(LucideIcons.circle_check, l.inStock, p),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        product.name(locale),
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: p.text, height: 1.25),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l.aboutProduct,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.desc(locale),
                        style: GoogleFonts.inter(fontSize: 13.5, color: p.muted, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l.similarTitle,
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: related.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _SimilarCard(
                      prod: related[i],
                      l: l,
                      p: p,
                      locale: locale,
                      onOpen: () => onOpen(related[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: p.cardBg,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: buy,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRental ? brandGreen : const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              isRental ? l.rentBuyNow : l.buyNow,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      if (!isRental) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: index >= 0 ? () => onAdd(index) : null,
                            icon: const Icon(LucideIcons.shopping_cart, size: 18),
                            label: Text(
                              l.addToCartBtn,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _featChip(IconData icon, String label, HomePalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: brandGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: brandGreen),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.text)),
        ],
      ),
    );
  }
}

class _DetailHeader extends ConsumerWidget {
  const _DetailHeader({
    required this.product,
    required this.productIndex,
    required this.p,
    required this.discount,
    required this.l,
    this.isRental = false,
  });

  final ShopProduct product;
  final int productIndex;
  final HomePalette p;
  final int discount;
  final ShopL10n l;
  final bool isRental;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = isRental
        ? ref.watch(rentalFavoritesProvider).contains(productIndex)
        : ref.watch(shopFavoritesProvider).contains(productIndex);
    void toggleFav() {
      if (isRental) {
        ref.read(rentalFavoritesProvider.notifier).toggle(productIndex);
      } else {
        ref.read(shopFavoritesProvider.notifier).toggle(productIndex);
      }
    }
    return Stack(
      children: [
        Container(
          height: 320,
          width: double.infinity,
          color: p.productImageBg,
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          child: buildShopProductImage(product, fit: BoxFit.contain),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: SafeArea(
            child: _round(LucideIcons.arrow_left, () => Navigator.of(context).maybePop()),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: SafeArea(
            child: Row(
              children: [
                _round(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  toggleFav,
                  color: isFav ? const Color(0xFFEF4444) : const Color(0xFF1B1F24),
                ),
                const SizedBox(width: 8),
                _round(LucideIcons.share_2, () {}),
              ],
            ),
          ),
        ),
        if (discount > 0)
          Positioned(
            right: 0,
            top: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
              ),
              child: Column(
                children: [
                  Text('-$discount%', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l.warranty, style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        if (product.badge != ProductBadge.none)
          Positioned(
            left: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: product.badge == ProductBadge.hit ? const Color(0xFFF59E0B) : brandGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.badge == ProductBadge.hit ? l.badgeHit : l.badgeNew,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback onTap, {Color? color}) {
    return Material(
      color: p.cardBg,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: color ?? p.text),
        ),
      ),
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({required this.prod, required this.l, required this.p, required this.locale, required this.onOpen});

  final ShopProduct prod;
  final ShopL10n l;
  final HomePalette p;
  final AppLocale locale;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              color: p.productImageBg,
              padding: const EdgeInsets.all(8),
                            child: buildShopProductImage(prod, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 32,
                    child: Text(
                      prod.name(locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: p.text, height: 1.2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shopMoney(prod.price)} ${l.priceUnit}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: prod.oldPrice > 0 ? const Color(0xFFEF4444) : p.text,
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

class ShopFavoritesPage extends ConsumerWidget {
  const ShopFavoritesPage({
    super.key,
    required this.l,
    required this.locale,
    required this.onOpen,
  });

  final ShopL10n l;
  final AppLocale locale;
  final ValueChanged<ShopProduct> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final fav = ref.watch(shopFavoritesProvider);
    final catalog = ref.watch(shopCatalogProvider);
    final products = [for (final i in fav) if (i >= 0 && i < catalog.length) catalog[i]];

    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
              child: Row(
                children: [
                  Material(
                    color: p.pageBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
                        child: Icon(LucideIcons.arrow_left, size: 18, color: p.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l.favoritesTitle, style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: p.text)),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(l.favoritesEmpty, style: GoogleFonts.inter(color: p.muted)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final prod = products[i];
                        final idx = catalog.indexOf(prod);
                        return _ProductTile(
                          prod: prod,
                          l: l,
                          p: p,
                          locale: locale,
                          isFav: true,
                          onAdd: () {},
                          onFav: () {
                            ref.read(shopFavoritesProvider.notifier).remove(idx);
                          },
                          onOpen: () => onOpen(prod),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
