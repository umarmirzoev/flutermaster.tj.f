import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/platform_models.dart';
import '../../../core/providers/platform_store_provider.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';
import 'widgets/admin_badges.dart';
import 'widgets/admin_charts.dart';
import 'widgets/admin_data_builder.dart';

// ─── Orders ───────────────────────────────────────────────────────────────────

class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key, this.statusFilter});

  final AdminOrderStatus? statusFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(orderWorkflowProvider);
    return AdminDataBuilder(
      builder: (context, data) {
    final query = ref.watch(adminUiProvider).searchQuery;
    final resolveStatus = (AdminOrder o) => effectiveAdminOrderStatus(ref, o);
    final orders = filterOrders(
      data.orders,
      status: statusFilter,
      query: query,
      resolveStatus: resolveStatus,
    );
    final title = switch (statusFilter) {
      AdminOrderStatus.newOrder => 'Новые заказы',
      AdminOrderStatus.inProgress => 'Заказы в работе',
      AdminOrderStatus.completed => 'Выполненные заказы',
      AdminOrderStatus.cancelled => 'Отменённые заказы',
      null => 'Все заказы',
    };

    return _AdminPageScaffold(
      title: title,
      count: orders.length,
      child: _DataTable(
        columns: const ['ID', 'Клиент', 'Мастер', 'Услуга', 'Сумма', 'Статус', 'Дата', 'Действия'],
        rows: orders.map((o) {
          final workflowEntry =
              ref.read(orderWorkflowProvider.notifier).entryFor(o.fullId);
          final displayStatus = workflowEntry != null
              ? workflowCodeToAdminStatus(workflowEntry.statusCode)
              : o.status;
          return [
            Text(o.id, style: _cellStyle(bold: true)),
            Text(o.client, style: _cellStyle()),
            Text(o.master, style: _cellStyle(muted: true)),
            Text(o.service, style: _cellStyle(muted: true)),
            Text('${formatMoney(o.amount)} с.', style: _cellStyle(bold: true)),
            workflowEntry != null
                ? AdminWorkflowStatusBadge(statusCode: workflowEntry.statusCode)
                : AdminStatusBadge(status: displayStatus),
            Text(o.date, style: _cellStyle(muted: true)),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.ellipsis, size: 16),
              onSelected: (v) {
                if (v == 'accept') {
                  adminApproveOrder(ref, o);
                  return;
                }
                final status = switch (v) {
                  'new' => AdminOrderStatus.newOrder,
                  'progress' => AdminOrderStatus.inProgress,
                  'done' => AdminOrderStatus.completed,
                  'cancel' => AdminOrderStatus.cancelled,
                  _ => o.status,
                };
                adminUpdateOrderStatus(ref, o, status);
              },
              itemBuilder: (_) => [
                if (displayStatus == AdminOrderStatus.newOrder ||
                    (workflowEntry?.statusCode ?? 1) < 3)
                  const PopupMenuItem(
                    value: 'accept',
                    child: Text('Принять заявку'),
                  ),
                const PopupMenuItem(value: 'new', child: Text('Новый')),
                const PopupMenuItem(value: 'progress', child: Text('В работе')),
                const PopupMenuItem(value: 'done', child: Text('Выполнено')),
                const PopupMenuItem(value: 'cancel', child: Text('Отменить')),
              ],
            ),
          ];
        }).toList(),
      ),
    );
      },
    );
  }
}

// ─── Masters ──────────────────────────────────────────────────────────────────

class AdminMastersPage extends ConsumerWidget {
  const AdminMastersPage({super.key, this.statusFilter});

  final AdminMasterStatus? statusFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminDataBuilder(
      builder: (context, data) {
    final query = ref.watch(adminUiProvider).searchQuery;
    final masters = filterMasters(
      data.masters,
      status: statusFilter == AdminMasterStatus.top ? AdminMasterStatus.top : statusFilter,
      query: query,
    );
    final title = switch (statusFilter) {
      AdminMasterStatus.pending => 'Мастера на модерации',
      AdminMasterStatus.top => 'Топ мастера',
      AdminMasterStatus.blocked => 'Заблокированные мастера',
      _ => 'Все мастера',
    };

    return _AdminPageScaffold(
      title: title,
      count: masters.length,
      child: _DataTable(
        columns: const ['Мастер', 'Специализация', 'Заказы', 'Рейтинг', 'Доход', 'Статус', 'Действия'],
        rows: masters.map((m) {
          return [
            Row(
              children: [
                _masterAvatar(m),
                const SizedBox(width: 8),
                Expanded(child: Text(m.name, style: _cellStyle(bold: true), overflow: TextOverflow.ellipsis)),
              ],
            ),
            Text(m.specialization, style: _cellStyle()),
            Text('${m.orders}', style: _cellStyle()),
            Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107)), Text(' ${m.rating}')]),
            Text('${formatMoney(m.income)} с.', style: _cellStyle(bold: true, color: AdminTheme.green)),
            AdminMasterBadge(status: m.status),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.status == AdminMasterStatus.pending)
                  _actionBtn('Одобрить', AdminTheme.green, () => adminApproveMaster(ref, m.id)),
                if (m.status != AdminMasterStatus.blocked)
                  _actionBtn('Блок', AdminTheme.red, () => adminBlockMaster(ref, m.id)),
              ],
            ),
          ];
        }).toList(),
      ),
    );
      },
    );
  }
}

