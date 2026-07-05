import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/providers/auth_provider.dart';
import '../../chat/models/api_conversation.dart';
import '../../chat/presentation/chat_thread_screen.dart';
import '../../chat/models/chat_inbox_item.dart';
import '../../chat/providers/chat_provider.dart';
import '../../home/presentation/home_palette.dart';

class ChatsListPage extends ConsumerStatefulWidget {
  const ChatsListPage({super.key, required this.p});

  final HomePalette p;

  @override
  ConsumerState<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends ConsumerState<ChatsListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openItem(ChatInboxItem item) {
    if (item.canOpenChat) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadScreen(
            conversation: ApiConversation(
              id: item.conversationId!,
              title: item.peerName,
              type: 'Direct',
              participantUserIds: const [],
              orderId: item.orderId,
              isLocal: item.isLocal,
            ),
            isLocal: item.isLocal,
          ),
        ),
      );
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.isMaster) {
      context.push('/master/cabinet/active-orders');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Мастер ещё не принял заказ',
          style: GoogleFonts.inter(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(chatInboxProvider);
    final p = widget.p;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Поиск',
              hintStyle: GoogleFonts.inter(color: p.muted, fontSize: 15),
              prefixIcon: Icon(LucideIcons.search, color: p.muted, size: 20),
              filled: true,
              fillColor: p.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: p.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: inbox.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Чаты недоступны',
                style: GoogleFonts.inter(color: p.muted),
              ),
            ),
            data: (items) {
              final filtered = _query.isEmpty
                  ? items
                  : items
                      .where(
                        (i) =>
                            i.peerName.toLowerCase().contains(_query) ||
                            i.subtitle.toLowerCase().contains(_query),
                      )
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _query.isEmpty ? 'Чатов пока нет' : 'Ничего не найдено',
                    style: GoogleFonts.inter(color: p.muted),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return _ChatInboxTile(
                    item: item,
                    p: p,
                    onTap: () => _openItem(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatInboxTile extends StatelessWidget {
  const _ChatInboxTile({
    required this.item,
    required this.p,
    required this.onTap,
  });

  final ChatInboxItem item;
  final HomePalette p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              _Avatar(name: item.peerName, imageAsset: item.avatarAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.timeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.badgeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageAsset});

  final String name;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: AssetImage(imageAsset!),
      );
    }

    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFFE8ECF1),
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }
}
