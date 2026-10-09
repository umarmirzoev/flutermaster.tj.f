import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/fancy_confirm.dart';
import '../../../core/widgets/motion.dart';
import '../../chat/presentation/chats_list_page.dart' show UnreadBadge;
import '../../chat/providers/chat_provider.dart' show unreadChatsTotalProvider;
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/master_palette.dart';
import '../../auth/models/master_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/order_workflow_provider.dart';
import 'widgets/master_pending_order_card.dart';
import 'cabinet/master_cabinet_shell.dart';
import 'master_pending_profile.dart';
import 'widgets/master_avatar.dart';

class MasterDashboard extends ConsumerWidget {
  const MasterDashboard({super.key, this.bottomPadding = 110});

  final double bottomPadding;

  Future<void> _addPortfolioPhoto(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    await ref
        .read(authProvider.notifier)
        .addPortfolioPhoto(base64Encode(bytes));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Фото добавлено в портфолио', style: GoogleFonts.manrope()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showFancyConfirm(
      context,
      icon: LucideIcons.log_out,
      color: masterNavy,
      title: 'Выйти?',
      message: 'Вы выйдете из аккаунта мастера. Войти снова можно по номеру и паролю.',
      confirmLabel: 'Выйти',
      cancelLabel: 'Отмена',
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) context.go('/role');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).masterProfile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator(color: masterNavy));
    }

    final ratingLabel =
        profile.rating > 0 ? profile.rating.toStringAsFixed(1) : '—';

    final workflowOrders = ref.watch(mergedMasterOrdersProvider).value ?? [];
    final pendingOrders =
        workflowOrders.where((o) => o.statusCode == 3).toList();
    final activeCount = workflowOrders
        .where((o) => o.statusCode == 4 || o.statusCode == 5)
        .length;
    final completedCount =
        workflowOrders.where((o) => o.statusCode == 6).length;
    final unreadChats = ref.watch(unreadChatsTotalProvider).asData?.value ?? 0;
    final level = _MasterLevel.of(
      completedCount > profile.completedOrders ? completedCount : profile.completedOrders,
    );

    Widget section(int i, Widget child) => Reveal(
          delay: Duration(milliseconds: 80 + 70 * i),
          child: child,
        );

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        _DashboardHeader(
          profile: profile,
          ratingLabel: ratingLabel,
          onLogout: () => _signOut(context, ref),
        ),
        if (pendingOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Reveal(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PulseRing(
                        color: Color(0xFFEF4444),
                        size: 10,
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Новые заявки (${pendingOrders.length})',
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: masterNavy),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/master/cabinet/orders'),
                        child: Text(
                          'Все заказы',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: masterNavy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pendingOrders.map(
                    (order) => MasterPendingOrderCard(order: order, compact: true),
                  ),
                ],
              ),
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
                        icon: LucideIcons.circle_check,
                        tint: const Color(0xFF22C55E),
                        value: completedCount,
                        label: 'Выполнено заказов',
                        phase: 0,
                        onTap: () => context.push('/master/cabinet/orders'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: LucideIcons.wallet,
                        tint: const Color(0xFFF59E0B),
                        value: profile.monthlyIncome,
                        format: formatSomoni,
                        label: 'Доход за месяц',
                        phase: 0.25,
                        onTap: () => context.push('/master/cabinet/income'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              section(
                1,
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: LucideIcons.calendar_check,
                        tint: const Color(0xFF3B82F6),
                        value: activeCount,
                        label: 'Активные заказы',
                        phase: 0.5,
                        onTap: () => context.push('/master/cabinet/active-orders'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: LucideIcons.star,
                        tint: const Color(0xFF8B5CF6),
                        value: 0,
                        textValue: ratingLabel,
                        label: profile.reviewCount > 0 ? 'Рейтинг · ${profile.reviewCount} отзывов' : 'Рейтинг',
                        phase: 0.75,
                        onTap: () => context.push('/master/cabinet/rating'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              section(2, _LevelCard(level: level, onTap: () => context.push('/master/cabinet/level'))),
              const SizedBox(height: 18),
              section(
                3,
                Text(
                  'Быстрые действия',
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: masterNavy),
                ),
              ),
              const SizedBox(height: 10),
              section(
                4,
                Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        icon: LucideIcons.message_circle,
                        label: 'Чаты',
                        tint: const Color(0xFF3B82F6),
                        badge: unreadChats,
                        onTap: () => context.push('/master/cabinet/chats'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickTile(
                        icon: LucideIcons.calendar,
                        label: 'График',
                        tint: const Color(0xFF22C55E),
                        onTap: () => context.push('/master/cabinet/schedule'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickTile(
                        icon: LucideIcons.map_pin,
                        label: 'Зона',
                        tint: const Color(0xFFEF4444),
                        onTap: () => context.push('/master/cabinet/zone'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickTile(
                        icon: LucideIcons.wrench,
                        label: 'Услуги',
                        tint: const Color(0xFFF59E0B),
                        onTap: () => context.push('/master/cabinet/services'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              section(
                5,
                _PanelCard(
                  icon: LucideIcons.image,
                  title: 'Портфолио работ',
                  trailing: _LinkText(label: 'Смотреть все', onTap: () => context.push('/master/cabinet/portfolio')),
                  child: profile.portfolioBase64.isEmpty
                      ? HoverLift(
                          radius: 14,
                          lift: 2,
                          child: GestureDetector(
                            onTap: () => _addPortfolioPhoto(context, ref),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 26),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [masterPageBg, masterNavy.withValues(alpha: 0.05)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: masterNavy.withValues(alpha: 0.12)),
                              ),
                              child: Column(
                                children: [
                                  FloatY(
                                    amplitude: 4,
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: masterNavy.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.image_plus, color: masterNavy, size: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Добавьте фото выполненных работ',
                                    style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: masterNavy),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Клиенты чаще выбирают мастеров с фото',
                                    style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: profile.portfolioBase64.length.clamp(0, 6),
                          itemBuilder: (context, index) {
                            return Reveal(
                              delay: Duration(milliseconds: 60 * index),
                              child: HoverLift(
                                radius: 12,
                                scale: 1.05,
                                child: GestureDetector(
                                  onTap: () => context.push('/master/cabinet/portfolio'),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      Uint8List.fromList(base64Decode(profile.portfolioBase64[index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 14),
              section(
                6,
                HoverLift(
                  radius: 18,
                  lift: 3,
                  child: GestureDetector(
                    onTap: () => context.push('/master/cabinet/rating'),
                    child: _PanelCard(
                      icon: LucideIcons.message_circle,
                      title: 'Отзывы клиентов',
                      trailing: _LinkText(label: 'Смотреть все', onTap: () => context.push('/master/cabinet/rating')),
                      child: Row(
                        children: [
                          Text(
                            ratingLabel,
                            style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w900, color: masterNavy),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    for (var i = 0; i < 5; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 2),
                                        child: Icon(
                                          LucideIcons.star,
                                          size: 16,
                                          color: i < profile.rating.round()
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.reviewCount > 0
                                      ? '${profile.reviewCount} отзывов от клиентов'
                                      : 'Пока нет отзывов — выполните первый заказ',
                                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              section(
                7,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ваши услуги (${profile.selectedServices.length})',
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: masterNavy),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/master/cabinet/services'),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text('Добавить', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(foregroundColor: masterNavy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (profile.selectedServices.isEmpty)
                section(
                  8,
                  HoverLift(
                    radius: 14,
                    lift: 2,
                    child: GestureDetector(
                      onTap: () => context.push('/master/cabinet/services'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: masterPageBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8ECF1)),
                        ),
                        child: Text(
                          'Добавьте услуги и укажите цены',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...profile.selectedServices.take(8).toList().asMap().entries.map(
                      (e) => Reveal(
                        delay: Duration(milliseconds: 500 + 50 * e.key),
                        offsetX: 20,
                        offsetY: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ServiceRow(
                            name: profile.serviceName(e.value),
                            price: formatSomoni(profile.priceForService(e.value)),
                            onTap: () => context.push('/master/cabinet/services'),
                          ),
                        ),
                      ),
                    ),
              if (profile.selectedServices.length > 8)
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/master/cabinet/services'),
                    child: Text(
                      'Все услуги (${profile.selectedServices.length})',
                      style: GoogleFonts.manrope(color: masterNavy, fontWeight: FontWeight.w700),
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

/// Уровень мастера — те же ступени, что на экране «Уровень мастера».
class _MasterLevel {
  const _MasterLevel(this.name, this.orders, this.min, this.nextMin, this.nextName, this.color);

  final String name;
  final int orders;
  final int min;
  final int nextMin;
  final String? nextName;
  final Color color;

  double get progress => nextName == null ? 1 : ((orders - min) / (nextMin - min)).clamp(0.0, 1.0);

  static _MasterLevel of(int orders) {
    const levels = [
      (name: 'Старт', min: 0, color: Color(0xFF22C55E)),
      (name: 'Бронза', min: 10, color: Color(0xFFCD7F32)),
      (name: 'Серебро', min: 50, color: Color(0xFF94A3B8)),
      (name: 'Золото', min: 150, color: Color(0xFFF59E0B)),
      (name: 'Platinum', min: 500, color: Color(0xFF8B5CF6)),
    ];
    var i = 0;
    for (var k = 0; k < levels.length; k++) {
      if (orders >= levels[k].min) i = k;
    }
    final cur = levels[i];
    final hasNext = i + 1 < levels.length;
    return _MasterLevel(
      cur.name,
      orders,
      cur.min,
      hasNext ? levels[i + 1].min : cur.min,
      hasNext ? levels[i + 1].name : null,
      cur.color,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.profile,
    required this.ratingLabel,
    required this.onLogout,
  });

  final MasterProfile profile;
  final String ratingLabel;
  final VoidCallback onLogout;

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFFFFD54A)),
            const SizedBox(width: 5),
            Text(text, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [masterNavy, masterNavyLight],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: FloatY(
                amplitude: 8,
                period: const Duration(milliseconds: 4800),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF57B55E).withValues(alpha: 0.35), const Color(0xFF57B55E).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: FloatY(
                amplitude: 6,
                phase: 0.5,
                period: const Duration(milliseconds: 5600),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(
                    offsetY: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Кабинет мастера',
                            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        HoverLift(
                          radius: 20,
                          lift: 2,
                          scale: 1.08,
                          child: Tooltip(
                            message: 'Выйти',
                            child: GestureDetector(
                              onTap: onLogout,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: const Icon(LucideIcons.log_out, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Reveal(
                        delay: const Duration(milliseconds: 80),
                        offsetY: 0,
                        offsetX: -20,
                        child: PulseRing(
                          color: const Color(0xFF4ADE80),
                          size: 76,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: masterAvatar(profile: profile, size: 71),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Reveal(
                          delay: const Duration(milliseconds: 150),
                          offsetY: 0,
                          offsetX: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.shortName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const LiveDot(color: Color(0xFF4ADE80), size: 8),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Онлайн',
                                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF4ADE80)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF57B55E).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Мастер · ${masterPrimaryCategory(profile)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    delay: const Duration(milliseconds: 220),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(LucideIcons.star, 'Рейтинг $ratingLabel'),
                        _pill(LucideIcons.message_circle, '${profile.reviewCount} отзывов'),
                        _pill(LucideIcons.wrench, '${profile.selectedServices.length} услуг'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    this.textValue,
    this.format,
    this.phase = 0,
    this.onTap,
  });

  final IconData icon;
  final Color tint;
  final int value;
  final String? textValue;
  final String Function(int)? format;
  final String label;
  final double phase;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 16,
      glowColor: tint,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF1)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, tint.withValues(alpha: 0.05)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FloatY(
                      amplitude: 2.5,
                      phase: phase,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: tint, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.chevron_right, size: 16, color: masterNavy.withValues(alpha: 0.35)),
                  ],
                ),
                const SizedBox(height: 12),
                if (textValue != null)
                  Text(
                    textValue!,
                    style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: masterNavy),
                  )
                else
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value.toDouble()),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        format != null ? format!(v.round()) : '${v.round()}',
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: masterNavy),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onTap});

  final _MasterLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = level.color;
    final left = level.nextMin - level.orders;
    return HoverLift(
      radius: 20,
      glowColor: c,
      child: ShineSweep(
        radius: 20,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [masterNavy, Color.lerp(masterNavyLight, c, 0.35)!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FloatY(
                      amplitude: 3,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(LucideIcons.award, color: c, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Уровень мастера', style: GoogleFonts.manrope(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                          Text(level.name, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevron_right, color: Colors.white.withValues(alpha: 0.7), size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: level.progress),
                    duration: const Duration(milliseconds: 1300),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(c),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.nextName == null
                      ? 'Максимальный уровень — вы лучший!'
                      : 'Ещё $left заказов до уровня «${level.nextName}»',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 16,
      scale: 1.06,
      glowColor: tint,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tint.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [tint, Color.lerp(tint, Colors.black, 0.18)!],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Icon(icon, color: Colors.white, size: 19),
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: UnreadBadge(count: badge, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: masterNavy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: masterNavy),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: masterNavy),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LinkText extends StatefulWidget {
  const _LinkText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<_LinkText> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: masterNavy),
            ),
            AnimatedSlide(
              offset: Offset(_hover ? 0.3 : 0, 0),
              duration: const Duration(milliseconds: 200),
              child: const Icon(LucideIcons.chevron_right, size: 15, color: masterNavy),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.name, required this.price, required this.onTap});

  final String name;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 14,
      lift: 2,
      scale: 1.01,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF57B55E), shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: masterNavy.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    price,
                    style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: masterNavy),
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
