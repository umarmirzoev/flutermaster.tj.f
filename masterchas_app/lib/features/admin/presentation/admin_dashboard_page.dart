import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';
import 'widgets/admin_badges.dart';
import 'widgets/admin_charts.dart';
import 'widgets/admin_data_builder.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminDataBuilder(
      builder: (context, data) {
    final ui = ref.watch(adminUiProvider);
    final orders = data.orders;
    final inProgress = orders.where((o) => o.status == AdminOrderStatus.inProgress).length;
    final cancelled = orders.where((o) => o.status == AdminOrderStatus.cancelled).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final statW = w > 1200 ? 200.0 : w > 800 ? (w - 36) / 4 : (w - 12) / 2;
              final completed = orders.where((o) => o.status == AdminOrderStatus.completed).length;
              final stats = [
                AdminStatCard(
                  label: 'Заказы',
                  value: '${orders.length}',
                  change: '${data.clients.length} клиентов',
                  icon: LucideIcons.clipboard_list,
                  iconColor: AdminTheme.green,
                  iconBg: const Color(0xFFD1FAE5),
                ),
                AdminStatCard(
                  label: 'Выполнено',
                  value: '$completed',
                  change: '${data.masters.length} мастеров',
                  icon: LucideIcons.circle_check,
                  iconColor: AdminTheme.blue,
                  iconBg: const Color(0xFFDBEAFE),
                ),
                AdminStatCard(
                  label: 'В работе',
                  value: '$inProgress',
                  change: '-4% от вчера',
                  icon: LucideIcons.clock,
                  iconColor: AdminTheme.yellow,
                  iconBg: const Color(0xFFFEF3C7),
                  positive: false,
                ),
                AdminStatCard(
                  label: 'Отменено',
                  value: '$cancelled',
                  change: '-2% от вчера',
                  icon: LucideIcons.circle_x,
                  iconColor: AdminTheme.red,
                  iconBg: const Color(0xFFFEE2E2),
                  positive: false,
                ),
              ];
              final incomeCard = _IncomeCard(
                period: ui.incomePeriod,
                onPeriod: (p) => ref.read(adminUiProvider.notifier).setIncomePeriod(p),
                commissionTotal: data.transactions.where((t) => t.type == 'Комиссия').fold(0, (a, t) => a + t.amount),
                payoutTotal: data.transactions.where((t) => t.type == 'Выплата').fold(0, (a, t) => a + t.amount),
              );

              if (w >= 1180) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final stat in stats) ...[
                      SizedBox(width: statW.clamp(160, 200), child: stat),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: incomeCard),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: stats.map((s) => SizedBox(width: statW.clamp(150, 220), child: s)).toList(),
                  ),
                  const SizedBox(height: 12),
                  incomeCard,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final chartW = w > 1100 ? (w - 36) / 4 : w > 700 ? (w - 12) / 2 : w;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: chartW, child: AdminLineChartCard(title: 'Заказы по дням', points: adminOrdersChart(data), color: AdminTheme.green)),
                  SizedBox(width: chartW, child: AdminBarChartCard(title: 'Комиссия', points: adminIncomeChart(data))),
                  SizedBox(width: chartW, child: AdminLineChartCard(title: 'Заказы', points: adminOrdersChart(data), color: AdminTheme.purple)),
                  SizedBox(width: chartW, child: AdminLineChartCard(title: 'Выплаты', points: adminIncomeChart(data), color: AdminTheme.blue)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              if (w > 1000) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _RecentOrdersPanel(orders: orders.take(5).toList(), tab: ui.orderTab, onTab: (i) => ref.read(adminUiProvider.notifier).setOrderTab(i), onOpen: () => context.go('/admin/orders'))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _MastersPanel(masters: data.masters.take(4).toList(), onOpen: () => context.go('/admin/masters'))),
                    const SizedBox(width: 12),
                    SizedBox(width: 260, child: _ChatsPanel(chats: data.chats, onOpen: () => context.go('/admin/chats'))),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentOrdersPanel(orders: orders.take(5).toList(), tab: ui.orderTab, onTab: (i) => ref.read(adminUiProvider.notifier).setOrderTab(i), onOpen: () => context.go('/admin/orders')),
                  const SizedBox(height: 12),
                  _MastersPanel(masters: data.masters.take(4).toList(), onOpen: () => context.go('/admin/masters')),
                  const SizedBox(height: 12),
                  _ChatsPanel(chats: data.chats, onOpen: () => context.go('/admin/chats')),
                ],
              );
            },
          ),
        ],
      ),
    );
      },
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.period, required this.onPeriod, required this.commissionTotal, required this.payoutTotal});

  final String period;
  final ValueChanged<String> onPeriod;
  final int commissionTotal;
  final int payoutTotal;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Доход платформы',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.text),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(border: Border.all(color: AdminTheme.border), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: period,
                    isDense: true,
                    iconSize: 18,
                    style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.text),
                    items: ['Сегодня', 'Неделя', 'Месяц']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onPeriod(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _incomeCol('Комиссия', '${formatMoney(commissionTotal)} с.', 'всего', true, expanded: false),
                    const SizedBox(height: 10),
                    _incomeCol('Выплаты', '${formatMoney(payoutTotal)} с.', 'мастерам', true, expanded: false),
                    const SizedBox(height: 10),
                    _incomeCol('Чистый', '${formatMoney(commissionTotal - payoutTotal)} с.', 'баланс', commissionTotal >= payoutTotal, expanded: false),
                  ],
                );
              }
              return Row(
                children: [
                  _incomeCol('Комиссия', '${formatMoney(commissionTotal)} с.', 'всего', true),
                  _incomeCol('Выплаты', '${formatMoney(payoutTotal)} с.', 'мастерам', true),
                  _incomeCol('Баланс', '${formatMoney(commissionTotal - payoutTotal)} с.', 'чистый', commissionTotal >= payoutTotal),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _incomeCol(String label, String value, String change, bool pos, {bool expanded = true}) {
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AdminTheme.text)),
        ),
        Text(change, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pos ? AdminTheme.green : AdminTheme.red)),
      ],
    );
    return expanded ? Expanded(child: col) : col;
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.orders, required this.tab, required this.onTab, required this.onOpen});

  final List<AdminOrder> orders;
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onOpen;

  static const _tabs = ['Все', 'Новые', 'В работе', 'Выполнено', 'Отменено'];

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Последние заказы', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AdminTheme.text)),
              const Spacer(),
              TextButton(onPressed: onOpen, child: Text('Все', style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.green, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(_tabs.length, (i) {
              final on = tab == i;
              return InkWell(
                onTap: () => onTab(i),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: on ? AdminTheme.green.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: on ? AdminTheme.green : AdminTheme.border),
                  ),
                  child: Text(_tabs[i], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: on ? AdminTheme.green : AdminTheme.muted)),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          ...orders.map((o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: Text(o.id, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminTheme.text))),
                    Expanded(flex: 2, child: Text(o.client, style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.text), overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(o.master, style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.muted), overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(o.service, style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.muted), overflow: TextOverflow.ellipsis)),
                    AdminStatusBadge(status: o.status),
                    const SizedBox(width: 8),
                    Text(o.date, style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MastersPanel extends StatelessWidget {
  const _MastersPanel({required this.masters, required this.onOpen});

  final List<AdminMaster> masters;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Мастера', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AdminTheme.text)),
              const Spacer(),
              TextButton(onPressed: onOpen, child: Text('Все', style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.green, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          ...masters.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: AssetImage(m.avatar)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                          Text(m.specialization, style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted)),
                        ],
                      ),
                    ),
                    Text('${m.orders}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107)),
                        Text(m.rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text('${formatMoney(m.income)} с.', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AdminTheme.green)),
                    const SizedBox(width: 8),
                    AdminMasterBadge(status: m.status),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ChatsPanel extends StatelessWidget {
  const _ChatsPanel({required this.chats, required this.onOpen});

  final List<AdminChat> chats;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Чаты', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AdminTheme.text)),
              const Spacer(),
              TextButton(onPressed: onOpen, child: Text('Все', style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.green, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          ...chats.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AdminTheme.green.withValues(alpha: 0.15),
                      child: Text(c.avatar, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AdminTheme.green)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                          Text(c.lastMessage, style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(c.time, style: GoogleFonts.inter(fontSize: 10, color: AdminTheme.muted)),
                        if (c.unread > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AdminTheme.green, shape: BoxShape.circle),
                            child: Text('${c.unread}', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
