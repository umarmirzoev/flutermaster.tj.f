import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/realtime/signalr_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/phone_formatter.dart';
import '../../masters/data/masters_data.dart';
import '../../orders/models/order_workflow_entry.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../models/api_conversation.dart';
import '../providers/chat_provider.dart';

const _brandGreen = Color(0xFF57B55E);

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversation,
    this.isLocal = false,
  });

  final ApiConversation conversation;
  final bool isLocal;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();

  bool get _isLocal =>
      widget.isLocal || widget.conversation.id.startsWith('local-chat-');

  @override
  void initState() {
    super.initState();
    if (!_isLocal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setupHub());
    }
  }

  Future<void> _setupHub() async {
    final signalR = ref.read(signalRServiceProvider);
    signalR.onChatMessage = (payload) {
      if (payload['conversationId']?.toString() == widget.conversation.id) {
        ref.invalidate(chatMessagesProvider(widget.conversation.id));
      }
    };
    await signalR.joinConversation(widget.conversation.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _senderRole {
    final auth = ref.read(authProvider);
    return auth.isMaster ? 'master' : 'client';
  }

  OrderWorkflowEntry? get _orderEntry {
    final orderId = widget.conversation.orderId;
    if (orderId == null || orderId.isEmpty) return null;
    return ref.read(orderWorkflowProvider.notifier).entryFor(orderId);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    if (_isLocal) {
      await ref.read(orderWorkflowProvider.notifier).sendMessage(
            conversationId: widget.conversation.id,
            senderRole: _senderRole,
            text: text,
          );
      ref.invalidate(chatMessagesProvider(widget.conversation.id));
      ref.invalidate(conversationsProvider);
      return;
    }

    await ref.read(signalRServiceProvider).sendChatMessage(
          conversationId: widget.conversation.id,
          text: text,
        );
    ref.invalidate(chatMessagesProvider(widget.conversation.id));
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _peerAvatar(String name, {String? imageAsset}) {
    if (imageAsset != null && imageAsset.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage(imageAsset),
      );
    }
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE8ECF1),
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  MasterItem? _masterFromEntry(OrderWorkflowEntry? entry) {
    if (entry == null) return null;
    final digits = localDigitsFromPhone(entry.masterPhone);
    for (final master in masters) {
      if (localDigitsFromPhone(master.phone) == digits) return master;
      if (master.fullName == entry.masterName) return master;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(orderWorkflowProvider);
    final messages = ref.watch(chatMessagesProvider(widget.conversation.id));
    final auth = ref.watch(authProvider);
    final myRole = _senderRole;
    final entry = _orderEntry;
    final masterCatalog = _masterFromEntry(entry);

    final peerName = auth.isMaster
        ? (entry?.clientName ?? widget.conversation.title)
        : (entry?.masterName ?? widget.conversation.title);
    final serviceLine = entry != null
        ? '${entry.title} · ${entry.price.toStringAsFixed(0)} с.'
        : null;
    final statusLabel = switch (entry?.statusCode) {
      4 || 5 => 'В работе',
      6 => 'Завершён',
      7 => 'Отменён',
      _ => 'В работе',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            _peerAvatar(
              peerName,
              imageAsset: auth.isMaster ? null : masterCatalog?.image,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (serviceLine != null)
                    Text(
                      serviceLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              statusLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: statusLabel == 'Отменён'
                    ? const Color(0xFFDC2626)
                    : _brandGreen,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.phone, color: _brandGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final m = items[index];
                  if (m.senderUserId == 'system') {
                    return _SystemBanner(text: m.text);
                  }

                  final isMasterMsg = m.senderUserId == 'master';
                  final isMine = m.senderUserId == myRole;
                  final alignRight = isMine;

                  final bubbleColor = isMasterMsg
                      ? _brandGreen
                      : const Color(0xFFF3F4F6);
                  final textColor = isMasterMsg
                      ? Colors.white
                      : const Color(0xFF111827);

                  return Align(
                    alignment: alignRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(alignRight ? 18 : 6),
                          bottomRight: Radius.circular(alignRight ? 6 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.text,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(m.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isMasterMsg
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(LucideIcons.plus, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        hintStyle:
                            GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _brandGreen,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _send,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          LucideIcons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemBanner extends StatelessWidget {
  const _SystemBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
