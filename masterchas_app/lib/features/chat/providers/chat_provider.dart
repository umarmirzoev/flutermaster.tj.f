import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/jwt_user.dart';
import '../../../core/network/api_result.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/phone_formatter.dart';
import '../../masters/data/masters_data.dart';
import '../../orders/models/order_workflow_entry.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../data/chat_payload.dart';
import '../data/chat_repository.dart';
import '../models/api_conversation.dart';
import '../models/chat_inbox_item.dart';
import 'dart:convert';

MasterItem? masterByPhone(String? phone) {
  final digits = localDigitsFromPhone(phone);
  if (digits.isEmpty) return null;
  for (final master in masters) {
    if (localDigitsFromPhone(master.phone) == digits) return master;
  }
  return null;
}

String _formatTimeLabel(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _appointmentSubtitle(OrderWorkflowEntry entry) {
  if (entry.scheduledTime != null && entry.scheduledTime!.isNotEmpty) {
    final parts = entry.scheduledTime!.split(':');
    final hhmm =
        parts.length >= 2 ? '${parts[0]}:${parts[1]}' : entry.scheduledTime!;
    return 'Запись на $hhmm';
  }
  return entry.title;
}

({String label, Color color, Color bg}) _badgeFor(int status, bool isMaster) {
  return switch (status) {
    3 when !isMaster => (
        label: 'Ждёт мастера',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
      ),
    3 when isMaster => (
        label: 'Новая заявка',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
      ),
    4 || 5 => (
        label: 'В работе',
        color: const Color(0xFF16A34A),
        bg: const Color(0xFFECFDF3),
      ),
    6 => (
        label: 'Завершён',
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF3F4F6),
      ),
    7 => (
        label: 'Отменён',
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEE2E2),
      ),
    _ => (
        label: 'Заказ',
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF3F4F6),
      ),
  };
}

ChatInboxItem _inboxFromOrder(
  OrderWorkflowEntry entry,
  bool isMaster, {
  String? conversationId,
  bool isLocal = false,
}) {
  final badge = _badgeFor(entry.statusCode, isMaster);
  final master = masterByPhone(entry.masterPhone);
  final lastMessageTime = entry.updatedAt;
  final convId = conversationId ?? entry.conversationId;

  return ChatInboxItem(
    orderId: entry.orderId,
    conversationId: convId,
    peerName: isMaster ? entry.clientName : entry.masterName,
    subtitle: _appointmentSubtitle(entry),
    timeLabel: _formatTimeLabel(lastMessageTime),
    badgeLabel: badge.label,
    badgeColor: badge.color,
    badgeBgColor: badge.bg,
    sortTime: lastMessageTime,
    avatarAsset: isMaster ? null : master?.image,
    isLocal: isLocal,
  );
}

ChatInboxItem _inboxFromApiConversation(
  ApiConversation chat,
  bool isMaster,
  OrderWorkflowEntry? entry,
) {
  final badge = _badgeFor(entry?.statusCode ?? 4, isMaster);
  final sortTime = entry?.updatedAt ?? DateTime.now();
  return ChatInboxItem(
    orderId: entry?.orderId ?? chat.orderId ?? chat.id,
    conversationId: chat.id,
    peerName: chat.title,
    subtitle: entry?.title ?? 'Чат по заказу',
    timeLabel: _formatTimeLabel(sortTime),
    badgeLabel: badge.label,
    badgeColor: badge.color,
    badgeBgColor: badge.bg,
    sortTime: sortTime,
    isLocal: false,
  );
}

/// Удалённые (скрытые) чаты на этом устройстве: ключ чата → когда удалили.
/// Если после удаления придёт новое сообщение — чат появится снова.
final hiddenChatsProvider = NotifierProvider<HiddenChatsNotifier, Map<String, int>>(HiddenChatsNotifier.new);

class HiddenChatsNotifier extends Notifier<Map<String, int>> {
  static const _key = 'hidden_chats';

  @override
  Map<String, int> build() {
    ref.keepAlive();
    Future.microtask(_load);
    return const {};
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(secureStorageProvider).readSetting(_key);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {}
  }

