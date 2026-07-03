import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../chat/models/api_conversation.dart';
import '../../../chat/presentation/chat_thread_screen.dart';
import '../../../chat/providers/chat_provider.dart';
import 'master_cabinet_shell.dart';

class MasterChatsScreen extends ConsumerWidget {
  const MasterChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(conversationsProvider);

    return MasterCabinetShell(
      title: 'Сообщения',
      child: chats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(conversationsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _ChatTile(conversation: items[index]),
                ),
              ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.conversation});

  final ApiConversation conversation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8ECF1)),
      ),
      leading: CircleAvatar(
        backgroundColor: masterNavy.withValues(alpha: 0.1),
        child: const Icon(LucideIcons.message_circle, color: masterNavy),
      ),
      title: Text(
        conversation.title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Диалог по заказу'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadScreen(conversation: conversation),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: masterNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.message_circle, size: 40, color: masterNavy),
            ),
            const SizedBox(height: 20),
            Text(
              'Нет сообщений',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: masterNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
