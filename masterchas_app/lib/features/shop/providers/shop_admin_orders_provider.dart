import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/platform_store_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../admin/models/admin_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/shop_data.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

String _productLine(ShopProduct product, int qty) {
  if (qty <= 1) return product.ru;
  return '${product.ru} ×$qty';
}

final shopAdminOrdersProvider =
    NotifierProvider<ShopAdminOrdersNotifier, List<AdminOrder>>(ShopAdminOrdersNotifier.new);

class ShopAdminOrdersNotifier extends Notifier<List<AdminOrder>> {
  bool _loaded = false;

  @override
  List<AdminOrder> build() {
    ref.keepAlive();
    Future.microtask(_ensureLoaded);
    return const [];
  }

  Future<List<AdminOrder>> ensureLoaded() async {
    await _ensureLoaded();
    return state;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readShopAdminOrdersJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = jsonDecode(json) as List<dynamic>;
      state = list.map(_orderFromJson).toList();
    } catch (_) {}
  }

  Future<void> registerPurchase({
    required Map<int, int> items,
    required int total,
    required List<ShopProduct> catalog,
    String kind = 'Магазин',
  }) async {
    await _ensureLoaded();
    if (items.isEmpty || total <= 0) return;

    final auth = ref.read(authProvider);
    final client = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.phone?.trim().isNotEmpty == true ? auth.phone!.trim() : 'Клиент');

    final products = items.entries
        .where((e) => e.key >= 0 && e.key < catalog.length)
        .map((e) => _productLine(catalog[e.key], e.value))
        .join(', ');

    final id = DateTime.now().millisecondsSinceEpoch;
    final order = AdminOrder(
      id: '#SH-$id',
      fullId: 'shop-$id',
      client: client,
      master: '—',
      service: '$kind: $products',
      status: AdminOrderStatus.newOrder,
      date: _formatDate(DateTime.now()),
      amount: total,
    );

    state = [order, ...state];
    await ref.read(secureStorageProvider).writeShopAdminOrdersJson(
          jsonEncode(state.map(_orderToJson).toList()),
        );

    ref.read(platformStoreProvider.notifier).addOrder(
          client: client,
          master: '—',
          service: order.service,
          amount: total,
        );
  }

  static Map<String, dynamic> _orderToJson(AdminOrder o) => {
        'id': o.id,
        'fullId': o.fullId,
        'client': o.client,
        'master': o.master,
        'service': o.service,
        'status': o.status.index,
        'date': o.date,
        'amount': o.amount,
      };

  static AdminOrder _orderFromJson(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    final statusIndex = (json['status'] as num?)?.toInt() ?? 0;
    return AdminOrder(
      id: json['id'] as String? ?? '',
      fullId: json['fullId'] as String? ?? '',
      client: json['client'] as String? ?? 'Клиент',
      master: json['master'] as String? ?? '—',
      service: json['service'] as String? ?? 'Магазин',
      status: AdminOrderStatus.values[statusIndex.clamp(0, AdminOrderStatus.values.length - 1)],
      date: json['date'] as String? ?? _formatDate(DateTime.now()),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}