  Future<void> hide(ChatInboxItem item) async {
    final key = chatHideKey(item);
    state = {...state, key: DateTime.now().millisecondsSinceEpoch};
    try {
      await ref.read(secureStorageProvider).writeSetting(_key, jsonEncode(state));
    } catch (_) {}
  }
}

String chatHideKey(ChatInboxItem item) => item.conversationId ?? 'order:${item.orderId}';

List<ChatInboxItem> _withoutHidden(List<ChatInboxItem> items, Map<String, int> hidden) {
  if (hidden.isEmpty) return items;
  return items.where((i) {
    final at = hidden[chatHideKey(i)];
    return at == null || i.sortTime.millisecondsSinceEpoch > at;
  }).toList();
}

final chatInboxProvider = FutureProvider<List<ChatInboxItem>>((ref) async {
  final hidden = ref.watch(hiddenChatsProvider);
  await ref.read(orderWorkflowProvider.notifier).ensureLoaded();
  ref.watch(orderWorkflowProvider);
  final auth = ref.watch(authProvider);
  final notifier = ref.read(orderWorkflowProvider.notifier);

  final apiResult = await ref.read(chatRepositoryProvider).getConversations();
  final apiChats = apiResult is ApiSuccess<List<ApiConversation>>
      ? apiResult.data
      : <ApiConversation>[];
  // Настоящая серверная сессия: показываем только серверные чаты —
  // они общие для клиента и мастера, сообщения доходят до собеседника.
  final hasServerSession =
      userIdFromJwt(await ref.read(secureStorageProvider).readToken()) != null;
  if (hasServerSession && apiResult is ApiSuccess<List<ApiConversation>>) {
    final serverItems = apiChats.map((chat) {
      final badge = _badgeFor(chat.orderStatus ?? 4, auth.isMaster);
      final sortTime = chat.lastMessageAt ?? DateTime.now();
      final last = chatPreviewText(chat.lastMessageType, chat.lastMessageText);
      return ChatInboxItem(
        orderId: chat.orderId ?? chat.id,
        conversationId: chat.id,
        peerName: chat.displayName,
        subtitle: last.isNotEmpty ? last : (chat.orderTitle ?? 'Чат по заказу'),
        timeLabel: _formatTimeLabel(sortTime),
        badgeLabel: badge.label,
        badgeColor: badge.color,
        badgeBgColor: badge.bg,
        sortTime: sortTime,
        isLocal: false,
        unreadCount: chat.unreadCount,
        peerPhone: chat.peerPhone,
      );
    }).toList()
      ..sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return _withoutHidden(serverItems, hidden);
  }

  ApiConversation? apiConvFor(String orderId) {
    for (final c in apiChats) {
      if (c.matchesOrder(orderId)) return c;
    }
    return null;
  }

  final orders = auth.isMaster
      ? notifier.ordersForMaster(auth.phone)
      : notifier.ordersForClient(auth.phone);

  final items = <ChatInboxItem>[];
  final seenConversations = <String>{};

  for (final entry in orders.where((o) => o.statusCode >= 3 && o.statusCode != 7)) {
    final apiConv = apiConvFor(entry.orderId);
    String? convId = apiConv?.id ?? entry.conversationId;
    var isLocal = convId?.startsWith('local-chat-') ?? false;

    if (convId == null && entry.statusCode >= 4) {
      convId = await notifier.ensureConversationForOrder(entry.orderId);
      isLocal = true;
    }

    if (convId != null) seenConversations.add(convId);

    items.add(_inboxFromOrder(
      entry,
      auth.isMaster,
      conversationId: convId,
      isLocal: apiConv == null && isLocal,
    ));
  }

  for (final apiConv in apiChats) {
    if (seenConversations.contains(apiConv.id)) continue;
    final entry = apiConv.orderId != null
        ? notifier.entryFor(apiConv.orderId!)
        : null;
    items.add(_inboxFromApiConversation(apiConv, auth.isMaster, entry));
  }

  items.sort((a, b) => b.sortTime.compareTo(a.sortTime));
  return _withoutHidden(items, hidden);
});

