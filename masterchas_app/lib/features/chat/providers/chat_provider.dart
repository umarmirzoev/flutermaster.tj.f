import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/phone_formatter.dart';
import '../../masters/data/masters_data.dart';
import '../../orders/models/order_workflow_entry.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../data/chat_repository.dart';
import '../models/api_conversation.dart';
import '../models/chat_inbox_item.dart';

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

ChatInboxItem _inboxFromOrder(OrderWorkflowEntry entry, bool isMaster) {
  final badge = _badgeFor(entry.statusCode, isMaster);
  final master = masterByPhone(entry.masterPhone);
  final lastMessageTime = entry.updatedAt;

  return ChatInboxItem(
    orderId: entry.orderId,
    conversationId: entry.conversationId,
    peerName: isMaster ? entry.clientName : entry.masterName,
    subtitle: _appointmentSubtitle(entry),
    timeLabel: _formatTimeLabel(lastMessageTime),
    badgeLabel: badge.label,
    badgeColor: badge.color,
    badgeBgColor: badge.bg,
    sortTime: lastMessageTime,
    avatarAsset: isMaster ? null : master?.image,
    isLocal: entry.conversationId != null,
  );
}

final chatInboxProvider = FutureProvider<List<ChatInboxItem>>((ref) async {
  await ref.read(orderWorkflowProvider.notifier).ensureLoaded();
  ref.watch(orderWorkflowProvider);
  final auth = ref.watch(authProvider);
  final notifier = ref.read(orderWorkflowProvider.notifier);

  final orders = auth.isMaster
      ? notifier.ordersForMaster(auth.phone)
      : notifier.ordersForClient(auth.phone);

  final items = orders
      .where((o) => o.statusCode >= 3 && o.statusCode != 7)
      .map((o) => _inboxFromOrder(o, auth.isMaster))
      .toList()
    ..sort((a, b) => b.sortTime.compareTo(a.sortTime));

  return items;
});

final conversationsProvider = FutureProvider<List<ApiConversation>>((ref) async {
  final result = await ref.read(chatRepositoryProvider).getConversations();
  final apiChats =
      result is ApiSuccess<List<ApiConversation>> ? result.data : <ApiConversation>[];

  final auth = ref.watch(authProvider);
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
  if (result is ApiSuccess<List<ApiMessage>>) return result.data;
  return [];
});