// ─── Clients ──────────────────────────────────────────────────────────────────

class AdminClientsPage extends ConsumerWidget {
  const AdminClientsPage({super.key, this.vipOnly = false, this.newOnly = false});

  final bool vipOnly;
  final bool newOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminDataBuilder(
      builder: (context, data) {
    final query = ref.watch(adminUiProvider).searchQuery;
    final clients = filterClients(data.clients, vip: vipOnly ? true : null, isNew: newOnly ? true : null, query: query);
    final title = vipOnly ? 'VIP клиенты' : newOnly ? 'Новые клиенты' : 'Все клиенты';

    return _AdminPageScaffold(
      title: title,
      count: clients.length,
      child: _DataTable(
        columns: const ['Имя', 'Телефон', 'Заказы', 'Потрачено', 'Регистрация', 'Статус'],
        rows: clients.map((c) {
          return [
            Text(c.name, style: _cellStyle(bold: true)),
            Text(c.phone, style: _cellStyle(muted: true)),
            Text('${c.orders}', style: _cellStyle()),
            Text('${formatMoney(c.spent)} с.', style: _cellStyle(bold: true)),
            Text(c.joined, style: _cellStyle(muted: true)),
            c.isVip
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                    child: Text('VIP', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                  )
                : Text('Обычный', style: _cellStyle(muted: true)),
          ];
        }).toList(),
      ),
    );
      },
    );
  }
}

// ─── Chats ────────────────────────────────────────────────────────────────────

class AdminChatsPage extends ConsumerStatefulWidget {
  const AdminChatsPage({super.key});

  @override
  ConsumerState<AdminChatsPage> createState() => _AdminChatsPageState();
}

class _AdminChatsPageState extends ConsumerState<AdminChatsPage> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminDataBuilder(
      builder: (context, data) {
    if (data.chats.isEmpty) {
      return _AdminPageScaffold(title: 'Чаты', count: 0, child: AdminCard(child: Padding(padding: const EdgeInsets.all(24), child: Text('Чатов нет.', style: GoogleFonts.inter(color: AdminTheme.muted)))));
    }
    final selected = ref.watch(adminUiProvider).selectedChatId ?? data.chats.first.id;
    final chat = data.chats.firstWhere((c) => c.id == selected, orElse: () => data.chats.first);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Чаты', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...data.chats.map((c) {
                    final on = c.id == selected;
                    return InkWell(
                      onTap: () {
                        ref.read(adminUiProvider.notifier).selectChat(c.id);
                        adminMarkChatRead(ref, c.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: on ? AdminTheme.green.withValues(alpha: 0.08) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                                  Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(c.lastMessage, style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (c.unread > 0)
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: AdminTheme.green, shape: BoxShape.circle),
                                child: Text('${c.unread}', style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AdminCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Чат с ${chat.name}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        if (chat.messages.isEmpty) _bubble(chat.lastMessage, false),
                        ...chat.messages.map((m) => _bubble(m.text, m.isAdmin)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'Написать сообщение...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final t = _msgCtrl.text.trim();
                          if (t.isEmpty) return;
                          adminSendChatMessage(ref, chat.id, t);
                          _msgCtrl.clear();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                        child: const Icon(LucideIcons.send, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _bubble(String text, bool admin) {
    return Align(
      alignment: admin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: admin ? AdminTheme.green : AdminTheme.pageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: admin ? Colors.white : AdminTheme.text)),
      ),
    );
  }
}

// ─── Reviews ──────────────────────────────────────────────────────────────────

class AdminReviewsPage extends ConsumerWidget {
  const AdminReviewsPage({super.key, this.flaggedOnly = false, this.pendingOnly = false});

  final bool flaggedOnly;
  final bool pendingOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminDataBuilder(
      builder: (context, data) {
    final query = ref.watch(adminUiProvider).searchQuery;
    var reviews = filterReviews(data.reviews, flagged: flaggedOnly ? true : null, query: query);
    if (pendingOnly) reviews = reviews.where((r) => r.rating < 3).toList();
    final title = flaggedOnly ? 'Жалобы на отзывы' : pendingOnly ? 'Отзывы на модерации' : 'Все отзывы';

    return _AdminPageScaffold(
      title: title,
      count: reviews.length,
      child: _DataTable(
        columns: const ['Автор', 'Мастер', 'Оценка', 'Текст', 'Дата', 'Статус'],
        rows: reviews.map((r) {
          return [
            Text(r.author, style: _cellStyle(bold: true)),
            Text(r.master, style: _cellStyle()),
            Row(mainAxisSize: MainAxisSize.min, children: List.generate(r.rating, (_) => const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107)))),
            Expanded(child: Text(r.text, style: _cellStyle(), maxLines: 2, overflow: TextOverflow.ellipsis)),
            Text(r.date, style: _cellStyle(muted: true)),
            r.flagged
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)), child: Text('Жалоба', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.red)))
                : Text('Опубликован', style: _cellStyle(muted: true)),
          ];
        }).toList(),
      ),
    );
      },
    );
  }
}

