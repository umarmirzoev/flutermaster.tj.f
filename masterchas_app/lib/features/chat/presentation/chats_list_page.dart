import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../chat/presentation/chat_thread_screen.dart';
import '../../chat/providers/chat_provider.dart';
import '../../home/presentation/home_palette.dart';

class ChatsListPage extends ConsumerWidget {
  const ChatsListPage({super.key, required this.p});

  final HomePalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(conversationsProvider);

    return chatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('Чаты недоступны', style: GoogleFonts.inter(color: p.muted)),
      ),
      data: (chats) => chats.isEmpty
          ? Center(
              child: Text('Чатов пока нет', style: GoogleFonts.inter(color: p.muted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final chat = chats[i];
                return ListTile(
                  tileColor: p.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: p.border),
                  ),
                  leading: Icon(LucideIcons.message_circle, color: brandGreen),
                  title: Text(chat.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatThreadScreen(conversation: chat),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
