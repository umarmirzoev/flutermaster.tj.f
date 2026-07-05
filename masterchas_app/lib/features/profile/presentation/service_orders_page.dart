import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/presentation/home_palette.dart';
import '../../orders/models/api_order.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../orders/utils/order_status.dart';
import 'profile_shell.dart';

class ServiceOrdersPage extends ConsumerWidget {
  const ServiceOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final ordersAsync = ref.watch(mergedClientOrdersProvider);

    return ProfileSubPage(
      title: 'Мои заказы',
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('Не удалось загрузить заказы', style: GoogleFonts.inter(color: p.muted)),
        ),
        data: (orders) => orders.isEmpty
            ? Center(
                child: Text('Заказов пока нет', style: GoogleFonts.inter(color: p.muted)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _OrderCard(order: orders[i], p: p),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.p});

  final ApiOrder order;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.title,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
              _StatusChip(status: order.statusCode?.toString() ?? order.status),
            ],
          ),
          if (order.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.map_pin, size: 14, color: brandGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order.address, style: GoogleFonts.inter(fontSize: 12, color: p.muted)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${order.payableAmount?.toStringAsFixed(0) ?? order.price.toStringAsFixed(0)} с.',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: brandGreen),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveOrderStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: resolved.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        resolved.label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: resolved.color),
      ),
    );
  }
}
