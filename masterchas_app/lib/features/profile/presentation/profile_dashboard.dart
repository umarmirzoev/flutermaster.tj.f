import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../shop/data/shop_data.dart';
import '../../shop/state/shop_state.dart';
import '../data/profile_l10n.dart';
import 'edit_name_sheet.dart';
import 'service_orders_page.dart';
import 'profile_subpages.dart';

class ProfileDashboard extends ConsumerWidget {
  const ProfileDashboard({
    super.key,
    this.bottomPadding = 110,
    this.onOpenProduct,
  });

  final double bottomPadding;
  final void Function(ShopProduct)? onOpenProduct;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l = ProfileL10n.of(locale);
    final p = HomePalette.of(context);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final auth = ref.watch(authProvider);
    final name = auth.displayName ?? 'Пользователь';
    final phone = auth.phone ?? '—';

    final orders = ref.watch(shopOrdersProvider);
    final fav = ref.watch(shopFavoritesProvider);
    final cards = ref.watch(shopCardsProvider);
    final addrs = ref.watch(shopAddressesProvider);
    final orderNotifier = ref.read(shopOrdersProvider.notifier);

    final ordersCount = orders.length;
    final favCount = fav.length;
    final spent = orderNotifier.totalSpent;
    final bonus = orderNotifier.totalBonus;
    const toGold = 2000;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        _Header(
          l: l,
          name: name,
          phone: phone,
          onSettings: () => _languageSheet(context, ref, l),
          onCall: () => _push(context, const SupportPage()),
          onEditAvatar: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EditNameSheet(initialName: name),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.shopping_bag,
                      tint: brandGreen,
                      value: '$ordersCount',
                      label: l.orders,
                      p: p,
                      onTap: () => _push(context, const ServiceOrdersPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.heart,
                      tint: const Color(0xFF8B5CF6),
                      value: '$favCount',
                      label: l.favorites,
                      p: p,
                      onTap: () => _push(context, FavoritesPage(onOpenProduct: onOpenProduct)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.wallet,
                      tint: const Color(0xFFF59E0B),
                      value: '${shopMoney(spent)} ${l.unit}',
                      label: l.spent,
                      p: p,
                      onTap: () => _push(context, const SpentPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _LevelCard(l: l, toGold: toGold, spent: spent)),
                  const SizedBox(width: 12),
                  Expanded(child: _BonusCard(l: l, bonus: bonus)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    _MenuRow(icon: LucideIcons.history, label: l.orderHistory, p: p, onTap: () => _push(context, const ServiceOrdersPage())),
                    _divider(p),
                    _MenuRow(
                      icon: LucideIcons.credit_card,
                      label: l.paymentMethods,
                      p: p,
                      trailing: cards.isEmpty ? l.addCard : '•• ${cards.last.last4}',
                      onTap: () => _push(context, const PaymentMethodsPage()),
                    ),
                    _divider(p),
                    _MenuRow(
                      icon: LucideIcons.map_pin,
                      label: l.myAddresses,
                      p: p,
                      badge: '${addrs.length}',
                      onTap: () => _push(context, const AddressesPage()),
                    ),
                    _divider(p),
                    _MenuRow(icon: LucideIcons.shield_check, label: l.security, p: p, onTap: () => _push(context, const SecurityPage())),
                    _divider(p),
                    _MenuRow(icon: LucideIcons.bell, label: l.notifications, p: p, onTap: () => _push(context, const NotificationsPage())),
                    _divider(p),
                    _MenuRow(icon: LucideIcons.headphones, label: l.support, p: p, onTap: () => _push(context, const SupportPage()), last: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(11)),
                      child: const Icon(LucideIcons.moon, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.darkTheme, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
                          const SizedBox(height: 2),
                          Text(l.darkThemeSub, style: GoogleFonts.inter(fontSize: 11, color: p.muted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeTrackColor: brandGreen,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(HomePalette p) => Divider(height: 1, thickness: 1, color: p.border, indent: 56);

  void _languageSheet(BuildContext context, WidgetRef ref, ProfileL10n l) {
    final p = HomePalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        const langs = [
          (AppLocale.ru, 'Русский', '🇷🇺'),
          (AppLocale.en, 'English', '🇬🇧'),
          (AppLocale.tg, 'Тоҷикӣ', '🇹🇯'),
          (AppLocale.zh, '中文', '🇨🇳'),
        ];
        final current = ref.read(localeProvider);
        return Container(
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
                Text(l.chooseLanguage, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
                const SizedBox(height: 12),
                for (final lang in langs)
                  ListTile(
                    leading: Text(lang.$3, style: const TextStyle(fontSize: 22)),
                    title: Text(lang.$2, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                    trailing: current == lang.$1 ? const Icon(LucideIcons.check, color: brandGreen) : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(lang.$1);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.l,
    required this.name,
    required this.phone,
    required this.onSettings,
    required this.onCall,
    required this.onEditAvatar,
  });

  final ProfileL10n l;
  final String name;
  final String phone;
  final VoidCallback onSettings;
  final VoidCallback onCall;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 18, 16, 22),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E9E4F), Color(0xFF57B55E), Color(0xFF7CC97F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.title, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              GestureDetector(
                onTap: onSettings,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(LucideIcons.settings, size: 19, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                onTap: onEditAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.55)]),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial, style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, color: const Color(0xFF2E9E4F))),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(color: brandGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(LucideIcons.pencil, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1C1C),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          phone,
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(l.online, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: brandGreen)),
                        ],
                      ),
                    ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.tint, required this.value, required this.label, required this.p, required this.onTap});

  final IconData icon;
  final Color tint;
  final String value;
  final String label;
  final HomePalette p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: tint),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: p.text)),
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: p.muted, height: 1.15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.l, required this.toGold, required this.spent});

  final ProfileL10n l;
  final int toGold;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final progress = (spent / (spent + toGold)).clamp(0.05, 0.95);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF2B2F36), Color(0xFF3C434D)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.medal, size: 18, color: Color(0xFFC0C7D0)),
              const SizedBox(width: 6),
              Expanded(child: Text(l.accountLevel, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.7), height: 1.15))),
            ],
          ),
          const SizedBox(height: 6),
          Text('Silver', style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.18), valueColor: const AlwaysStoppedAnimation(brandGreen)),
          ),
          const SizedBox(height: 6),
          Text(l.toGold(toGold), style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  const _BonusCard({required this.l, required this.bonus});

  final ProfileL10n l;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF2E9E4F), Color(0xFF57B55E)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.star, size: 18, color: Color(0xFFFFD54A)),
              const SizedBox(width: 6),
              Expanded(child: Text(l.bonusesTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.85), height: 1.15))),
            ],
          ),
          const SizedBox(height: 6),
          Text('$bonus +', style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          Text(l.bonusRate, style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.p,
    required this.onTap,
    this.trailing,
    this.badge,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final HomePalette p;
  final VoidCallback onTap;
  final String? trailing;
  final String? badge;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: brandGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: brandGreen),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: p.text))),
              if (trailing != null) Text(trailing!, style: GoogleFonts.inter(fontSize: 12.5, color: p.muted)),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: brandGreen.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: brandGreen)),
                ),
              const SizedBox(width: 6),
              Icon(LucideIcons.chevron_right, size: 17, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
