import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../data/shop_data.dart';
import '../state/shop_state.dart';
import 'shop_profile.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggleFav(int idx) => ref.read(shopFavoritesProvider.notifier).toggle(idx);

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
      for (final p in shopProducts)
        if (p.ru.toLowerCase().contains(q) || p.en.toLowerCase().contains(q)) p,
    ];
  }

  void _add(int productIndex, ShopL10n l) {
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
      for (var i = 0; i < shopProducts.length; i++)
        if (shopProducts[i].badge == badge && (_cat == 0 || shopProducts[i].categoryIndex == _cat)) shopProducts[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l = ShopL10n.of(locale);
    final p = HomePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fav = ref.watch(shopFavoritesProvider);
    final cartCount = ref.watch(shopCartProvider).values.fold(0, (a, b) => a + b);

    final hits = _filtered(ProductBadge.hit);
    final news = _filtered(ProductBadge.isNew);
    final searching = _query.trim().isNotEmpty;
    final results = searching ? _search() : const <ShopProduct>[];
    final deals = [for (final pr in shopProducts) if (pr.discountPercent > 0) pr];

    return ColoredBox(
      color: p.shellBg,
      child: Center(
        child: Container(
          width: 390,
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height),
          decoration: BoxDecoration(
            color: p.pageBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: p.pageBg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    l: l,
                    p: p,
                    cartCount: cartCount,
                    controller: _searchCtrl,
                    onCart: () => _openCart(l, locale),
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
                        ? ShopProfilePage(onOpenProduct: _openProduct)
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
          ),
        ),
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
    required this.controller,
    required this.onCart,
    required this.onChanged,
    required this.onClear,
  });

  final ShopL10n l;
  final HomePalette p;
  final int cartCount;
  final TextEditingController controller;
  final VoidCallback onCart;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: p.cardBg,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circle(LucideIcons.arrow_left, p, () => Navigator.of(context).maybePop()),
              const SizedBox(width: 10),
              Text(
                l.title,
                style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: p.text),
              ),
              const Spacer(),
              _circle(LucideIcons.heart, p, () {}),
              const SizedBox(width: 8),
              _CartButton(p: p, count: cartCount, onTap: onCart),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: p.searchBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 18, color: p.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.inter(fontSize: 13, color: p.text),
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
                    child: Icon(LucideIcons.x, size: 18, color: p.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(IconData icon, HomePalette p, VoidCallback onTap) {
    return Material(
      color: p.pageBg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
          child: Icon(icon, size: 17, color: p.text),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
              child: Icon(LucideIcons.shopping_cart, size: 17, color: p.text),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
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

// ─── Categories ─────────────────────────────────────────────────────────────

class _Categories extends StatelessWidget {
  const _Categories({required this.l, required this.p, required this.selected, required this.onSelect});

  final ShopL10n l;
  final HomePalette p;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: l.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final on = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: on ? brandGreen : p.cardBg,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: on ? brandGreen : p.border),
                    ),
                    child: Icon(shopCategoryIcons[i], size: 24, color: on ? Colors.white : p.text),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l.categories[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? brandGreen : p.muted,
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

class _ProductRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final prod = products[i];
          final globalIndex = shopProducts.indexOf(prod);
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

class _ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final discount = prod.discountPercent;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          boxShadow: light
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]
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
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(prod.image, fit: BoxFit.contain),
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
                    onTap: onFav,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        size: 13,
                        color: isFav ? const Color(0xFFEF4444) : const Color(0xFF8B95A5),
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
                      Material(
                        color: brandGreen,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onAdd,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(LucideIcons.plus, size: 17, color: Colors.white),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF57B55E)],
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    l.emailHint,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8B95A5)),
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
                'г. Душанбе, ул. Бохтар, 123',
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
      (LucideIcons.user, l.navProfile),
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final on = i == current;
              final c = on ? brandGreen : p.muted;
              return InkWell(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i].$1, size: 20, color: c),
                    const SizedBox(height: 3),
                    Text(
                      items[i].$2,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        color: c,
                      ),
                    ),
                  ],
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
    final entries = cart.entries.toList();
    final total = entries.fold(0, (a, e) => a + shopProducts[e.key].price * e.value);

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
                    final prod = shopProducts[idx];
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
                            color: Colors.white,
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(prod.image, fit: BoxFit.contain),
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
                          : () {
                              final discount = entries.fold(0, (a, e) {
                                final pr = shopProducts[e.key];
                                return a + (pr.oldPrice > pr.price ? (pr.oldPrice - pr.price) * e.value : 0);
                              });
                              ref.read(shopOrdersProvider.notifier).add(
                                    ShopOrder(
                                      date: DateTime.now(),
                                      items: Map<int, int>.from(cart),
                                      total: total,
                                      discount: discount,
                                      bonus: (total * 0.01).round(),
                                    ),
                                  );
                              ref.read(shopCartProvider.notifier).clear();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: brandGreen,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    l.orderPlaced,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ),
                              );
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
  Widget build(BuildContext context) {
    final discount = prod.discountPercent;
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(prod.image, fit: BoxFit.contain),
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
                          LucideIcons.heart,
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
                                '${shopMoney(prod.oldPrice)} ${l.priceUnit}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: p.muted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '${shopMoney(prod.price)} ${l.priceUnit}',
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

class _SearchResults extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        final idx = shopProducts.indexOf(prod);
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

class _TileListView extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(LucideIcons.tag, size: 14, color: Colors.white),
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
        final idx = shopProducts.indexOf(prod);
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
    final fav = ref.watch(shopFavoritesProvider);
    return ColoredBox(
      color: p.shellBg,
      child: Center(
        child: Container(
          width: 390,
          decoration: BoxDecoration(color: p.pageBg),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
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
                        final idx = shopProducts.indexOf(prod);
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
          ),
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
  });

  final ShopProduct product;
  final ShopL10n l;
  final AppLocale locale;
  final ValueChanged<int> onAdd;
  final ValueChanged<ShopProduct> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final index = shopProducts.indexOf(product);
    final discount = product.discountPercent;
    final similar = [
      for (final pr in shopProducts)
        if (pr != product && pr.categoryIndex == product.categoryIndex) pr,
    ];
    final more = [
      for (final pr in shopProducts)
        if (pr != product && pr.categoryIndex != product.categoryIndex) pr,
    ];
    final related = [...similar, ...more].take(6).toList();

    void buy() {
      final disc = product.oldPrice > product.price ? product.oldPrice - product.price : 0;
      ref.read(shopOrdersProvider.notifier).add(
            ShopOrder(
              date: DateTime.now(),
              items: {index: 1},
              total: product.price,
              discount: disc,
              bonus: (product.price * 0.01).round(),
            ),
          );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: brandGreen,
            behavior: SnackBarBehavior.floating,
            content: Text(
              l.orderPlaced,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        );
    }

    return ColoredBox(
      color: p.shellBg,
      child: Center(
        child: Container(
          width: 390,
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height),
          decoration: BoxDecoration(color: p.pageBg),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: p.pageBg,
            body: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DetailHeader(product: product, p: p, discount: discount, l: l),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${shopMoney(product.price)} ${l.priceUnit}',
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
                                '${shopMoney(product.oldPrice)} ${l.priceUnit}',
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
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              l.buyNow,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => onAdd(index),
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
                  ),
                ),
              ),
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.product, required this.p, required this.discount, required this.l});

  final ShopProduct product;
  final HomePalette p;
  final int discount;
  final ShopL10n l;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 320,
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          child: Image.asset(product.image, fit: BoxFit.contain),
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
                _round(LucideIcons.heart, () {}),
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

  Widget _round(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: const Color(0xFF1B1F24)),
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
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Image.asset(prod.image, fit: BoxFit.contain),
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
