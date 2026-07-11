import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_result.dart';
import '../../../core/realtime/signalr_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/chat_repository.dart';
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
  bool _peerTyping = false;

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
      ref.invalidate(chatInboxProvider);
      return;
    }

    try {
      await ref.read(signalRServiceProvider).sendChatMessage(
            conversationId: widget.conversation.id,
            text: text,
          );
    } catch (_) {
      final result = await ref.read(chatRepositoryProvider).sendMessage(
            conversationId: widget.conversation.id,
            text: text,
          );
      if (result is ApiError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }
    }
    ref.invalidate(chatMessagesProvider(widget.conversation.id));
    ref.invalidate(chatInboxProvider);
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
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FA),
          image: DecorationImage(
            image: const AssetImage('assets/images/master_1.png'),
            fit: BoxFit.cover,
            opacity: 0.015,
            onError: (_, __) {},
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length + (_peerTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_peerTyping && index == items.length) {
                      return const _TypingBubble();
                    }
                    final m = items[index];
                    if (m.senderUserId == 'system') {
                      return _SystemBanner(text: m.text);
                    }

                    final isMasterMsg = m.senderUserId == 'master';
                    final isMine = m.senderUserId == myRole;
                    final alignRight = isMine;

                    final bubbleColor = isMine
                        ? _brandGreen
                        : (isMasterMsg ? const Color(0xFFEAF6EB) : Colors.white);
                    final textColor = isMine
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
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(alignRight ? 18 : 4),
                            bottomRight: Radius.circular(alignRight ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(m.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isMine
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.check_check,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Quick reply chips
            _QuickReplies(onSelect: (text) {
              _controller.text = text;
              _send();
            }),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showAttachSheet,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4BAF50), Color(0xFF57B55E)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _brandGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Сообщение...',
                          hintStyle:
                              GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: Colors.white,
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: _brandGreen, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _brandGreen.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachOption(ctx, LucideIcons.image, 'Фото', const Color(0xFF8B5CF6)),
                  _attachOption(ctx, LucideIcons.camera, 'Камера', const Color(0xFF3B82F6)),
                  _attachOption(ctx, LucideIcons.map_pin, 'Гео', const Color(0xFFEF4444)),
                  _attachOption(ctx, LucideIcons.file_text, 'Файл', const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption(BuildContext ctx, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — скоро', style: GoogleFonts.inter()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator bubble ──
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_c.value + i / 3) % 1.0;
                final scale = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  child: Transform.translate(
                    offset: Offset(0, -4 * scale),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF).withValues(alpha: 0.5 + scale * 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ── Quick reply chips ──
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onSelect});

  final ValueChanged<String> onSelect;

  static const _replies = [
    'Когда придёте?',
    'Какая цена?',
    'Спасибо!',
    'Договорились',
    'Можно раньше?',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => onSelect(_replies[i]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _brandGreen.withValues(alpha: 0.25)),
              ),
              child: Text(
                _replies[i],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brandGreen,
                ),
              ),
            ),
          );
        },
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
