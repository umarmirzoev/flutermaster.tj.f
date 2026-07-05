import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/providers/order_workflow_provider.dart';

class ClientProfileStats {
  const ClientProfileStats({
    required this.ordersCount,
    required this.spent,
  });

  final int ordersCount;
  final int spent;
}

final clientProfileStatsProvider = Provider<ClientProfileStats>((ref) {
  final ordersAsync = ref.watch(mergedClientOrdersProvider);
  return ordersAsync.maybeWhen(
    data: (orders) {
      final active = orders.where((o) => !o.isCancelled).toList();
      final spent = active.fold<double>(
        0,
        (sum, o) => sum + (o.payableAmount ?? o.price),
      );
      return ClientProfileStats(
        ordersCount: active.length,
        spent: spent.round(),
      );
    },
    orElse: () => const ClientProfileStats(ordersCount: 0, spent: 0),
  );
});
