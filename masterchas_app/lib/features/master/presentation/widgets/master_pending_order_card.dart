import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../chat/models/api_conversation.dart';
import '../../../chat/presentation/chat_thread_screen.dart';
import '../../../chat/providers/chat_provider.dart';
import '../../../orders/models/api_order.dart';
import '../../../orders/providers/order_workflow_provider.dart';
import '../../../orders/utils/order_status.dart';

/// Карточка заказа со статусом «ожидает ответа мастера» — принять или отклонить.
class MasterPendingOrderCard extends ConsumerWidget {
  const MasterPendingOrderCard({
    super.key,
    required this.order,
    this.compact = false,
  });

  final ApiOrder order;
  final bool compact;

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Отклонить заказ?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Причина отклонения',
            hintText: 'Например: занят в это время',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !context.mounted) return;

    await ref
        .read(orderWorkflowProvider.notifier)
        .masterDeclineOrder(order.id, reason);
    ref.invalidate(mergedMasterOrdersProvider);
    ref.invalidate(mergedClientOrdersProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заказ отклонён', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final chatId = await ref
        .read(orderWorkflowProvider.notifier)
        .masterAcceptOrder(order.id);
    ref.invalidate(mergedMasterOrdersProvider);
    ref.invalidate(mergedClientOrdersProvider);
    ref.invalidate(conversationsProvider);

    if (!context.mounted || chatId == null) return;

    final workflow = ref.read(orderWorkflowProvider);
    final localChat = workflow.conversations[chatId];
    if (localChat == null) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заказ принят', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadScreen(
          conversation: ApiConversation(
            id: localChat.id,
            title: localChat.title,
            type: 'Direct',
            participantUserIds: const [],
          ),
          isLocal: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(orderWorkflowProvider);
    final workflow = ref.watch(orderWorkflowProvider);
    final entry = ref.read(orderWorkflowProvider.notifier).entryFor(order.id);
    final statusCode = order.statusCode ?? 0;
    final status = resolveOrderStatus(statusCode.toString());
    final statusLabel = statusCode == 3 ? 'Ожидает вашего ответа' : status.label;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusCode == 3
              ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
              : const Color(0xFFE8ECF1),
          width: statusCode == 3 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 40 : 44,
                height: compact ? 40 : 44,
                decoration: BoxDecoration(
                  color: masterNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.isPendingMasterAccept
                      ? LucideIcons.bell
                      : LucideIcons.wrench,
                  color: masterNavy,
                  size: compact ? 20 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: masterNavy,
                      ),
                    ),
                    if (order.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        order.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    if (entry != null && entry.clientName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Клиент: ${entry.clientName}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${order.price.toStringAsFixed(0)} с.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: masterNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (statusCode == 3 ? Colors.orange : status.color)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusCode == 3 ? Colors.orange.shade800 : status.color,
              ),
            ),
          ),
          if (order.isPendingMasterAccept) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    child: const Text('Отклонить'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(context, ref),
                    style: FilledButton.styleFrom(backgroundColor: masterNavy),
                    child: const Text('Принять'),
                  ),
                ),
              ],
            ),
          ],
          if (order.isMasterAccepted && entry?.conversationId != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                final localChat =
                    workflow.conversations[entry!.conversationId!];
                if (localChat == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatThreadScreen(
                      conversation: ApiConversation(
                        id: localChat.id,
                        title: localChat.title,
                        type: 'Direct',
                        participantUserIds: const [],
                      ),
                      isLocal: true,
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.message_circle, size: 16),
              label: const Text('Открыть чат'),
              style: TextButton.styleFrom(foregroundColor: masterNavy),
            ),
          ],
        ],
      ),
    );
  }
}
