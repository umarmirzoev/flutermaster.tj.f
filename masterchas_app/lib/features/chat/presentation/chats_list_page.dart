import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../../chat/models/api_conversation.dart';
import '../../chat/presentation/chat_thread_screen.dart';
import '../../chat/models/chat_inbox_item.dart';
import '../../chat/providers/chat_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fancy_confirm.dart';
import '../data/chat_repository.dart';

class ChatsListPage extends ConsumerStatefulWidget {
  const ChatsListPage({super.key, required this.p});

  final HomePalette p;

  @override
  ConsumerState<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends ConsumerState<ChatsListPage> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _refreshTimer;
  bool _unreadOnly = false;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    // Новые сообщения и счётчики непрочитанных подтягиваются сами.
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) ref.invalidate(chatInboxProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openItem(ChatInboxItem item) async {
    if (item.canOpenChat) {
      _pushChat(item);
      return;
    }

    if (item.conversationId == null) {
      final chatId = await ref
          .read(orderWorkflowProvider.notifier)
          .ensureConversationForOrder(item.orderId);
      if (!mounted) return;
      if (chatId != null) {
        ref.invalidate(chatInboxProvider);
        _pushChat(item.copyWith(conversationId: chatId, isLocal: true));
        return;
      }
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
          style: GoogleFonts.manrope(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _pushChat(ChatInboxItem item) {
    Navigator.of(context)
        .push(
      SmoothRoute<void>(
        builder: (_) => ChatThreadScreen(
          conversation: ApiConversation(
            id: item.conversationId!,
            title: item.peerName,
            type: 'Direct',
            participantUserIds: const [],
            orderId: item.orderId,
            isLocal: item.isLocal,
            peerName: item.peerName,
            peerPhone: item.peerPhone,
          ),
          isLocal: item.isLocal,
        ),
      ),
    )
        .then((_) {
      if (!mounted) return;
      ref.invalidate(chatInboxProvider);
      ref.invalidate(unreadChatsTotalProvider);
    });
  }

  Future<bool> _confirmDelete(ChatInboxItem item) {
    return showFancyConfirm(
      context,
      icon: LucideIcons.trash_2,
      color: const Color(0xFFEF4444),
      title: 'Удалить чат?',
      message: 'Переписка с «${item.peerName}» пропадёт из вашего списка. '
          'У собеседника она останется. Если он напишет снова — чат вернётся.',
      confirmLabel: 'Удалить',
      cancelLabel: 'Отмена',
    );
  }

  Future<void> _deleteChat(ChatInboxItem item) async {
    await ref.read(hiddenChatsProvider.notifier).hide(item);
    final id = item.conversationId;
    if (id != null && !item.isLocal) {
      await ref.read(chatRepositoryProvider).hideConversation(id);
    }
    if (!mounted) return;
    ref.invalidate(chatInboxProvider);
    ref.invalidate(unreadChatsTotalProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111827),
          content: Row(
            children: [
              const Icon(LucideIcons.trash_2, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Чат с «${item.peerName}» удалён',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showChatMenu(ChatInboxItem item) {
    final p = widget.p;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget action(IconData icon, String label, Color color, VoidCallback onTap, int i) => Reveal(
              delay: Duration(milliseconds: 40 + 60 * i),
              offsetY: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: color, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Text(label, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
                      ],
                    ),
                  ),
                ),
              ),
            );
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: p.pageBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text(item.peerName, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
                const SizedBox(height: 8),
                action(LucideIcons.message_circle, 'Открыть чат', const Color(0xFF57B55E), () => _openItem(item), 0),
                action(LucideIcons.trash_2, 'Удалить чат', const Color(0xFFEF4444), () async {
                  if (await _confirmDelete(item)) await _deleteChat(item);
                }, 1),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(chatInboxProvider);
    ref.invalidate(unreadChatsTotalProvider);
    try {
      await ref.read(chatInboxProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(chatInboxProvider);
    final p = widget.p;
    const green = Color(0xFF57B55E);

    return Column(
      children: [
        Reveal(
          offsetY: 14,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Focus(
              onFocusChange: (f) => setState(() => _searchFocused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: green.withValues(alpha: _searchFocused ? 0.22 : 0.06),
                      blurRadius: _searchFocused ? 22 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  cursorColor: green,
                  style: GoogleFonts.manrope(color: p.text, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени или сообщению...',
                    hintStyle: GoogleFonts.manrope(color: p.muted, fontSize: 14.5),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(LucideIcons.search, color: green, size: 15),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(LucideIcons.x, size: 16, color: p.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: p.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: green, width: 1.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Reveal(
          delay: const Duration(milliseconds: 80),
          offsetY: 10,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Все',
                  icon: LucideIcons.message_circle,
                  selected: !_unreadOnly,
                  p: p,
                  onTap: () => setState(() => _unreadOnly = false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Непрочитанные',
                  icon: LucideIcons.bell,
                  selected: _unreadOnly,
                  count: inbox.asData?.value.where((i) => i.unreadCount > 0).length ?? 0,
                  p: p,
                  onTap: () => setState(() => _unreadOnly = true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(LucideIcons.arrow_left, size: 12, color: p.muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'смахните — удалить',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(fontSize: 10.5, color: p.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: inbox.when(
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [for (var i = 0; i < 5; i++) _SkeletonTile(p: p, index: i)],
            ),
            error: (_, __) => _EmptyChats(
              p: p,
              icon: LucideIcons.circle_alert,
              title: 'Чаты недоступны',
              subtitle: 'Проверьте интернет и потяните вниз, чтобы обновить.',
              onRetry: _refresh,
            ),
            data: (items) {
              var filtered = _unreadOnly ? items.where((i) => i.unreadCount > 0).toList() : items;
              if (_query.isNotEmpty) {
                filtered = filtered
                    .where(
                      (i) =>
                          i.peerName.toLowerCase().contains(_query) ||
                          i.subtitle.toLowerCase().contains(_query),
                    )
                    .toList();
              }

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  color: green,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _EmptyChats(
                        p: p,
                        icon: _query.isNotEmpty
                            ? LucideIcons.search_x
                            : (_unreadOnly ? LucideIcons.check_check : LucideIcons.message_circle),
                        title: _query.isNotEmpty
                            ? 'Ничего не найдено'
                            : (_unreadOnly ? 'Всё прочитано' : 'Чатов пока нет'),
                        subtitle: _query.isNotEmpty
                            ? 'Попробуйте другое имя или слово.'
                            : (_unreadOnly
                                ? 'Новых сообщений нет — вы в курсе всего.'
                                : 'Чат с мастером появится сразу после того, как он примет ваш заказ.'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: green,
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return Reveal(
                      key: ValueKey('chat-${item.conversationId ?? item.orderId}-$_unreadOnly'),
                      delay: Duration(milliseconds: 40 * (i < 10 ? i : 10)),
                      offsetY: 18,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        // Смахните влево — удалить чат. Долгое нажатие — меню.
                        child: Dismissible(
                          key: ValueKey('dismiss-${chatHideKey(item)}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(item),
                          onDismissed: (_) => _deleteChat(item),
                          background: const _DeleteBackground(),
                          child: _ChatInboxTile(
                            item: item,
                            p: p,
                            onTap: () => _openItem(item),
                            onLongPress: () => _showChatMenu(item),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.p,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final HomePalette p;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF57B55E);
    return HoverLift(
      radius: 20,
      lift: 2,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [Color(0xFF2E9E4F), Color(0xFF57B55E)])
                : null,
            color: selected ? null : p.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.transparent : p.border),
            boxShadow: selected
                ? [BoxShadow(color: green.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : p.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : p.text,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                UnreadBadge(count: count, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({
    required this.p,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final HomePalette p;
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF57B55E);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Reveal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatY(
              amplitude: 6,
              child: PulseRing(
                color: green,
                size: 96,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [green.withValues(alpha: 0.22), green.withValues(alpha: 0.08)],
                    ),
                  ),
                  child: Icon(icon, size: 40, color: green),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 13.5, color: p.muted, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => onRetry!(),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(LucideIcons.refresh_cw, size: 16, color: Colors.white),
                label: Text('Обновить', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile({required this.p, required this.index});

  final HomePalette p;
  final int index;

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final a = 0.35 + 0.35 * _c.value;
        final block = p.muted.withValues(alpha: 0.12 * a + 0.04);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: block, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120.0 + 20 * (widget.index % 3), height: 12, decoration: BoxDecoration(color: block, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: block, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatInboxTile extends StatelessWidget {
  const _ChatInboxTile({
    required this.item,
    required this.p,
    required this.onTap,
    this.onLongPress,
  });

  final ChatInboxItem item;
  final HomePalette p;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final unread = item.unreadCount > 0;
    const green = Color(0xFF57B55E);
    return HoverLift(
      scale: 1.015,
      lift: 3,
      glowColor: green,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: unread ? green.withValues(alpha: 0.07) : p.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: unread ? green.withValues(alpha: 0.35) : p.border),
            ),
            child: Row(
              children: [
                if (item.conversationId != null)
                  Hero(
                    tag: 'chat-avatar-${item.conversationId}',
                    child: _Avatar(name: item.peerName, imageAsset: item.avatarAsset, highlight: unread),
                  )
                else
                  _Avatar(name: item.peerName, imageAsset: item.avatarAsset, highlight: unread),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.peerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 15.5,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: unread ? p.text : p.muted,
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
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
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: unread ? green : p.muted,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                        child: child,
                      ),
                      child: unread
                          ? UnreadBadge(key: ValueKey(item.unreadCount), count: item.unreadCount)
                          : Container(
                              key: const ValueKey('status'),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.badgeBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: item.badgeColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    item.badgeLabel,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: item.badgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageAsset, this.highlight = false});

  final String name;
  final String? imageAsset;
  final bool highlight;

  static const _palettes = <List<Color>>[
    [Color(0xFF57B55E), Color(0xFF2E9E4F)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFEC4899), Color(0xFFBE185D)],
    [Color(0xFF14B8A6), Color(0xFF0F766E)],
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    final colors = _palettes[trimmed.hashCode.abs() % _palettes.length];

    final Widget inner = (imageAsset != null && imageAsset!.isNotEmpty)
        ? CircleAvatar(radius: 24, backgroundImage: AssetImage(imageAsset!))
        : Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            ),
            child: Text(
              initial,
              style: GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: highlight
            ? const SweepGradient(colors: [Color(0xFF57B55E), Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF57B55E)])
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: inner,
      ),
    );
  }
}

/// Красный кружок с числом непрочитанных — как в Instagram.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, this.size = 22});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}


/// Красный фон под карточкой при смахивании влево.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.trash_2, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text('Удалить', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}
