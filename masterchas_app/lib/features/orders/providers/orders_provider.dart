import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/realtime/signalr_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/orders_repository.dart';
import '../models/api_order.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final clientOrdersProvider = FutureProvider<List<ApiOrder>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.isGuest) return [];

  final signalR = ref.read(signalRServiceProvider);
  signalR.onOrderStatusChanged = (_, __) {
    ref.invalidateSelf();
  };
  await signalR.connect();

  final result = await ref.read(ordersRepositoryProvider).getMyOrders();
  if (result is ApiSuccess<List<ApiOrder>>) return result.data;
  return [];
});

final masterAssignedOrdersProvider = FutureProvider<List<ApiOrder>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || !auth.isMaster) return [];

  final signalR = ref.read(signalRServiceProvider);
  signalR.onOrderAssigned = (_) => ref.invalidateSelf();
  signalR.onOrderStatusChanged = (_, __) => ref.invalidateSelf();
  await signalR.connect();

  final result = await ref.read(ordersRepositoryProvider).getAssignedOrders();
  if (result is ApiSuccess<List<ApiOrder>>) return result.data;
  return [];
});
