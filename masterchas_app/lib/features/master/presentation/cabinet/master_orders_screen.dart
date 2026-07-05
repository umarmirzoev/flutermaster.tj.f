import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../orders/models/api_order.dart';
import '../../../orders/providers/order_workflow_provider.dart';
import '../widgets/master_pending_order_card.dart';
import 'master_cabinet_shell.dart';

class MasterOrdersScreen extends ConsumerWidget {
  const MasterOrdersScreen({super.key, this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(mergedMasterOrdersProvider);
    final title = active ? 'Активные заказы' : 'Заказы';

    return MasterCabinetShell(
      title: title,
      child: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final pending =
              items.where((o) => o.statusCode == 3).toList();
          final activeOrders = items
              .where((o) => o.statusCode == 4 || o.statusCode == 5)
              .toList();
          final completed = items
              .where((o) => o.statusCode == 6)
              .toList();
          final declined =
              items.where((o) => o.statusCode == 7).toList();

          if (this.active) {
            if (pending.isEmpty && activeOrders.isEmpty) {
              return const _EmptyState(active: true);
            }
            return _OrdersList(
              sections: [
                if (pending.isNotEmpty)
                  _OrderSection(
                    title: 'Новые заявки',
                    orders: pending,
                  ),
                if (activeOrders.isNotEmpty)
                  _OrderSection(
                    title: 'В работе',
                    orders: activeOrders,
                  ),
              ],
            );
          }

          if (items.isEmpty) {
            return const _EmptyState(active: false);
          }

          return _OrdersList(
            sections: [
              if (pending.isNotEmpty)
                _OrderSection(
                  title: 'Ожидают ответа',
                  orders: pending,
                ),
              if (activeOrders.isNotEmpty)
                _OrderSection(title: 'Активные', orders: activeOrders),
              if (completed.isNotEmpty)
                _OrderSection(title: 'Выполненные', orders: completed),
              if (declined.isNotEmpty)
                _OrderSection(title: 'Отклонённые', orders: declined),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.sections});

  final List<_OrderSection> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mergedMasterOrdersProvider);
        ref.invalidate(orderWorkflowProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Text(
              sections[i].title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: masterNavy,
              ),
            ),
            const SizedBox(height: 10),
            ...sections[i].orders.map(
                  (o) => MasterPendingOrderCard(order: o),
                ),
          ],
        ],
      ),
    );
  }
}

class _OrderSection {
  const _OrderSection({
    required this.title,
    required this.orders,
  });

  final String title;
  final List<ApiOrder> orders;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? LucideIcons.calendar : LucideIcons.wrench,
              size: 48,
              color: masterNavy.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              active ? 'Нет активных заказов' : 'Пока нет заказов',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: masterNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
