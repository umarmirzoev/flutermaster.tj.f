import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/phone_formatter.dart';
import '../models/api_order.dart';
import '../models/order_workflow_entry.dart';
import 'orders_provider.dart';

const chatSystemOpenMessage = 'Мастер принял заказ. Чат открыт.';

const _ruMonths = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

String formatVisitSchedule(DateTime? date, String? time) {
  if (date == null) return '';
  final dayMonth = '${date.day} ${_ruMonths[date.month - 1]}';
  if (time == null || time.isEmpty) return dayMonth;
  final parts = time.split(':');
  final hhmm = parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  return '$dayMonth к $hhmm';
}

String buildMasterAcceptMessage(OrderWorkflowEntry entry) {
  final service = entry.title.trim().isEmpty ? 'ваш заказ' : entry.title;
  final visit = formatVisitSchedule(entry.scheduledDate, entry.scheduledTime);
  if (visit.isNotEmpty) {
    return 'Здравствуйте! Я принял ваш заказ «$service». Буду на месте $visit.';
  }
  return 'Здравствуйте! Я принял ваш заказ «$service».';
}

String normalizePhoneDigits(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  return localDigitsFromPhone(raw);
}

bool phonesMatch(String? a, String? b) {
  return normalizePhoneDigits(a) == normalizePhoneDigits(b) &&
      normalizePhoneDigits(a).length >= 9;
}

final orderWorkflowProvider =
    NotifierProvider<OrderWorkflowNotifier, OrderWorkflowState>(
  OrderWorkflowNotifier.new,
);

class OrderWorkflowNotifier extends Notifier<OrderWorkflowState> {
  bool _loaded = false;

  @override
  OrderWorkflowState build() {
    ref.keepAlive();
    return const OrderWorkflowState();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await _load();
  }

  Future<void> _load() async {
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readOrderWorkflowJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      state = OrderWorkflowState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {}
  }

  Future<void> ensureLoaded() => _ensureLoaded();

  Future<void> _persist() async {
    await ref.read(secureStorageProvider).writeOrderWorkflowJson(
          jsonEncode(state.toJson()),
        );
  }

  OrderWorkflowEntry? entryFor(String orderId) => _findEntry(orderId);

  ApiOrder applyWorkflow(ApiOrder order) {
    final entry = _findEntry(order.id);
    if (entry == null) return order;
    return order.copyWith(
      status: entry.statusCode.toString(),
      statusCode: entry.statusCode,
    );
  }

  OrderWorkflowEntry? _findEntry(String orderId) {
    final direct = state.orders[orderId];
    if (direct != null) return direct;

    final normalized = orderId.trim().toLowerCase();
    for (final entry in state.orders.values) {
      final id = entry.orderId.toLowerCase();
      if (id == normalized ||
          id.startsWith(normalized) ||
          normalized.startsWith(id)) {
        return entry;
      }
    }
    return null;
  }

  String? _resolveOrderKey(String orderId) {
    if (state.orders.containsKey(orderId)) return orderId;
    final entry = _findEntry(orderId);
    return entry?.orderId;
  }

