import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_result.dart';
import '../../../core/config/app_config.dart';
import '../../../core/realtime/signalr_provider.dart';
import '../../../core/realtime/signalr_service.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../../calls/call_controller.dart';
import '../../calls/call_screen.dart';
import '../data/chat_payload.dart';
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
  Timer? _pollTimer;
  bool _uploading = false;
  bool _hasText = false;
  SignalRService? _hub;
  ChatMessageHandler? _onMsg;
  bool _sendPressed = false;
  final Set<String> _shownIds = <String>{};

  // Голосовые сообщения
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _webUseOpus = false;
  final Stopwatch _recordWatch = Stopwatch();
  Timer? _recordTicker;

  bool get _isLocal =>
      widget.isLocal || widget.conversation.id.startsWith('local-chat-');

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText && mounted) setState(() => _hasText = has);
    });
    if (!_isLocal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setupHub());
      // Запасной вариант, если SignalR не подключился: обновляем переписку каждые 4 секунды.
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) ref.invalidate(chatMessagesProvider(widget.conversation.id));
      });
    }
  }

  Future<void> _setupHub() async {
    if (!mounted) return;
    final signalR = ref.read(signalRServiceProvider);
    _hub = signalR;
    signalR.onChatMessage = _onMsg = (payload) {
      if (!mounted) return;
      if (payload['conversationId']?.toString() == widget.conversation.id) {
        ref.invalidate(chatMessagesProvider(widget.conversation.id));
      }
    };
    try {
      await signalR.joinConversation(widget.conversation.id);
    } catch (_) {
      // Нет realtime-подключения — сообщения всё равно придут через опрос сервера.
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordTicker?.cancel();
    unawaited(_recorder.dispose());
    if (_hub != null && identical(_hub!.onChatMessage, _onMsg)) _hub!.onChatMessage = null;
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
      if (!mounted) return;
      ref.invalidate(chatMessagesProvider(widget.conversation.id));
      ref.invalidate(conversationsProvider);
      ref.invalidate(chatInboxProvider);
      return;
    }

    // 1) Отправляем через REST API (сообщение сохраняется на сервере и рассылается собеседнику).
    final result = await ref.read(chatRepositoryProvider).sendMessage(
          conversationId: widget.conversation.id,
          text: text,
        );
    if (result is ApiError) {
      // 2) Старый сервер без REST-отправки — пробуем через SignalR.
      try {
        await ref.read(signalRServiceProvider).sendChatMessage(
              conversationId: widget.conversation.id,
              text: text,
            );
      } catch (_) {
        if (!mounted) return;
        _controller.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result as ApiError).message)),
        );
        return;
      }
    }
    if (!mounted) return;
    ref.invalidate(chatMessagesProvider(widget.conversation.id));
    ref.invalidate(chatInboxProvider);
  }

  /// Новое сообщение «выезжает» один раз; уже показанные не анимируются при прокрутке.
  Widget _appearOnce(String id, bool fromRight, Widget child) {
    if (_shownIds.contains(id)) return child;
    _shownIds.add(id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, c) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset((fromRight ? 24 : -24) * (1 - t), 10 * (1 - t)),
          child: Transform.scale(
            scale: 0.92 + 0.08 * t,
            alignment: fromRight ? Alignment.bottomRight : Alignment.bottomLeft,
            child: c,
          ),
        ),
      ),
      child: child,
    );
  }

  bool _dayChanged(DateTime? prev, DateTime? cur) {
    if (cur == null) return false;
    if (prev == null) return true;
    final a = prev.toLocal();
    final b = cur.toLocal();
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  String _dayLabel(DateTime? time) {
    if (time == null) return '';
    final d = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    final base = '${d.day} ${months[d.month - 1]}';
    return d.year == now.year ? base : '$base ${d.year}';
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
        style: GoogleFonts.manrope(
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

    final serverPeerName = widget.conversation.peerName?.trim();
    final peerName = (serverPeerName != null && serverPeerName.isNotEmpty)
        ? serverPeerName
        : auth.isMaster
            ? (entry?.clientName ?? widget.conversation.title)
            : (entry?.masterName ?? widget.conversation.title);
    final serviceLine = entry != null
        ? '${entry.title} · ${entry.price.toStringAsFixed(0)} с.'
        : null;

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
            Hero(
              tag: 'chat-avatar-${widget.conversation.id}',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _peerAvatar(
                    peerName,
                    imageAsset: auth.isMaster ? null : masterCatalog?.image,
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const LiveDot(color: _brandGreen, size: 8),
                    ),
                  ),
                ],
              ),
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
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (serviceLine != null)
                    Text(
                      serviceLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: HoverLift(
              radius: 14,
              lift: 2,
              glowColor: _brandGreen,
              child: Material(
                color: _brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showCallOptions(
                    peerName,
                    auth.isMaster
                        ? entry?.clientPhone
                        : (entry?.masterPhone ?? masterCatalog?.phone),
                  ),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(LucideIcons.phone, color: _brandGreen, size: 19),
                  ),
                ),
              ),
            ),
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
                data: (items) {
                  if (items.isEmpty && !_peerTyping) {
                    return _EmptyThread(peerName: peerName);
                  }
                  return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length + (_peerTyping ? 1 : 0),
                  itemBuilder: (context, rIndex) {
                    if (_peerTyping) {
                      if (rIndex == 0) return const _TypingBubble();
                      rIndex -= 1;
                    }
                    final index = items.length - 1 - rIndex;
                    final m = items[index];
                    final prev = index > 0 ? items[index - 1] : null;
                    final showDate = _dayChanged(prev?.createdAt, m.createdAt);

                    Widget body;
                    if (m.senderUserId == 'system') {
                      body = _SystemBanner(text: m.text);
                    } else {
                    final isMasterMsg = m.senderUserId == 'master';
                    final isMine = m.senderUserId == myRole;
                    final alignRight = isMine;

                    final bubbleColor = isMine
                        ? _brandGreen
                        : (isMasterMsg ? const Color(0xFFEAF6EB) : Colors.white);
                    final textColor = isMine
                        ? Colors.white
                        : const Color(0xFF111827);

                    body = _appearOnce(
                      m.id,
                      alignRight,
                      Align(
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
                            _MessageContent(
                              message: m,
                              isMine: isMine,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(m.createdAt),
                                  style: GoogleFonts.manrope(
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
                      ),),
                    );
                    }

                    if (!showDate) return body;
                    return Column(
                      children: [
                        _DateChip(label: _dayLabel(m.createdAt)),
                        body,
                      ],
                    );
                  },
                );
                },
              ),
            ),
            if (_uploading)
              const LinearProgressIndicator(
                minHeight: 3,
                color: _brandGreen,
                backgroundColor: Color(0xFFE8F5E9),
              ),
            // Quick reply chips
            _QuickReplies(onSelect: (text) {
              _controller.text = text;
              _send();
            }),
            if (_recording)
              SafeArea(child: _buildRecordingBar())
            else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    HoverLift(
                      radius: 21,
                      lift: 2,
                      scale: 1.08,
                      child: GestureDetector(
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Сообщение...',
                          hintStyle:
                              GoogleFonts.manrope(color: const Color(0xFF9CA3AF)),
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
                      onTapDown: (_) => setState(() => _sendPressed = true),
                      onTapCancel: () => setState(() => _sendPressed = false),
                      onTapUp: (_) => setState(() => _sendPressed = false),
                      onTap: _hasText ? _send : _startRecording,
                      child: AnimatedScale(
                        scale: _sendPressed ? 0.86 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _brandGreen.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          // Пустое поле — микрофон (голосовое), есть текст — «отправить».
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (c, a) => ScaleTransition(
                              scale: a,
                              child: RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(a), child: c),
                            ),
                            child: Icon(
                              _hasText ? LucideIcons.send : LucideIcons.mic,
                              key: ValueKey(_hasText),
                              color: Colors.white,
                              size: 20,
                            ),
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
      ),
    );
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.manrope()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Звонок собеседнику через обычное приложение «Телефон».
  Future<void> _callPeer(String? fallbackPhone) async {
    // Клиент звонит мастеру только через единый номер; мастер звонит клиенту напрямую.
    final isMaster = ref.read(authProvider).isMaster;
    final phone = isMaster ? (widget.conversation.peerPhone ?? fallbackPhone) : AppConfig.masterHotline;
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 9) {
      _toast('Номер собеседника недоступен');
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await launchUrl(uri)) {
      _toast('Не удалось открыть звонок: $digits');
    }
  }

  Future<void> _sendPayload(String text, int messageType) async {
    final result = await ref.read(chatRepositoryProvider).sendMessage(
          conversationId: widget.conversation.id,
          text: text,
          messageType: messageType,
        );
    if (result is ApiError) {
      _toast((result as ApiError).message);
      return;
    }
    if (!mounted) return;
    ref.invalidate(chatMessagesProvider(widget.conversation.id));
    ref.invalidate(chatInboxProvider);
  }

  Future<void> _uploadAndSend(List<int> bytes, String fileName, int messageType, {int durationMs = 0}) async {
    if (bytes.length > 10 * 1024 * 1024) {
      _toast('Файл больше 10 МБ');
      return;
    }
    setState(() => _uploading = true);
    try {
      final upload = await ref
          .read(chatRepositoryProvider)
          .uploadAttachment(bytes: bytes, fileName: fileName);
      if (upload is ApiSuccess<ChatAttachment>) {
        await _sendPayload(jsonEncode(upload.data.copyWith(durationMs: durationMs).toJson()), messageType);
      } else if (upload is ApiError<ChatAttachment>) {
        _toast(upload.message);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ───────────── Голосовые сообщения ─────────────

  Future<void> _startRecording() async {
    if (_isLocal) {
      _toast('Голосовые работают в чате, созданном на сервере (новый заказ).');
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        _toast('Разрешите доступ к микрофону, чтобы записать голосовое');
        return;
      }
      final String path;
      // В Safari нет opus — тогда пишем в m4a.
      _webUseOpus = kIsWeb && await _recorder.isEncoderSupported(AudioEncoder.opus);
      if (kIsWeb) {
        path = _webUseOpus ? 'voice.webm' : 'voice.m4a';
      } else {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await _recorder.start(
        RecordConfig(
          encoder: _webUseOpus ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: path,
      );
      HapticFeedback.mediumImpact();
      _recordWatch
        ..reset()
        ..start();
      _recordTicker?.cancel();
      _recordTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        // Максимум 5 минут — потом отправляем автоматически.
        if (_recordWatch.elapsed >= const Duration(minutes: 5)) {
          _stopRecording(send: true);
          return;
        }
        setState(() {});
      });
      setState(() => _recording = true);
    } catch (_) {
      _toast('Не удалось включить микрофон');
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    if (!_recording) return;
    _recordTicker?.cancel();
    _recordWatch.stop();
    final durationMs = _recordWatch.elapsedMilliseconds;
    setState(() => _recording = false);
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      if (send) _toast('Запись не сохранилась: $e');
      return;
    }
    if (!send) return;
    if (path == null || path.isEmpty) {
      _toast('Запись не сохранилась. Проверьте, что микрофон разрешён.');
      return;
    }
    if (durationMs < 1000) {
      _toast('Слишком короткое — держите запись хотя бы секунду');
      return;
    }
    try {
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) {
        _toast('Запись пустая — попробуйте ещё раз');
        return;
      }
      await _uploadAndSend(
        bytes,
        _webUseOpus ? 'voice.webm' : 'voice.m4a',
        ChatMessageType.voice,
        durationMs: durationMs,
      );
    } catch (e) {
      _toast('Не удалось отправить голосовое: $e');
    }
  }

  Widget _buildRecordingBar() {
    final secs = _recordWatch.elapsed.inSeconds;
    final label = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Reveal(
        offsetY: 12,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFECACA)),
            boxShadow: [
              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Отменить',
                onPressed: () => _stopRecording(send: false),
                icon: const Icon(LucideIcons.trash_2, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 4),
              const LiveDot(color: Color(0xFFEF4444), size: 10),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
              ),
              const SizedBox(width: 10),
              Expanded(child: _LiveWave(seed: secs)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _stopRecording(send: true),
                child: const PulseRing(
                  color: _brandGreen,
                  size: 46,
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: _brandGreen, shape: BoxShape.circle),
                      child: Icon(LucideIcons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────── Звонок ─────────────

  void _showCallOptions(String peerName, String? fallbackPhone) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Widget option({
          required IconData icon,
          required Color color,
          required String title,
          required String sub,
          required VoidCallback onTap,
          required int index,
        }) {
          return Reveal(
            delay: Duration(milliseconds: 60 + 70 * index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HoverLift(
                radius: 18,
                glowColor: color,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      onTap();
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: GoogleFonts.manrope(fontSize: 15.5, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                                const SizedBox(height: 2),
                                Text(sub, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevron_right, color: color, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Позвонить: $peerName',
                  style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 14),
                option(
                  index: 0,
                  icon: LucideIcons.phone_call,
                  color: _brandGreen,
                  title: 'Звонок в приложении',
                  sub: 'Бесплатно через интернет · зашифрован',
                  onTap: () => _startAppCall(peerName),
                ),
                option(
                  index: 1,
                  icon: LucideIcons.phone,
                  color: const Color(0xFF3B82F6),
                  title: 'Обычный звонок',
                  sub: ref.read(authProvider).isMaster
                      ? 'По номеру телефона через оператора'
                      : 'Через оператора: ${AppConfig.masterHotlineLabel}',
                  onTap: () => _callPeer(fallbackPhone),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startAppCall(String peerName) async {
    if (_isLocal) {
      _toast('Звонок в приложении работает в чате, созданном на сервере (новый заказ).');
      return;
    }
    final call = ref.read(callControllerProvider);
    if (call.busy) {
      _toast('Уже идёт звонок');
      return;
    }
    unawaited(Navigator.of(context).push(SmoothRoute<void>(builder: (_) => const CallScreen())));
    final error = await call.startCall(conversationId: widget.conversation.id, peerName: peerName);
    if (error != null) _toast(error);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        // Сжимаем на телефоне: фото ~4 МБ превращается в ~150–250 КБ,
        // чтобы не забивать сервер.
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 60,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
      await _uploadAndSend(bytes, name, ChatMessageType.image);
    } catch (_) {
      _toast(source == ImageSource.camera
          ? 'Не удалось открыть камеру. Разрешите доступ к камере.'
          : 'Не удалось выбрать фото');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      final file = result?.files.single;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null) {
        _toast('Не удалось прочитать файл');
        return;
      }
      if (bytes.length > 10 * 1024 * 1024) {
        _toast('Файл больше 10 МБ. Выберите файл поменьше.');
        return;
      }
      final lower = file.name.toLowerCase();
      final isImage = lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif');
      await _uploadAndSend(
        bytes,
        file.name,
        isImage ? ChatMessageType.image : ChatMessageType.file,
      );
    } catch (_) {
      _toast('Не удалось выбрать файл');
    }
  }

  Future<void> _sendLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Включите геолокацию (GPS) на телефоне');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast('Разрешите доступ к геолокации в настройках');
        return;
      }
      setState(() => _uploading = true);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await _sendPayload(
        ChatLocation(lat: position.latitude, lng: position.longitude).toPayload(),
        ChatMessageType.location,
      );
    } catch (_) {
      _toast('Не удалось определить местоположение');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
              const SizedBox(height: 14),
              Text(
                'Отправить вложение',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Reveal(
                    delay: const Duration(milliseconds: 0),
                    offsetY: 20,
                    child: _attachOption(ctx, LucideIcons.image, 'Фото', const Color(0xFF8B5CF6),
                        () => _pickImage(ImageSource.gallery)),
                  ),
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    offsetY: 20,
                    child: _attachOption(ctx, LucideIcons.camera, 'Камера', const Color(0xFF3B82F6),
                        () => _pickImage(ImageSource.camera)),
                  ),
                  Reveal(
                    delay: const Duration(milliseconds: 120),
                    offsetY: 20,
                    child: _attachOption(ctx, LucideIcons.map_pin, 'Гео', const Color(0xFFEF4444),
                        _sendLocation),
                  ),
                  Reveal(
                    delay: const Duration(milliseconds: 180),
                    offsetY: 20,
                    child: _attachOption(ctx, LucideIcons.file_text, 'Файл', const Color(0xFFF59E0B),
                        _pickFile),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    Future<void> Function() action,
  ) {
    return HoverLift(
      radius: 18,
      scale: 1.08,
      glowColor: color,
      child: GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        if (_isLocal) {
          _toast('Вложения работают в чате, созданном на сервере (новый заказ).');
          return;
        }
        action();
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
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
        ],
      ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.peerName});

  final String peerName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Reveal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatY(
                amplitude: 6,
                child: PulseRing(
                  color: _brandGreen,
                  size: 84,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _brandGreen.withValues(alpha: 0.14),
                    ),
                    child: const Icon(LucideIcons.message_circle, size: 36, color: _brandGreen),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Напишите $peerName',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              Text(
                'Обсудите время, адрес и детали заказа. Можно отправить фото, файл или геолокацию.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
              ),
            ],
          ),
        ),
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
                style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
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

// ── Содержимое сообщения: текст, фото, файл или геолокация ──
class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.isMine,
    required this.textColor,
  });

  final ApiMessage message;
  final bool isMine;
  final Color textColor;

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    switch (message.messageType) {
      case ChatMessageType.voice:
        final voice = ChatAttachment.tryParse(message.text);
        if (voice == null) break;
        return _VoiceBubble(attachment: voice, isMine: isMine);
      case ChatMessageType.image:
        final attachment = ChatAttachment.tryParse(message.text);
        if (attachment == null) break;
        final url = attachment.absoluteUrl;
        return GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      maxScale: 5,
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                  SafeArea(
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
              errorBuilder: (_, __, ___) => Container(
                width: 220,
                height: 120,
                color: const Color(0xFFF3F4F6),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.image, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        );

      case ChatMessageType.file:
        final attachment = ChatAttachment.tryParse(message.text);
        if (attachment == null) break;
        return InkWell(
          onTap: () => _open(attachment.absoluteUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.file_text,
                  color: isMine ? Colors.white : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${attachment.sizeLabel} · Открыть',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case ChatMessageType.location:
        final location = ChatLocation.tryParse(message.text);
        if (location == null) break;
        return InkWell(
          onTap: () => _open(location.mapsUrl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 220,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDCFCE7), Color(0xFFDBEAFE)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.map_pin, size: 40, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 6),
              Text(
                'Геолокация',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                'Открыть на карте',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                  decorationColor: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
    }

    return Text(
      message.text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        color: textColor,
        height: 1.4,
      ),
    );
  }
}


/// Анимированная «волна» во время записи.
class _LiveWave extends StatelessWidget {
  const _LiveWave({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: LayoutBuilder(
        builder: (context, box) {
          final count = (box.maxWidth / 5).floor().clamp(4, 60);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (i) {
              final h = 6.0 + ((i * 7 + seed * 13) % 19);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Голосовое сообщение: кнопка play/pause, волна с прогрессом и длительность.
class _VoiceBubble extends StatefulWidget {
  const _VoiceBubble({required this.attachment, required this.isMine});

  final ChatAttachment attachment;
  final bool isMine;

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  AudioPlayer? _player;
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _duration = Duration(milliseconds: widget.attachment.durationMs);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Source? _source;

  /// Скачиваем голосовое сами и отдаём плееру байты с правильным типом —
  /// так оно играет независимо от заголовков сервера.
  Future<Source> _loadSource() async {
    if (_source != null) return _source!;
    final a = widget.attachment;
    final name = a.fileName.contains('.') ? a.fileName : a.url;
    final mime = chatMimeTypeFor(name);
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'm4a';
    final data = await ProviderScope.containerOf(context, listen: false)
        .read(chatRepositoryProvider)
        .downloadBytes(a.absoluteUrl);
    final bytes = Uint8List.fromList(data);
    if (bytes.isEmpty) throw Exception('пустой файл');
    if (kIsWeb) {
      _source = BytesSource(bytes, mimeType: mime);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/voice_${a.url.hashCode.toUnsigned(32)}.$ext');
      await file.writeAsBytes(bytes, flush: true);
      _source = DeviceFileSource(file.path, mimeType: mime);
    }
    return _source!;
  }

  Future<void> _toggle() async {
    try {
      if (_player == null) {
        final p = AudioPlayer();
        _player = p;
        _subs.add(p.onPositionChanged.listen((d) {
          if (mounted) setState(() => _position = d);
        }));
        _subs.add(p.onDurationChanged.listen((d) {
          if (mounted && d > Duration.zero) setState(() => _duration = d);
        }));
        _subs.add(p.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
          }
        }));
      }
      if (_playing) {
        await _player!.pause();
        setState(() => _playing = false);
      } else {
        setState(() => _loading = true);
        if (_position > Duration.zero) {
          await _player!.resume();
        } else {
          await _player!.play(await _loadSource());
        }
        if (mounted) setState(() => _playing = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось воспроизвести голосовое: $e', style: GoogleFonts.manrope()), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.isMine;
    final fg = mine ? Colors.white : _brandGreen;
    final total = _duration.inMilliseconds > 0 ? _duration : Duration(milliseconds: widget.attachment.durationMs);
    final progress = total.inMilliseconds > 0 ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0) : 0.0;
    final shown = _playing || _position > Duration.zero ? _position : total;
    final secs = shown.inSeconds;
    final label = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final seed = widget.attachment.url.hashCode;

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          GestureDetector(
            onTap: _loading ? null : _toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mine ? Colors.white.withValues(alpha: 0.22) : _brandGreen.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _playing ? LucideIcons.pause : LucideIcons.play,
                        key: ValueKey(_playing),
                        color: fg,
                        size: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final count = (box.maxWidth / 5).floor().clamp(4, 40);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(count, (i) {
                          final h = 5.0 + ((seed >> (i % 16)) & 0xF) + (i % 3) * 2;
                          final played = i / count <= progress;
                          return Container(
                            width: 3,
                            height: h.clamp(5.0, 22.0),
                            decoration: BoxDecoration(
                              color: played ? fg : fg.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(LucideIcons.mic, size: 11, color: mine ? Colors.white70 : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: mine ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
