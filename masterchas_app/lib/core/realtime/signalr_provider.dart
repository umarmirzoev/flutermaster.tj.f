import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/signalr_service.dart';
import '../../features/orders/providers/orders_provider.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService();
  service.onOrderStatusChanged = (_, __) {
    ref.invalidate(clientOrdersProvider);
    ref.invalidate(masterAssignedOrdersProvider);
  };
  service.onOrderAssigned = (_) {
    ref.invalidate(masterAssignedOrdersProvider);
  };
  ref.onDispose(() => service.disconnect());
  return service;
});

Future<void> connectRealtime(WidgetRef ref) async {
  try {
    await ref.read(signalRServiceProvider).connect();
  } catch (_) {}
}
