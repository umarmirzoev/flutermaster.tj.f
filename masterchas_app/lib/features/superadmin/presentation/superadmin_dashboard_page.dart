import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/platform_store_provider.dart';
import '../../admin/providers/admin_provider.dart';
import '../data/superadmin_data.dart';
import '../models/superadmin_models.dart';
import '../providers/superadmin_provider.dart';
import '../theme/superadmin_theme.dart';
import 'widgets/superadmin_forms.dart';
import 'widgets/superadmin_widgets.dart';

class SuperAdminDashboardPage extends ConsumerWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adminDataProvider);
    final ui = ref.watch(superAdminUiProvider);
    final data = ref.watch(superAdminDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kpiRow(data),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final cw = w > 1100 ? (w - 36) / 4 : w > 700 ? (w - 12) / 2 : w;
            final orderChart = computeOrdersChart(data.orders);
            final payChart = computeIncomeChart(data.payouts);
            final masterSlices = data.masters.isEmpty
                ? const [SaPieSlice(label: 'Нет', value: 1, color: SuperAdminTheme.muted, percent: 100)]
                : [SaPieSlice(label: 'Мастера', value: data.masters.length.toDouble(), color: SuperAdminTheme.green, percent: 100)];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: cw, child: SaLineChartCard(title: 'Динамика заказов', points: orderChart, color: SuperAdminTheme.green, period: ui.chartPeriod, onPeriod: (p) => ref.read(superAdminUiProvider.notifier).setChartPeriod(p))),
                SizedBox(width: cw, child: SaBarChartCard(title: 'Выплаты', points: payChart)),
                SizedBox(width: cw, child: SaLineChartCard(title: 'Активность', points: orderChart, color: SuperAdminTheme.purple, period: ui.activityPeriod, onPeriod: (p) => ref.read(superAdminUiProvider.notifier).setActivityPeriod(p), periodOptions: const ['День', 'Неделя', 'Месяц'])),
                SizedBox(width: cw, child: SaPieChartCard(title: 'Мастера', slices: masterSlices, total: '${data.masters.length}')),
              ],
            );
          }),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth > 1000) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _ordersTable(data.orders, () => context.go('/superadmin/orders'))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _popularProducts(data.products, () => context.go('/superadmin/shop'))),
                ],
              );
            }
            return Column(children: [
              _ordersTable(data.orders, () => context.go('/superadmin/orders')),
              const SizedBox(height: 12),
              _popularProducts(data.products, () => context.go('/superadmin/shop')),
            ]);
          }),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final cw = w > 1100 ? (w - 36) / 4 : w > 700 ? (w - 12) / 2 : w;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: cw, child: _newUsers(data.clients)),
                SizedBox(width: cw, child: _topMasters(data.masters)),
                SizedBox(width: cw, child: _recentReviews(data.reviews)),
                SizedBox(width: cw, child: _notificationsFeed(data.notifications)),
              ],
            );
          }),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth > 1000) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _productsTable(data.products)),
                  const SizedBox(width: 12),
                  Expanded(child: _payoutsTable(data.payouts)),
                  const SizedBox(width: 12),
                  SizedBox(width: 280, child: _systemStatus(data.systemServices)),
                ],
              );
            }
            return Column(children: [
              _productsTable(data.products),
              const SizedBox(height: 12),
              _payoutsTable(data.payouts),
              const SizedBox(height: 12),
              _systemStatus(data.systemServices),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _kpiRow(PlatformStoreState data) {
    final total = data.orders.length;
    final done = data.orders.where((o) => o.status == SaOrderStatus.completed).length;
    final progress = data.orders.where((o) => o.status == SaOrderStatus.inProgress).length;
    final cancelled = data.orders.where((o) => o.status == SaOrderStatus.cancelled).length;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cw = w > 1200 ? (w - 60) / 6 : w > 800 ? (w - 36) / 3 : (w - 12) / 2;
      final kpis = [
        (LucideIcons.clipboard_list, 'Всего заказов', '$total', '${data.clients.length} клиентов', SuperAdminTheme.green, const Color(0xFFD1FAE5), true),
        (LucideIcons.circle_check, 'Выполнено', '$done', '', SuperAdminTheme.blue, const Color(0xFFDBEAFE), true),
        (LucideIcons.clock, 'В работе', '$progress', '', SuperAdminTheme.yellow, const Color(0xFFFEF3C7), true),
        (LucideIcons.circle_x, 'Отменено', '$cancelled', '', SuperAdminTheme.red, const Color(0xFFFEE2E2), false),
        (LucideIcons.wallet, 'Доход', '${formatSaMoney(data.totalOrderAmount)} с.', '', SuperAdminTheme.purple, const Color(0xFFEDE9FE), true),
        (LucideIcons.shopping_bag, 'Товары', '${data.products.length}', '${data.masters.length} мастеров', SuperAdminTheme.green, const Color(0xFFD1FAE5), true),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kpis.map((k) => SizedBox(width: cw.clamp(160, 220), child: SaKpiCard(label: k.$2, value: k.$3, change: k.$4, icon: k.$1, iconColor: k.$5, iconBg: k.$6, positive: k.$7))).toList(),
      );
    });
  }

  Widget _ordersTable(List<SaOrder> orders, VoidCallback onAll) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SaSectionTitle(title: 'Последние заказы', action: 'Все', onAction: onAll),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: SuperAdminTheme.muted),
              dataTextStyle: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.text),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Клиент')),
                DataColumn(label: Text('Мастер')),
                DataColumn(label: Text('Услуга')),
                DataColumn(label: Text('Дата')),
                DataColumn(label: Text('Статус')),
                DataColumn(label: Text('Сумма')),
              ],
              rows: orders.map((o) => DataRow(cells: [
                DataCell(Text(o.id, style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(Text(o.client)),
                DataCell(Text(o.master)),
                DataCell(Text(o.service)),
                DataCell(Text(o.date)),
                DataCell(SaStatusPill(label: saOrderStatusLabel(o.status), color: saOrderStatusColor(o.status))),
                DataCell(Text('${formatSaMoney(o.amount)} с.')),
              ])).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularProducts(List<SaProduct> products, VoidCallback onAll) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SaSectionTitle(title: 'Магазин: популярные товары', action: 'Все', onAction: onAll),
          const SizedBox(height: 12),
          ...products.take(4).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SaProductImage(product: p, size: 48)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(p.category, style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                      ]),
                    ),
                    Text('${formatSaMoney(p.price)} с.', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: SuperAdminTheme.green)),
                    const SizedBox(width: 8),
                    SaStatusPill(label: p.inStock ? 'В наличии' : 'Нет', color: p.inStock ? SuperAdminTheme.green : SuperAdminTheme.red),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _newUsers(List<SaClient> users) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Клиенты'),
          const SizedBox(height: 8),
          if (users.isEmpty) Text('Нет клиентов', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted)),
          ...users.take(4).map((u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: AssetImage(u.avatar)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(u.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    Text(u.date, style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                    if (u.isNew) ...[const SizedBox(width: 6), const SaStatusPill(label: 'Новый', color: SuperAdminTheme.blue)],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _topMasters(List<SaMaster> masters) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Топ мастера'),
          const SizedBox(height: 8),
          ...masters.take(4).map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: m.imageBytes != null ? MemoryImage(m.imageBytes!) : AssetImage(m.avatar) as ImageProvider),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107)),
                    Text(' ${m.rating}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('${m.orders} зак.', style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _recentReviews(List<SaReview> reviews) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Последние отзывы'),
          const SizedBox(height: 8),
          if (reviews.isEmpty) Text('Нет отзывов', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted)),
          ...reviews.take(4).map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: SuperAdminTheme.green.withValues(alpha: 0.12), child: Text(r.avatar, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: SuperAdminTheme.green))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Text(r.author, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)), ...List.generate(r.rating, (_) => const Icon(LucideIcons.star, size: 10, color: Color(0xFFFFC107)))]),
                        Text(r.text, style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _notificationsFeed(List<SaNotification> notifications) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Уведомления'),
          const SizedBox(height: 8),
          if (notifications.isEmpty) Text('Нет уведомлений', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted)),
          ...notifications.take(4).map((n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: n.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(n.icon, size: 14, color: n.color)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.title, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      Text(n.time, style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                    ])),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _productsTable(List<SaProduct> products) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Последние товары'),
          const SizedBox(height: 8),
          ...products.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Image.asset(p.image, width: 32, height: 32, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(LucideIcons.package, size: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    Text(p.category, style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                    const SizedBox(width: 8),
                    Text('${formatSaMoney(p.price)} с.', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('${p.sold}', style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.muted)),
                    const SizedBox(width: 8),
                    Icon(p.inStock ? LucideIcons.circle_check : LucideIcons.circle_x, size: 14, color: p.inStock ? SuperAdminTheme.green : SuperAdminTheme.red),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _payoutsTable(List<SaPayout> payouts) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Последние выплаты мастерам'),
          const SizedBox(height: 8),
          ...payouts.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(p.master, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${formatSaMoney(p.amount)} с.', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: SuperAdminTheme.green)),
                    const SizedBox(width: 8),
                    Text(p.method, style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                    const SizedBox(width: 8),
                    SaStatusPill(label: p.paid ? 'Выплачено' : 'Ожидает', color: p.paid ? SuperAdminTheme.green : SuperAdminTheme.yellow),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _systemStatus(List<SaSystemService> services) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SaSectionTitle(title: 'Статус системы'),
          const SizedBox(height: 8),
          ...services.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(s.name, style: GoogleFonts.inter(fontSize: 12))),
                    Icon(s.status == 'Работает' ? LucideIcons.circle_check : LucideIcons.circle_alert, size: 14, color: s.status == 'Работает' ? SuperAdminTheme.green : SuperAdminTheme.yellow),
                    const SizedBox(width: 4),
                    Text(s.status, style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
