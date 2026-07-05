import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/platform_store_provider.dart';
import '../../../core/network/api_result.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/admin_api_mapper.dart';
import '../../chat/providers/chat_provider.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../data/admin_data.dart';
import '../data/admin_repository.dart';
import '../../shop/providers/shop_admin_orders_provider.dart';
import '../models/admin_models.dart';

AdminOrderStatus workflowCodeToAdminStatus(int code) {
  return switch (code) {
    6 => AdminOrderStatus.completed,
    7 || 8 => AdminOrderStatus.cancelled,
    3 || 4 || 5 => AdminOrderStatus.inProgress,
    _ => AdminOrderStatus.newOrder,
  };
}

AdminOrderStatus effectiveAdminOrderStatus(WidgetRef ref, AdminOrder order) {
  final entry =
      ref.read(orderWorkflowProvider.notifier).entryFor(order.fullId);
  if (entry != null) return workflowCodeToAdminStatus(entry.statusCode);
  return order.status;
}

int adminStatusToWorkflowCode(AdminOrderStatus status) {
  return switch (status) {
    AdminOrderStatus.newOrder => 1,
    AdminOrderStatus.inProgress => 3,
    AdminOrderStatus.completed => 6,
    AdminOrderStatus.cancelled => 7,
  };
}

void _invalidateOrderViews(WidgetRef ref) {
  ref.invalidate(mergedClientOrdersProvider);
  ref.invalidate(mergedMasterOrdersProvider);
  ref.invalidate(chatInboxProvider);
}

class AdminUiState {
  const AdminUiState({
    this.sidebarCollapsed = false,
    this.searchQuery = '',
    this.expandedMenus = const {'orders', 'masters'},
    this.incomePeriod = 'Месяц',
    this.orderTab = 0,
    this.selectedChatId,
  });

  final bool sidebarCollapsed;
  final String searchQuery;
  final Set<String> expandedMenus;
  final String incomePeriod;
  final int orderTab;
  final String? selectedChatId;

  AdminUiState copyWith({
    bool? sidebarCollapsed,
    String? searchQuery,
    Set<String>? expandedMenus,
    String? incomePeriod,
    int? orderTab,
    String? selectedChatId,
  }) {
    return AdminUiState(
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedMenus: expandedMenus ?? this.expandedMenus,
      incomePeriod: incomePeriod ?? this.incomePeriod,
      orderTab: orderTab ?? this.orderTab,
      selectedChatId: selectedChatId ?? this.selectedChatId,
    );
  }
}

class AdminUiNotifier extends Notifier<AdminUiState> {
  @override
  AdminUiState build() => const AdminUiState();

  void toggleSidebar() => state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void toggleMenu(String id) {
    final next = Set<String>.from(state.expandedMenus);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(expandedMenus: next);
  }

  void setIncomePeriod(String p) => state = state.copyWith(incomePeriod: p);
  void setOrderTab(int i) => state = state.copyWith(orderTab: i);
  void selectChat(String? id) => state = state.copyWith(selectedChatId: id);
}

final adminUiProvider = NotifierProvider<AdminUiNotifier, AdminUiState>(AdminUiNotifier.new);

class AdminDataNotifier extends AsyncNotifier<AdminDataState> {
  @override
  Future<AdminDataState> build() async {
    ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (next.isInitialized &&
          next.isAuthenticated &&
          next.isAdmin &&
          (previous?.isAdmin != true || previous?.isAuthenticated != true)) {
        Future.microtask(() => refresh());
      }
    });

    var auth = ref.read(authProvider);
    if (!auth.isInitialized) {
      await ref.read(authProvider.notifier).initializeAuth();
      auth = ref.read(authProvider);
    }
    if (!auth.isAdmin) {
      return AdminDataState.empty();
    }
    return _load();
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (!auth.isAdmin) {
      state = AsyncData(AdminDataState.empty());
      return;
    }
    state = const AsyncLoading<AdminDataState>();
    state = AsyncData(await _load());
  }

  Future<AdminDataState> _load() async {
    final result = await ref.read(adminRepositoryProvider).fetchDashboardData();
    if (result is ApiSuccess<AdminDataState>) {
      final data = result.data;
      final shopOrders = await ref.read(shopAdminOrdersProvider.notifier).ensureLoaded();
      final mergedOrders = [...shopOrders, ...data.orders];
      final mergedData = AdminDataState(
        orders: mergedOrders,
        masters: data.masters,
        clients: data.clients,
        chats: data.chats,
        reviews: data.reviews,
        transactions: data.transactions,
        settings: data.settings,
        supportTickets: data.supportTickets,
        categories: data.categories,
        coupons: data.coupons,
        marketingLogs: data.marketingLogs,
      );
      ref.read(platformStoreProvider.notifier).syncApiCatalog(
            orders: adminOrdersToSa(mergedOrders),
            clients: adminClientsToSa(data.clients),
            masters: adminMastersToSa(data.masters),
          );
      return mergedData;
    }

    final auth = ref.read(authProvider);
    if (auth.isAdmin) {
      final shopOrders = await ref.read(shopAdminOrdersProvider.notifier).ensureLoaded();
      final seed = adminSeedDataState;
      return AdminDataState(
        orders: [...shopOrders, ...seed.orders],
        masters: seed.masters,
        clients: seed.clients,
        chats: seed.chats,
        reviews: seed.reviews,
        transactions: seed.transactions,
        settings: seed.settings,
        supportTickets: seed.supportTickets,
        categories: seed.categories,
        coupons: seed.coupons,
        marketingLogs: seed.marketingLogs,
      );
    }

    throw Exception(
      result is ApiError<AdminDataState> ? result.message : 'Ошибка загрузки',
    );
  }
}