// ─── Finance ──────────────────────────────────────────────────────────────────

class AdminFinancePage extends ConsumerWidget {
  const AdminFinancePage({super.key, this.section = 'transactions'});

  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminDataBuilder(
      builder: (context, data) {
    var txs = data.transactions;
    if (section == 'payouts') txs = txs.where((t) => t.type == 'Выплата').toList();
    if (section == 'commission') txs = txs.where((t) => t.type == 'Комиссия').toList();
    final title = switch (section) {
      'payouts' => 'Выплаты мастерам',
      'commission' => 'Комиссия платформы',
      _ => 'Транзакции',
    };

    return _AdminPageScaffold(
      title: title,
      count: txs.length,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final chartW = w > 800 ? (w - 12) / 2 : w;
              return Wrap(
                spacing: 12,
                children: [
                  SizedBox(width: chartW, child: AdminBarChartCard(title: 'Доход по месяцам', points: adminIncomeChart(data), height: 200)),
                  SizedBox(width: chartW, child: AdminLineChartCard(title: 'Комиссия', points: adminOrdersChart(data), color: AdminTheme.green, height: 200)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _DataTable(
            columns: const ['ID', 'Тип', 'Сумма', 'Сторона', 'Дата', 'Статус'],
            rows: txs.map((t) {
              return [
                Text(t.id, style: _cellStyle(bold: true)),
                Text(t.type, style: _cellStyle()),
                Text('${t.amount >= 0 ? '' : ''}${formatMoney(t.amount.abs())} с.', style: _cellStyle(bold: true, color: t.amount < 0 ? AdminTheme.red : AdminTheme.green)),
                Text(t.party, style: _cellStyle(muted: true)),
                Text(t.date, style: _cellStyle(muted: true)),
                Text(t.status, style: _cellStyle()),
              ];
            }).toList(),
          ),
        ],
      ),
    );
      },
    );
  }
}

// ─── Analytics ────────────────────────────────────────────────────────────────

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key, this.section = 'overview'});

  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = switch (section) {
      'services' => 'Аналитика по услугам',
      'districts' => 'Аналитика по районам',
      _ => 'Обзор аналитики',
    };

    return AdminDataBuilder(
      builder: (context, data) => _AdminPageScaffold(
      title: title,
      count: null,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final chartW = w > 900 ? (w - 12) / 2 : w;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: chartW, child: AdminLineChartCard(title: 'Заказы по дням', points: adminOrdersChart(data), color: AdminTheme.green, height: 220)),
              SizedBox(width: chartW, child: AdminBarChartCard(title: 'Доход (комиссия)', points: adminIncomeChart(data), height: 220)),
              SizedBox(width: chartW, child: AdminLineChartCard(title: 'Активность пользователей', points: adminOrdersChart(data), color: AdminTheme.purple, height: 220)),
              SizedBox(width: chartW, child: AdminLineChartCard(title: 'Активность мастеров', points: adminIncomeChart(data), color: AdminTheme.blue, height: 220)),
            ],
          );
        },
      ),
    ),
    );
  }
}