final conversationsProvider = FutureProvider<List<ApiConversation>>((ref) async {
  final result = await ref.read(chatRepositoryProvider).getConversations();
  final apiChats =
      result is ApiSuccess<List<ApiConversation>> ? result.data : <ApiConversation>[];

  final auth = ref.watch(authProvider);
  final hasServerSession =
      userIdFromJwt(await ref.read(secureStorageProvider).readToken()) != null;
  if (hasServerSession && result is ApiSuccess<List<ApiConversation>>) {
    return apiChats
        .map((c) => ApiConversation(
              id: c.id,
              title: c.displayName,
              type: c.type,
              participantUserIds: c.participantUserIds,
              orderId: c.orderId,
              peerName: c.peerName,
              peerPhone: c.peerPhone,
              orderTitle: c.orderTitle,
              orderStatus: c.orderStatus,
              lastMessageText: c.lastMessageText,
              lastMessageAt: c.lastMessageAt,
              lastMessageType: c.lastMessageType,
              unreadCount: c.unreadCount,
            ))
        .toList();
  }
  final local = ref.read(orderWorkflowProvider.notifier).conversationsForUser(
        phone: auth.phone,
        isMaster: auth.isMaster,
      );

  final merged = <ApiConversation>[...apiChats];
  for (final chat in local) {
    final orderEntry =
        ref.read(orderWorkflowProvider.notifier).entryFor(chat.orderId);
    final title = auth.isMaster
        ? chat.title
        : (chat.masterName ?? orderEntry?.masterName ?? chat.title);

    merged.add(ApiConversation(
      id: chat.id,
      title: title,
      type: 'Direct',
      participantUserIds: const [],
      orderId: chat.orderId,
      isLocal: true,
    ));
  }

  return merged;
});

/// Alias used by master orders screen after accept.
final mergedConversationsProvider = conversationsProvider;

final chatMessagesProvider =
    FutureProvider.family<List<ApiMessage>, String>((ref, conversationId) async {
  if (conversationId.startsWith('local-chat-')) {
    final chat = ref.watch(orderWorkflowProvider).conversations[conversationId];
    if (chat == null) return [];
    return chat.messages
        .map(
          (m) => ApiMessage(
            id: m.id,
            conversationId: conversationId,
            senderUserId: m.senderRole,
            text: m.text,
            createdAt: m.createdAt,
          ),
        )
        .toList();
  }

  final result = await ref.read(chatRepositoryProvider).getMessages(conversationId);
  if (result is! ApiSuccess<List<ApiMessage>>) return [];

  // Сервер присылает id отправителя; экран чата сравнивает с ролью ('master'/'client').
  final auth = ref.read(authProvider);
  final myRole = auth.isMaster ? 'master' : 'client';
  final peerRole = auth.isMaster ? 'client' : 'master';
  final myUserId = userIdFromJwt(await ref.read(secureStorageProvider).readToken());
  return result.data
      .map(
        (m) => ApiMessage(
          id: m.id,
          conversationId: m.conversationId,
          senderUserId: myUserId != null && m.senderUserId.toLowerCase() == myUserId
              ? myRole
              : peerRole,
          text: m.text,
          createdAt: m.createdAt?.toLocal(),
          messageType: m.messageType,
        ),
      )
      .toList();
});

/// Общее число непрочитанных сообщений — для значка на вкладке «Чаты».
/// Опрашивает сервер каждые 8 секунд, пока вкладка с приложением открыта.
final unreadChatsTotalProvider = StreamProvider<int>((ref) async* {
  final repo = ref.read(chatRepositoryProvider);
  final storage = ref.read(secureStorageProvider);
  while (true) {
    var total = 0;
    if (userIdFromJwt(await storage.readToken()) != null) {
      final result = await repo.getConversations();
      if (result is ApiSuccess<List<ApiConversation>>) {
        for (final c in result.data) {
          total += c.unreadCount;
        }
      }
    }
    yield total;
    await Future<void>.delayed(const Duration(seconds: 8));
  }
});
