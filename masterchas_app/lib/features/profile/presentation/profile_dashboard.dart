import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../data/account_level.dart';
import '../providers/client_profile_stats_provider.dart';
import '../../masters/providers/master_favorites_provider.dart';
import 'profile_subpages.dart';
import 'widgets/profile_gamification.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fancy_confirm.dart';
import '../../chat/presentation/chats_list_page.dart';
import '../../chat/providers/chat_provider.dart' show unreadChatsTotalProvider;

class ProfileDashboard extends ConsumerWidget {
  const ProfileDashboard({
    super.key,
    this.bottomPadding = 110,
    this.onOpenProduct,
  });

  final double bottomPadding;
  final void Function(ShopProduct)? onOpenProduct;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(SmoothRoute<void>(builder: (_) => page));
  }

  static String _tx(AppLocale loc, String ru, String en, String tg, String zh) =>
      switch (loc) { AppLocale.ru => ru, AppLocale.en => en, AppLocale.tg => tg, AppLocale.zh => zh };

  void _openChats(BuildContext context, HomePalette p, AppLocale loc) {
    _push(
      context,
      Scaffold(
        backgroundColor: p.pageBg,
        appBar: AppBar(
          backgroundColor: p.pageBg,
          foregroundColor: p.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _tx(loc, 'Сообщения', 'Messages', 'Паёмҳо', '消息'),
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: p.text),
          ),
        ),
        body: SafeArea(top: false, child: ChatsListPage(p: p)),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref, AppLocale loc) async {
    final confirmed = await showFancyConfirm(
      context,
      icon: LucideIcons.trash_2,
      color: const Color(0xFFDC2626),
      title: _tx(loc, 'Удалить аккаунт?', 'Delete account?', 'Ҳисобро нест кунем?', '删除账户？'),
      message: _tx(
        loc,
        'Аккаунт, имя и номер будут удалены с сервера. Восстановить их будет нельзя. Этим же номером можно будет зарегистрироваться заново.',
        'Your account, name and phone will be removed from the server. This cannot be undone. You can register again with the same number.',
        'Ҳисоб, ном ва рақам аз сервер нест мешаванд. Барқарор кардан ғайриимкон аст.',
        '您的账户、姓名和手机号将从服务器删除，且无法恢复。',
      ),
      confirmLabel: _tx(loc, 'Удалить', 'Delete', 'Нест кардан', '删除'),
      cancelLabel: _tx(loc, 'Отмена', 'Cancel', 'Бекор', '取消'),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(authProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, style: GoogleFonts.manrope()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    context.go('/role');
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref, ProfileL10n l) async {
    final confirmed = await showFancyConfirm(
      context,
      icon: LucideIcons.log_out,
      color: brandGreen,
      title: l.signOutTitle,
      message: l.signOutMsg,
      confirmLabel: l.signOut,
      cancelLabel: l.cancel,
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) context.go('/role');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l = ProfileL10n.of(locale);
    final p = HomePalette.of(context);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final auth = ref.watch(authProvider);
    final name = auth.displayName ?? l.defaultUser;
    final phone = auth.phone ?? '—';

    final profileStats = ref.watch(clientProfileStatsProvider);
    final fav = ref.watch(masterFavoritesProvider);
    final cards = ref.watch(shopCardsProvider);
    final addrs = ref.watch(shopAddressesProvider);
    ref.watch(shopOrdersProvider);
    final orderNotifier = ref.read(shopOrdersProvider.notifier);

    final ordersCount = profileStats.ordersCount;
    final favCount = fav.length;
    final spent = profileStats.spent;
    final bonus = orderNotifier.totalBonus;
    final level = accountLevelFor(spent: spent, orders: ordersCount);

    final unread = ref.watch(unreadChatsTotalProvider).asData?.value ?? 0;
    const danger = Color(0xFFDC2626);

    Widget section(int i, Widget child) => Reveal(
          delay: Duration(milliseconds: 90 + 70 * i),
          child: child,
        );

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        _Header(
          l: l,
          p: p,
          name: name,
          phone: phone,
          flag: switch (locale) { AppLocale.ru => '🇷🇺', AppLocale.en => '🇬🇧', AppLocale.tg => '🇹🇯', AppLocale.zh => '🇨🇳' },
          editLabel: _tx(locale, 'Изменить имя', 'Edit name', 'Тағйири ном', '修改姓名'),
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
              section(
                0,
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: LucideIcons.shopping_bag,
                        tint: brandGreen,
                        value: ordersCount,
                        label: l.orders,
                        p: p,
                        floatPhase: 0,
                        onTap: () => _push(context, const ServiceOrdersPage()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: LucideIcons.heart,
                        tint: const Color(0xFF8B5CF6),
                        value: favCount,
                        label: l.favorites,
                        p: p,
                        floatPhase: 0.33,
                        onTap: () => _push(context, const FavoritesPage()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: LucideIcons.wallet,
                        tint: const Color(0xFFF59E0B),
                        value: spent,
                        format: (v) => '${shopMoney(v)} ${l.unit}',
                        label: l.spent,
                        p: p,
                        floatPhase: 0.66,
                        onTap: () => _push(context, const SpentPage()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              section(
                1,
                HoverLift(
                  radius: 20,
                  child: ShineSweep(
                    radius: 20,
                    child: LevelProgressCard(level: level, p: p, l: l),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              section(2, _BonusCard(l: l, bonus: bonus)),
              const SizedBox(height: 18),
              section(3, _AchievementsRow(ordersCount: ordersCount, p: p, l: l)),
              const SizedBox(height: 18),
              section(
                4,
                _MenuGroup(
                  title: _tx(locale, 'Мои дела', 'My stuff', 'Корҳои ман', '我的'),
                  p: p,
                  children: [
                    _MenuRow(
                      icon: LucideIcons.message_circle,
                      label: _tx(locale, 'Сообщения', 'Messages', 'Паёмҳо', '消息'),
                      p: p,
                      tint: const Color(0xFF3B82F6),
                      unread: unread,
                      onTap: () => _openChats(context, p, locale),
                    ),
                    _MenuRow(icon: LucideIcons.history, label: l.orderHistory, p: p, onTap: () => _push(context, const ServiceOrdersPage())),
                    _MenuRow(
                      icon: LucideIcons.heart,
                      label: l.favorites,
                      p: p,
                      tint: const Color(0xFF8B5CF6),
                      badge: favCount > 0 ? '$favCount' : null,
                      onTap: () => _push(context, const FavoritesPage()),
                    ),
                    _MenuRow(
                      icon: LucideIcons.map_pin,
                      label: l.myAddresses,
                      p: p,
                      tint: const Color(0xFFEF4444),
                      badge: '${addrs.length}',
                      onTap: () => _push(context, const AddressesPage()),
                    ),
                    _MenuRow(
                      icon: LucideIcons.credit_card,
                      label: l.paymentMethods,
                      p: p,
                      tint: const Color(0xFFF59E0B),
                      trailing: cards.isEmpty ? l.addCard : '•• ${cards.last.last4}',
                      onTap: () => _push(context, const PaymentMethodsPage()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              section(
                5,
                _MenuGroup(
                  title: _tx(locale, 'Настройки', 'Settings', 'Танзимот', '设置'),
                  p: p,
                  children: [
                    _MenuRow(
                      icon: LucideIcons.globe,
                      label: l.chooseLanguage,
                      p: p,
                      tint: const Color(0xFF14B8A6),
                      trailing: locale.label,
                      onTap: () => _languageSheet(context, ref, l),
                    ),
                    _MenuRow(
                      icon: isDark ? LucideIcons.moon : LucideIcons.sun,
                      label: l.darkTheme,
                      p: p,
                      tint: const Color(0xFF6366F1),
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      trailingWidget: Switch(
                        value: isDark,
                        activeTrackColor: brandGreen,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ),
                    _MenuRow(icon: LucideIcons.bell, label: l.notifications, p: p, tint: const Color(0xFFEC4899), onTap: () => _push(context, const NotificationsPage())),
                    _MenuRow(icon: LucideIcons.shield_check, label: l.security, p: p, onTap: () => _push(context, const SecurityPage())),
                    _MenuRow(icon: LucideIcons.headphones, label: l.support, p: p, tint: const Color(0xFF3B82F6), onTap: () => _push(context, const SupportPage())),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              section(
                6,
                HoverLift(
                  radius: 18,
                  lift: 2,
                  glowColor: danger,
                  child: Material(
                    color: p.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _signOut(context, ref, l),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.log_out, size: 18, color: danger),
                            const SizedBox(width: 8),
                            Text(
                              l.signOut,
                              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: danger),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              section(
                7,
                Center(
                  child: TextButton.icon(
                    onPressed: () => _deleteAccount(context, ref, locale),
                    icon: Icon(LucideIcons.trash_2, size: 15, color: p.muted),
                    label: Text(
                      _tx(locale, 'Удалить аккаунт', 'Delete account', 'Нест кардани ҳисоб', '删除账户'),
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Master.tj',
                  style: GoogleFonts.manrope(fontSize: 11, color: p.muted.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _languageSheet(BuildContext context, WidgetRef ref, ProfileL10n l) {
    final p = HomePalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final langs = [
          (AppLocale.ru, l.langRussian, '🇷🇺'),
          (AppLocale.en, l.langEnglish, '🇬🇧'),
          (AppLocale.tg, l.langTajik, '🇹🇯'),
          (AppLocale.zh, l.langChinese, '🇨🇳'),
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
                Text(l.chooseLanguage, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: p.text)),
                const SizedBox(height: 12),
                for (final lang in langs)
                  ListTile(
                    leading: Text(lang.$3, style: const TextStyle(fontSize: 22)),
                    title: Text(lang.$2, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
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
    required this.p,
    required this.name,
    required this.phone,
    required this.flag,
    required this.editLabel,
    required this.onSettings,
    required this.onCall,
    required this.onEditAvatar,
  });

  final ProfileL10n l;
  final HomePalette p;
  final String name;
  final String phone;
  final String flag;
  final String editLabel;
  final VoidCallback onSettings;
  final VoidCallback onCall;
  final VoidCallback onEditAvatar;

  Widget _roundBtn({required Widget child, required VoidCallback onTap, String? tooltip}) {
    return HoverLift(
      radius: 20,
      lift: 2,
      scale: 1.08,
      child: Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: p.headerGradient,
          ),
        ),
        child: Stack(
          children: [
            // Плавающие декоративные круги
            Positioned(
              top: -30,
              right: -20,
              child: FloatY(
                amplitude: 8,
                period: const Duration(milliseconds: 4200),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: FloatY(
                amplitude: 6,
                phase: 0.5,
                period: const Duration(milliseconds: 5200),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 18, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(
                    offsetY: 10,
                    child: Row(
                      children: [
                        Text(l.title, style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Spacer(),
                        _roundBtn(
                          onTap: onCall,
                          tooltip: l.support,
                          child: const Icon(LucideIcons.headphones, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        _roundBtn(
                          onTap: onSettings,
                          tooltip: l.chooseLanguage,
                          child: Text(flag, style: const TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Reveal(
                        delay: const Duration(milliseconds: 80),
                        offsetY: 0,
                        offsetX: -20,
                        child: HoverLift(
                          radius: 44,
                          scale: 1.06,
                          child: GestureDetector(
                            onTap: onEditAvatar,
                            child: PulseRing(
                              color: Colors.white,
                              size: 84,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          p.headerCardBg.withValues(alpha: 0.98),
                                          p.headerCardBg.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(initial, style: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w900, color: const Color(0xFF2E9E4F))),
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Reveal(
                          delay: const Duration(milliseconds: 160),
                          offsetY: 0,
                          offsetX: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: p.headerCardBg,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: p.text, height: 1.2),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(LucideIcons.phone, size: 12, color: p.muted),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(phone, maxLines: 1, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: p.muted)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const LiveDot(color: brandGreen, size: 7),
                                    const SizedBox(width: 5),
                                    Text(l.online, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: brandGreen)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: onEditAvatar,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: brandGreen.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.pencil, size: 11, color: brandGreen),
                                            const SizedBox(width: 4),
                                            Text(editLabel, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700, color: brandGreen)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    required this.p,
    required this.onTap,
    this.format,
    this.floatPhase = 0,
  });

  final IconData icon;
  final Color tint;
  final int value;
  final String Function(int)? format;
  final String label;
  final HomePalette p;
  final VoidCallback onTap;
  final double floatPhase;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 16,
      glowColor: tint,
      child: Material(
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
                FloatY(
                  amplitude: 2.5,
                  phase: floatPhase,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tint.withValues(alpha: 0.22), tint.withValues(alpha: 0.1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: tint),
                  ),
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) {
                    final n = v.round();
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        format != null ? format!(n) : '$n',
                        style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w900, color: p.text),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, color: p.muted, height: 1.15)),
              ],
            ),
          ),
        ),
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
    return HoverLift(
      radius: 18,
      glowColor: const Color(0xFF57B55E),
      child: ShineSweep(
        radius: 18,
        delay: const Duration(milliseconds: 900),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFF2E9E4F), Color(0xFF57B55E)]),
          ),
          child: Row(
            children: [
              FloatY(
                amplitude: 3,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.star, size: 22, color: Color(0xFFFFD54A)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.bonusesTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(l.bonusRate, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: bonus.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '${v.round()}',
                  style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.p, required this.children});

  final String title;
  final HomePalette p;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: p.muted),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: p.border, indent: 58),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.p,
    required this.onTap,
    this.tint = brandGreen,
    this.trailing,
    this.trailingWidget,
    this.badge,
    this.unread = 0,
  });

  final IconData icon;
  final String label;
  final HomePalette p;
  final VoidCallback onTap;
  final Color tint;
  final String? trailing;
  final Widget? trailingWidget;
  final String? badge;
  final int unread;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final p = w.p;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: w.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            color: _hover ? w.tint.withValues(alpha: 0.06) : Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: w.trailingWidget != null ? 6 : 13),
            child: Row(
              children: [
                AnimatedScale(
                  scale: _hover ? 1.12 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedRotation(
                    turns: _hover ? -0.03 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: w.tint.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
                      child: Icon(w.icon, size: 16, color: w.tint),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.only(left: _hover ? 4 : 0),
                    child: Text(w.label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
                  ),
                ),
                if (w.unread > 0) ...[
                  UnreadBadge(count: w.unread),
                  const SizedBox(width: 6),
                ],
                if (w.trailing != null)
                  Text(w.trailing!, style: GoogleFonts.manrope(fontSize: 12.5, color: p.muted, fontWeight: FontWeight.w600)),
                if (w.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: w.tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                    child: Text(w.badge!, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: w.tint)),
                  ),
                if (w.trailingWidget != null)
                  w.trailingWidget!
                else ...[
                  const SizedBox(width: 4),
                  AnimatedSlide(
                    offset: Offset(_hover ? 0.25 : 0, 0),
                    duration: const Duration(milliseconds: 220),
                    child: Icon(LucideIcons.chevron_right, size: 17, color: _hover ? w.tint : p.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Achievements / badges row ──
class _AchievementsRow extends StatelessWidget {
  const _AchievementsRow({required this.ordersCount, required this.p, required this.l});

  final int ordersCount;
  final HomePalette p;
  final ProfileL10n l;

  @override
  Widget build(BuildContext context) {
    final achievements = <({IconData icon, String label, Color color, bool unlocked})>[
      (icon: LucideIcons.rocket, label: l.achFirstOrder, color: const Color(0xFF57B55E), unlocked: ordersCount >= 1),
      (icon: LucideIcons.flame, label: l.ach5Orders, color: const Color(0xFFF59E0B), unlocked: ordersCount >= 5),
      (icon: LucideIcons.crown, label: l.ach10Orders, color: const Color(0xFF8B5CF6), unlocked: ordersCount >= 10),
      (icon: LucideIcons.star, label: l.achReview, color: const Color(0xFF3B82F6), unlocked: ordersCount >= 2),
      (icon: LucideIcons.gift, label: l.achRefer, color: const Color(0xFFEC4899), unlocked: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.medal, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            Text(
              l.achievementsTitle,
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(width: 6),
            Text(
              '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: p.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final a = achievements[i];
              return Reveal(
                delay: Duration(milliseconds: 120 + 70 * i),
                offsetY: 0,
                offsetX: 24,
                child: HoverLift(
                radius: 18,
                scale: 1.08,
                glowColor: a.unlocked ? a.color : null,
                child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: a.unlocked
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [a.color, Color.lerp(a.color, Colors.black, 0.2)!],
                              )
                            : null,
                        color: a.unlocked ? null : p.muted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: a.unlocked
                            ? [BoxShadow(color: a.color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Icon(
                        a.unlocked ? a.icon : LucideIcons.lock,
                        size: 26,
                        color: a.unlocked ? Colors.white : p.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: a.unlocked ? p.text : p.muted,
                        height: 1.15,
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