  Future<void> registerOrder({
    required ApiOrder order,
    required String clientName,
    required String clientPhone,
    required String masterName,
    required String masterPhone,
    DateTime? scheduledDate,
    String? scheduledTime,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now();
    final entry = OrderWorkflowEntry(
      orderId: order.id,
      title: order.title,
      description: order.description,
      address: order.address,
      price: order.price,
      clientName: clientName,
      clientPhone: clientPhone,
      masterName: masterName,
      masterPhone: masterPhone,
      statusCode: order.statusCode ?? 1,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      createdAt: now,
      updatedAt: now,
    );

    final next = Map<String, OrderWorkflowEntry>.from(state.orders);
    next[order.id] = entry;
    state = state.copyWith(orders: next);
    await _persist();
  }

  Future<void> adminApproveOrder(
    String orderId, {
    String? masterName,
    String? masterPhone,
    String? clientName,
    String? clientPhone,
    String? title,
    String? address,
    int? price,
  }) async {
    await _ensureLoaded();

    final key = _resolveOrderKey(orderId);
    if (key != null) {
      final entry = state.orders[key]!;
      final next = Map<String, OrderWorkflowEntry>.from(state.orders);
      next[key] = entry.copyWith(
        statusCode: 3,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(orders: next);
      await _persist();
      return;
    }

    if (masterPhone == null || masterPhone.trim().isEmpty) return;

    final now = DateTime.now();
    final entry = OrderWorkflowEntry(
      orderId: orderId,
      title: title ?? 'Заказ',
      description: '',
      address: address ?? '',
      price: (price ?? 0).toDouble(),
      clientName: clientName ?? 'Клиент',
      clientPhone: clientPhone ?? '',
      masterName: masterName ?? 'Мастер',
      masterPhone: masterPhone,
      statusCode: 3,
      createdAt: now,
      updatedAt: now,
    );

    final next = Map<String, OrderWorkflowEntry>.from(state.orders);
    next[orderId] = entry;
    state = state.copyWith(orders: next);
    await _persist();
  }

  Future<void> adminSetOrderStatus(
    String orderId,
    int statusCode, {
    String? masterName,
    String? masterPhone,
    String? clientName,
    String? clientPhone,
    String? title,
    String? address,
    int? price,
  }) async {
    await _ensureLoaded();

    final key = _resolveOrderKey(orderId);
    if (key != null) {
      final entry = state.orders[key]!;
      final next = Map<String, OrderWorkflowEntry>.from(state.orders);
      next[key] = entry.copyWith(
        statusCode: statusCode,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(orders: next);
      await _persist();
      return;
    }

    if (masterPhone == null || masterPhone.trim().isEmpty) return;

    final now = DateTime.now();
    final entry = OrderWorkflowEntry(
      orderId: orderId,
      title: title ?? 'Заказ',
      description: '',
      address: address ?? '',
      price: (price ?? 0).toDouble(),
      clientName: clientName ?? 'Клиент',
      clientPhone: clientPhone ?? '',
      masterName: masterName ?? 'Мастер',
      masterPhone: masterPhone,
      statusCode: statusCode,
      createdAt: now,
      updatedAt: now,
    );

    final next = Map<String, OrderWorkflowEntry>.from(state.orders);
    next[orderId] = entry;
    state = state.copyWith(orders: next);
    await _persist();
  }

  Future<String?> masterAcceptOrder(String orderId) async {
    await _ensureLoaded();
    final key = _resolveOrderKey(orderId);
    if (key == null) return null;
    final entry = state.orders[key]!;

    final chatId = 'local-chat-$key';
    final now = DateTime.now();
    final conversation = LocalConversation(
      id: chatId,
      orderId: key,
      title: entry.clientName,
      clientPhone: entry.clientPhone,
      masterPhone: entry.masterPhone,
      masterName: entry.masterName,
      messages: [
        LocalChatMessage(
          id: 'msg-$key-system',
          senderRole: 'system',
          text: chatSystemOpenMessage,
          createdAt: now,
        ),
        LocalChatMessage(
          id: 'msg-$key-accept',
          senderRole: 'master',
          text: buildMasterAcceptMessage(entry),
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      ],
    );

    final nextOrders = Map<String, OrderWorkflowEntry>.from(state.orders);
    nextOrders[key] = entry.copyWith(
      statusCode: 4,
      conversationId: chatId,
      updatedAt: DateTime.now(),
    );

    final nextChats = Map<String, LocalConversation>.from(state.conversations);
    nextChats[chatId] = conversation;

    state = state.copyWith(orders: nextOrders, conversations: nextChats);
    await _persist();
    return chatId;
  }

  /// Создаёт локальный чат для заказа в работе, если его ещё нет.
  Future<String?> ensureConversationForOrder(String orderId) async {
    await _ensureLoaded();
    final key = _resolveOrderKey(orderId);
    if (key == null) return null;
    final entry = state.orders[key]!;
    if (entry.conversationId != null) return entry.conversationId;
    if (entry.statusCode < 4 || entry.statusCode == 7) return null;

    final chatId = 'local-chat-$key';
    final now = DateTime.now();
    final conversation = LocalConversation(
      id: chatId,
      orderId: key,
      title: entry.clientName,
      clientPhone: entry.clientPhone,
      masterPhone: entry.masterPhone,
      masterName: entry.masterName,
      messages: [
        LocalChatMessage(
          id: 'msg-$key-system',
          senderRole: 'system',
          text: chatSystemOpenMessage,
          createdAt: now,
        ),
      ],
    );

    final nextOrders = Map<String, OrderWorkflowEntry>.from(state.orders);
    nextOrders[key] = entry.copyWith(
      conversationId: chatId,
      updatedAt: DateTime.now(),
    );

    final nextChats = Map<String, LocalConversation>.from(state.conversations);
    nextChats[chatId] = conversation;

    state = state.copyWith(orders: nextOrders, conversations: nextChats);
    await _persist();
    return chatId;
  }

  Future<void> masterDeclineOrder(String orderId, String reason) async {
    await _ensureLoaded();
    final key = _resolveOrderKey(orderId);
    if (key == null) return;
    final entry = state.orders[key]!;

    final next = Map<String, OrderWorkflowEntry>.from(state.orders);
    next[key] = entry.copyWith(
      statusCode: 7,
      declineReason: reason.trim(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(orders: next);
    await _persist();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderRole,
    required String text,
  }) async {
    final chat = state.conversations[conversationId];
    if (chat == null || text.trim().isEmpty) return;

    final message = LocalChatMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      senderRole: senderRole,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    final nextChats = Map<String, LocalConversation>.from(state.conversations);
    nextChats[conversationId] = chat.copyWith(
      messages: [...chat.messages, message],
    );
    state = state.copyWith(conversations: nextChats);
    await _persist();
  }

  List<OrderWorkflowEntry> ordersForMaster(String? phone) {
    final digits = normalizePhoneDigits(phone);
    if (digits.isEmpty) return [];
    return state.orders.values
        .where((o) => normalizePhoneDigits(o.masterPhone) == digits)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<OrderWorkflowEntry> ordersForClient(String? phone) {
    final digits = normalizePhoneDigits(phone);
    if (digits.isEmpty) return [];
    return state.orders.values
        .where((o) => normalizePhoneDigits(o.clientPhone) == digits)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<LocalConversation> conversationsForUser({
    required String? phone,
    required bool isMaster,
  }) {
    final digits = normalizePhoneDigits(phone);
    if (digits.isEmpty) return [];

    return state.conversations.values.where((c) {
      final target = isMaster ? c.masterPhone : c.clientPhone;
      return normalizePhoneDigits(target) == digits;
    }).toList()
      ..sort((a, b) {
        final aTime = a.messages.isNotEmpty
            ? a.messages.last.createdAt
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.messages.isNotEmpty
            ? b.messages.last.createdAt
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  int workflowStatusForAdmin(String orderId, int fallbackCode) {
    return state.orders[orderId]?.statusCode ?? fallbackCode;
  }
}

/// Merged client orders: API + workflow status overlay.
final mergedClientOrdersProvider = FutureProvider<List<ApiOrder>>((ref) async {
  await ref.read(orderWorkflowProvider.notifier).ensureLoaded();
  final apiOrders = await ref.watch(clientOrdersProvider.future);
  final workflow = ref.watch(orderWorkflowProvider);
  final notifier = ref.read(orderWorkflowProvider.notifier);

  final merged = <ApiOrder>[];
  final seen = <String>{};

  for (final order in apiOrders) {
    merged.add(notifier.applyWorkflow(order));
    seen.add(order.id);
  }

  final auth = ref.watch(authProvider);
  for (final entry in workflow.orders.values) {
    if (seen.contains(entry.orderId)) continue;
    if (!phonesMatch(entry.clientPhone, auth.phone)) continue;
    merged.add(_orderFromEntry(entry));
  }

  merged.sort((a, b) => b.id.compareTo(a.id));
  return merged;
});

/// Merged master orders.
final mergedMasterOrdersProvider = FutureProvider<List<ApiOrder>>((ref) async {
  await ref.read(orderWorkflowProvider.notifier).ensureLoaded();
  final apiOrders = await ref.watch(masterAssignedOrdersProvider.future);
  final workflow = ref.watch(orderWorkflowProvider);
  final notifier = ref.read(orderWorkflowProvider.notifier);
  final auth = ref.watch(authProvider);

  final merged = <ApiOrder>[];
  final seen = <String>{};

  for (final order in apiOrders) {
    merged.add(notifier.applyWorkflow(order));
    seen.add(order.id);
  }

  for (final entry in workflow.orders.values) {
    if (seen.contains(entry.orderId)) continue;
    if (!phonesMatch(entry.masterPhone, auth.phone)) continue;
    if (entry.statusCode < 3) continue;
    merged.add(_orderFromEntry(entry));
  }

  merged.sort((a, b) => (b.statusCode ?? 0).compareTo(a.statusCode ?? 0));
  return merged;
});

ApiOrder _orderFromEntry(OrderWorkflowEntry entry) {
  return ApiOrder(
    id: entry.orderId,
    title: entry.title,
    description: entry.description,
    address: entry.address,
    status: entry.statusCode.toString(),
    statusCode: entry.statusCode,
    price: entry.price,
  );
}
