import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../orders/models/api_order.dart';
import '../../../orders/providers/orders_provider.dart';
import 'master_cabinet_shell.dart';

class MasterOrdersScreen extends ConsumerWidget {
  const MasterOrdersScreen({super.key, this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(masterAssignedOrdersProvider);
    final title = active ? 'Активные заказы' : 'Выполненные заказы';

    return MasterCabinetShell(
      title: title,
      child: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final filtered = active
              ? items.where((o) => o.isActive).toList()
              : items.where((o) => o.status.toLowerCase().contains('completed')).toList();

          if (filtered.isEmpty) {
            return _EmptyState(active: active);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(masterAssignedOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _OrderTile(order: filtered[index]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final ApiOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: masterNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              order.isActive ? LucideIcons.clock : LucideIcons.circle_check,
              color: masterNavy,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: masterNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${order.price.toStringAsFixed(0)} с.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: masterNavy,
            ),
          ),
        ],
      ),
    );
  }
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
              active ? 'Нет активных заказов' : 'Пока нет выполненных заказов',
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
