import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/catalog_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../shop/data/shop_data.dart';
import '../../shop/state/shop_state.dart';
import '../../orders/models/api_order.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../../orders/utils/order_status.dart';
import 'profile_shell.dart';

class ServiceOrdersPage extends ConsumerWidget {
  const ServiceOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = HomePalette.of(context);
    final ordersAsync = ref.watch(mergedClientOrdersProvider);
    final shopOrders = ref.watch(shopOrdersProvider);
    final catalog = ref.watch(shopCatalogProvider);

    return ProfileSubPage(
      title: 'Мои заказы',
      body: ordersAsync.when(
        loading: () => shopOrders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _ShopOrdersList(orders: shopOrders, catalog: catalog, p: p),
        error: (_, __) => shopOrders.isEmpty
            ? Center(
                child: Text('Не удалось загрузить заказы', style: GoogleFonts.inter(color: p.muted)),
              )
            : _ShopOrdersList(orders: shopOrders, catalog: catalog, p: p),
        data: (apiOrders) {
          if (apiOrders.isEmpty && shopOrders.isEmpty) {
            return Center(
              child: Text('Заказов пока нет', style: GoogleFonts.inter(color: p.muted)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (apiOrders.isNotEmpty) ...[
                Text('Услуги', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                const SizedBox(height: 10),
                ...apiOrders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrderCard(order: o, p: p),
                    )),
              ],
              if (shopOrders.isNotEmpty) ...[
                if (apiOrders.isNotEmpty) const SizedBox(height: 8),
                Text('Магазин', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                const SizedBox(height: 10),
                ...shopOrders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ShopOrderCard(order: o, catalog: catalog, p: p),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ShopOrdersList extends StatelessWidget {
  const _ShopOrdersList({required this.orders, required this.catalog, required this.p});

  final List<ShopOrder> orders;
  final List<ShopProduct> catalog;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ShopOrderCard(order: orders[i], catalog: catalog, p: p),
    );
  }
}

class _ShopOrderCard extends StatelessWidget {
  const _ShopOrderCard({required this.order, required this.catalog, required this.p});

  final ShopOrder order;
  final List<ShopProduct> catalog;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    final date =
        '${order.date.day.toString().padLeft(2, '0')}.${order.date.month.toString().padLeft(2, '0')}.${order.date.year}';
    final products = order.items.entries
        .where((e) => e.key >= 0 && e.key < catalog.length)
        .map((e) => catalog[e.key].ru)
        .join(', ');

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
                  products.isEmpty ? 'Заказ из магазина' : products,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(date, style: GoogleFonts.inter(fontSize: 12, color: p.muted)),
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
            '${shopMoney(order.total)} с.',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: brandGreen),
          ),
        ],
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
        status == 'Новый' ? 'Новый' : resolved.label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: resolved.color),
      ),
    );
  }
}