final adminDataProvider =
    AsyncNotifierProvider<AdminDataNotifier, AdminDataState>(AdminDataNotifier.new);

void adminApproveMaster(WidgetRef ref, String id) {
  // TODO: POST verify master via API
}

void adminBlockMaster(WidgetRef ref, String id) {
  // TODO: POST block user via API
}

void adminApproveOrder(WidgetRef ref, AdminOrder order) async {
  await ref.read(orderWorkflowProvider.notifier).adminApproveOrder(
        order.fullId,
        masterName: order.master,
        masterPhone: order.masterPhone,
        clientName: order.client,
        title: order.service,
        address: order.address,
        price: order.amount > 0 ? order.amount : null,
      );
  _invalidateOrderViews(ref);
}

void adminUpdateOrderStatus(
  WidgetRef ref,
  AdminOrder order,
  AdminOrderStatus status,
) async {
  if (status == AdminOrderStatus.inProgress) {
    await ref.read(orderWorkflowProvider.notifier).adminApproveOrder(
          order.fullId,
          masterName: order.master,
          masterPhone: order.masterPhone,
          clientName: order.client,
          title: order.service,
          address: order.address,
          price: order.amount > 0 ? order.amount : null,
        );
  } else {
    await ref.read(orderWorkflowProvider.notifier).adminSetOrderStatus(
          order.fullId,
          adminStatusToWorkflowCode(status),
          masterName: order.master,
          masterPhone: order.masterPhone,
          clientName: order.client,
          title: order.service,
          address: order.address,
          price: order.amount > 0 ? order.amount : null,
        );
  }
  _invalidateOrderViews(ref);
}

void adminMarkChatRead(WidgetRef ref, String id) {}

void adminSendChatMessage(WidgetRef ref, String chatId, String text) {
  // TODO: POST chat message via API
}

List<AdminOrder> filterOrders(
  List<AdminOrder> orders, {
  AdminOrderStatus? status,
  String? query,
  AdminOrderStatus Function(AdminOrder order)? resolveStatus,
}) {
  return orders.where((o) {
    final effective = resolveStatus?.call(o) ?? o.status;
    if (status != null && effective != status) return false;
    if (query == null || query.isEmpty) return true;
    final q = query.toLowerCase();
    return o.id.toLowerCase().contains(q) ||
        o.client.toLowerCase().contains(q) ||
        o.master.toLowerCase().contains(q) ||
        o.service.toLowerCase().contains(q);
  }).toList();
}

List<AdminMaster> filterMasters(List<AdminMaster> masters, {AdminMasterStatus? status, String? query}) {
  return masters.where((m) {
    if (status != null && m.status != status) return false;
    if (query == null || query.isEmpty) return true;
    final q = query.toLowerCase();
    return m.name.toLowerCase().contains(q) ||
        m.specialization.toLowerCase().contains(q) ||
        m.phone.contains(q);
  }).toList();
}

List<AdminClient> filterClients(List<AdminClient> clients, {bool? vip, bool? isNew, String? query}) {
  return clients.where((c) {
    if (vip == true && !c.isVip) return false;
    if (isNew == true && c.orders > 1) return false;
    if (query == null || query.isEmpty) return true;
    final q = query.toLowerCase();
    return c.name.toLowerCase().contains(q) || c.phone.contains(q);
  }).toList();
}

List<AdminReview> filterReviews(List<AdminReview> reviews, {bool? flagged, String? query}) {
  return reviews.where((r) {
    if (flagged == true && !r.flagged) return false;
    if (query == null || query.isEmpty) return true;
    final q = query.toLowerCase();
    return r.author.toLowerCase().contains(q) ||
        r.master.toLowerCase().contains(q) ||
        r.text.toLowerCase().contains(q);
  }).toList();
}

List<Map<String, String>> globalAdminSearch(AdminDataState data, String query) {
  if (query.trim().isEmpty) return const [];
  final q = query.toLowerCase();
  final results = <Map<String, String>>[];
  for (final o in data.orders) {
    if (o.id.toLowerCase().contains(q) || o.client.toLowerCase().contains(q)) {
      results.add({'type': 'Заказ', 'label': '${o.id} — ${o.client}', 'route': '/admin/orders'});
    }
  }
  for (final m in data.masters) {
    if (m.name.toLowerCase().contains(q)) {
      results.add({'type': 'Мастер', 'label': m.name, 'route': '/admin/masters'});
    }
  }
  for (final c in data.clients) {
    if (c.name.toLowerCase().contains(q)) {
      results.add({'type': 'Клиент', 'label': c.name, 'route': '/admin/clients'});
    }
  }
  return results;
}

List<AdminChartPoint> adminOrdersChart(AdminDataState data) {
  if (data.orders.isEmpty) return const [AdminChartPoint(label: 'Нет', value: 0)];
  final buckets = <String, double>{};
  for (final o in data.orders) {
    buckets[o.date] = (buckets[o.date] ?? 0) + 1;
  }
  return buckets.entries
      .take(7)
      .map((e) => AdminChartPoint(
            label: e.key.length > 5 ? e.key.substring(0, 5) : e.key,
            value: e.value,
          ))
      .toList();
}

List<AdminChartPoint> adminIncomeChart(AdminDataState data) {
  final comm = data.transactions.where((t) => t.type == 'Комиссия');
  if (comm.isEmpty) return const [AdminChartPoint(label: 'Нет', value: 0)];
  return comm
      .take(6)
      .map((t) => AdminChartPoint(label: t.party.replaceAll('Заказ ', ''), value: t.amount.toDouble()))
      .toList();
}