// ─── Settings ─────────────────────────────────────────────────────────────────

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key, this.section = 'general'});

  final String section;

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return AdminDataBuilder(
      builder: (context, data) {
    final s = data.settings;
    final store = ref.read(platformStoreProvider.notifier);
    final title = switch (widget.section) {
      'categories' => 'Категории услуг',
      'promos' => 'Промокоды',
      'notifications' => 'Уведомления',
      _ => 'Общие настройки',
    };

    return _AdminPageScaffold(
      title: title,
      count: null,
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.section == 'general' || widget.section == 'notifications') ...[
              _settingRow('Push-уведомления', Switch(value: s.pushNotifications, onChanged: (v) => store.updateSettings(SaPlatformSettings(maintenance: s.maintenance, registrations: s.registrations, commissionPercent: s.commissionPercent, pushNotifications: v, autoApproveMasters: s.autoApproveMasters)), activeThumbColor: AdminTheme.green)),
              _settingRow('Авто-одобрение мастеров', Switch(value: s.autoApproveMasters, onChanged: (v) => store.updateSettings(SaPlatformSettings(maintenance: s.maintenance, registrations: s.registrations, commissionPercent: s.commissionPercent, pushNotifications: s.pushNotifications, autoApproveMasters: v)), activeThumbColor: AdminTheme.green)),
              const SizedBox(height: 12),
              Text('Комиссия платформы: ${s.commissionPercent}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            if (widget.section == 'categories') ...[
              if (data.categories.isEmpty) const Text('Категорий нет'),
              for (final cat in data.categories)
                ListTile(
                  leading: const Icon(LucideIcons.wrench, size: 18, color: AdminTheme.green),
                  title: Text(cat.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text('${cat.productCount} товаров'),
                  trailing: Switch(value: cat.active, onChanged: (v) => store.updateCategory(cat.id, active: v), activeThumbColor: AdminTheme.green),
                ),
            ],
            if (widget.section == 'promos') ...[
              if (data.coupons.isEmpty) const Text('Промокодов нет'),
              for (final promo in data.coupons)
                ListTile(
                  title: Text(promo.code, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  subtitle: Text('${promo.description} · ${promo.discountPercent}%'),
                  trailing: Switch(value: promo.active, onChanged: (v) => store.updateCoupon(promo.id, active: v), activeThumbColor: AdminTheme.green),
                ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены'))),
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.green, foregroundColor: Colors.white),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _settingRow(String label, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
          trailing,
        ],
      ),
    );
  }
}

// ─── Support ──────────────────────────────────────────────────────────────────

class AdminSupportPage extends ConsumerWidget {
  const AdminSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminDataBuilder(
      builder: (context, data) {
    final tickets = data.supportTickets;
  final store = ref.read(platformStoreProvider.notifier);
    return _AdminPageScaffold(
      title: 'Поддержка',
      count: tickets.length,
      child: tickets.isEmpty
          ? AdminCard(child: Padding(padding: const EdgeInsets.all(24), child: Text('Обращений нет.', style: GoogleFonts.inter(color: AdminTheme.muted))))
          : AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Обращения пользователей', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            for (final ticket in tickets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(ticket.id, style: _cellStyle(bold: true)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(ticket.title, style: _cellStyle())),
                    Text(ticket.date, style: _cellStyle(muted: true)),
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      onSelected: (v) => store.updateTicketStatus(ticket.id, v),
                      itemBuilder: (_) => ['Открыт', 'В работе', 'Закрыт'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ticket.status == 'Открыт' ? const Color(0xFFFEE2E2) : ticket.status == 'В работе' ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(ticket.status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
      },
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _AdminPageScaffold extends StatelessWidget {
  const _AdminPageScaffold({required this.title, required this.child, this.count});

  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AdminTheme.text)),
              if (count != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AdminTheme.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text('$count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.green)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DataTable extends StatelessWidget {
  const _DataTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          Row(
            children: [
              for (final col in columns)
                Expanded(
                  flex: col == 'Действия' ? 2 : 3,
                  child: Text(col, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.muted)),
                ),
            ],
          ),
          const Divider(height: 24),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Нет данных', style: GoogleFonts.inter(color: AdminTheme.muted)),
            )
          else
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < row.length; i++)
                        Expanded(
                          flex: columns[i] == 'Действия' ? 2 : 3,
                          child: row[i],
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

TextStyle _cellStyle({bool bold = false, bool muted = false, Color? color}) {
  return GoogleFonts.inter(
    fontSize: 12.5,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    color: color ?? (muted ? AdminTheme.muted : AdminTheme.text),
  );
}

Widget _actionBtn(String label, Color color, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );
}

Widget _masterAvatar(AdminMaster master) {
  if (master.avatar.startsWith('assets/')) {
    return CircleAvatar(radius: 16, backgroundImage: AssetImage(master.avatar));
  }
  return CircleAvatar(
    radius: 16,
    backgroundColor: AdminTheme.green.withValues(alpha: 0.15),
    child: Text(
      master.avatar.isNotEmpty ? master.avatar : '?',
      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AdminTheme.green, fontSize: 12),
    ),
  );
}
