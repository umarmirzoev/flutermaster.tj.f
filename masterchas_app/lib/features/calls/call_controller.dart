import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/network/dio_provider.dart';
import '../../core/realtime/signalr_provider.dart';
import '../../core/realtime/signalr_service.dart';
import '../chat/data/chat_repository.dart';
import 'ring_tone.dart';

enum CallPhase { idle, outgoing, incoming, connecting, active, ended }

/// Звонки внутри приложения (WebRTC, только звук).
///
/// Сигналинг (offer/answer/ICE) идёт через SignalR-хаб чата, сам звук —
/// напрямую между телефонами или через наш TURN-сервер. Звук шифруется
/// DTLS-SRTP: сервер его не слышит и не записывает.
class CallController extends ChangeNotifier {
  CallController(this._ref);

  final Ref _ref;

  CallPhase phase = CallPhase.idle;
  String? conversationId;
  String peerName = '';
  bool isOutgoing = false;
  bool muted = false;
  bool speakerOn = false;
  String? endReason;
  Duration elapsed = Duration.zero;

  /// Для веба звук собеседника проигрывается через этот рендерер.
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _rendererReady = false;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String? _pendingOfferSdp;
  final List<RTCIceCandidate> _pendingIce = [];
  bool _remoteSet = false;
  Timer? _ringTimeout;
  Timer? _ticker;
  DateTime? _startedAt;
  bool _attached = false;
  bool _invited = false;
  final RingTone _ring = RingTone();

  /// Показывает экран входящего звонка (задаёт CallHost).
  void Function()? onIncoming;

  bool get busy => phase != CallPhase.idle && phase != CallPhase.ended;

  SignalRService get _hub => _ref.read(signalRServiceProvider);

  /// Подписка на события звонков. Вызывается, когда пользователь вошёл.
  Future<void> attach() async {
    if (!_attached) {
      _attached = true;
      _hub.onChatEvent('call.incoming', _onIncoming);
      _hub.onChatEvent('call.answered', _onAnswered);
      _hub.onChatEvent('call.ice', _onRemoteIce);
      _hub.onChatEvent('call.ended', _onRemoteEnded);
    }
    try {
      await _hub.connectChat();
    } catch (_) {
      // Нет соединения — попробуем при следующем вызове attach().
    }
  }

  // ───────────── Исходящий звонок ─────────────

  Future<String?> startCall({required String conversationId, required String peerName}) async {
    if (busy) return 'Уже идёт звонок';
    _reset();
    this.conversationId = conversationId;
    this.peerName = peerName;
    isOutgoing = true;
    phase = CallPhase.outgoing;
    notifyListeners();

    try {
      await _hub.connectChat();
      await _createPeer();
      final offer = await _pc!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
      await _pc!.setLocalDescription(offer);
      await _hub.invokeChat('CallInvite', [conversationId, offer.sdp ?? '']);
      _invited = true;
      unawaited(_ring.start(incoming: false));
      _ringTimeout = Timer(const Duration(seconds: 45), () {
        if (phase == CallPhase.outgoing) hangUp(reason: 'timeout');
      });
      return null;
    } catch (e) {
      await _finish('failed', notifyPeer: false);
      return _friendlyError(e);
    }
  }

  // ───────────── Входящий звонок ─────────────

  void _onIncoming(Map<String, dynamic> p) {
    final convId = p['conversationId']?.toString();
    final sdp = p['sdp']?.toString();
    if (convId == null || sdp == null) return;
    if (busy) {
      // Уже разговариваем — отвечаем «занято».
      unawaited(_hub.invokeChat('CallEnd', [convId, 'busy']).catchError((_) {}));
      return;
    }
    _reset();
    conversationId = convId;
    peerName = p['fromName']?.toString() ?? 'Собеседник';
    isOutgoing = false;
    _pendingOfferSdp = sdp;
    phase = CallPhase.incoming;
    notifyListeners();
    unawaited(_ring.start(incoming: true));
    _vibrateLoop();
    _ringTimeout = Timer(const Duration(seconds: 45), () {
      if (phase == CallPhase.incoming) _finish('missed', notifyPeer: false);
    });
    onIncoming?.call();
  }

  Future<String?> accept() async {
    if (phase != CallPhase.incoming || _pendingOfferSdp == null) return null;
    _ringTimeout?.cancel();
    await _ring.stop();
    phase = CallPhase.connecting;
    notifyListeners();
    try {
      await _createPeer();
      await _pc!.setRemoteDescription(RTCSessionDescription(_pendingOfferSdp, 'offer'));
      _remoteSet = true;
      await _flushIce();
      final answer = await _pc!.createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
      await _pc!.setLocalDescription(answer);
      await _hub.invokeChat('CallAnswer', [conversationId!, answer.sdp ?? '']);
      return null;
    } catch (e) {
      await _finish('failed', notifyPeer: true);
      return _friendlyError(e);
    }
  }

  Future<void> decline() => _finish('declined', notifyPeer: true);

  Future<void> hangUp({String reason = 'ended'}) {
    final r = phase == CallPhase.outgoing && reason == 'ended' ? 'cancelled' : reason;
    return _finish(r, notifyPeer: true);
  }

  // ───────────── События от собеседника ─────────────

  Future<void> _onAnswered(Map<String, dynamic> p) async {
    if (p['conversationId']?.toString() != conversationId || phase != CallPhase.outgoing) return;
    _ringTimeout?.cancel();
    await _ring.stop();
    phase = CallPhase.connecting;
    notifyListeners();
    try {
      await _pc?.setRemoteDescription(RTCSessionDescription(p['sdp']?.toString(), 'answer'));
      _remoteSet = true;
      await _flushIce();
    } catch (_) {
      await _finish('failed', notifyPeer: true);
    }
  }

  Future<void> _onRemoteIce(Map<String, dynamic> p) async {
    if (p['conversationId']?.toString() != conversationId) return;
    try {
      final map = jsonDecode(p['candidate']?.toString() ?? '{}') as Map<String, dynamic>;
      final c = RTCIceCandidate(
        map['candidate'] as String?,
        map['sdpMid'] as String?,
        (map['sdpMLineIndex'] as num?)?.toInt(),
      );
      if (_pc != null && _remoteSet) {
        await _pc!.addCandidate(c);
      } else {
        _pendingIce.add(c);
      }
    } catch (_) {}
  }

  void _onRemoteEnded(Map<String, dynamic> p) {
    if (p['conversationId']?.toString() != conversationId || !busy) return;
    _finish(p['reason']?.toString() ?? 'ended', notifyPeer: false);
  }

  // ───────────── Управление ─────────────

  void toggleMute() {
    muted = !muted;
    for (final t in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(speakerOn);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Текст статуса для экрана звонка.
  String get statusText => switch (phase) {
        CallPhase.outgoing => 'Вызов…',
        CallPhase.incoming => 'Входящий звонок',
        CallPhase.connecting => 'Соединение…',
        CallPhase.active => _fmt(elapsed),
        CallPhase.ended => switch (endReason) {
            'declined' => 'Звонок отклонён',
            'busy' => 'Собеседник занят',
            'timeout' || 'missed' => 'Нет ответа',
            'failed' => 'Не удалось соединиться',
            'cancelled' => 'Звонок отменён',
            _ => elapsed > Duration.zero ? 'Звонок завершён · ${_fmt(elapsed)}' : 'Звонок завершён',
          },
        CallPhase.idle => '',
      };

  // ───────────── Внутреннее ─────────────

  Future<void> _createPeer() async {
    final iceServers = await _loadIceServers();
    _pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    for (final track in _localStream!.getAudioTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    if (!_rendererReady) {
      await remoteRenderer.initialize();
      _rendererReady = true;
    }

    _pc!.onIceCandidate = (candidate) {
      final id = conversationId;
      if (id == null || candidate.candidate == null) return;
      unawaited(_hub.invokeChat('CallIce', [id, jsonEncode(candidate.toMap())]).catchError((_) {}));
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };
    _pc!.onIceConnectionState = (state) {
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _markActive();
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _finish('failed', notifyPeer: true);
        default:
          break;
      }
    };
  }

  Future<List<Map<String, dynamic>>> _loadIceServers() async {
    const fallback = [
      {'urls': ['stun:stun.l.google.com:19302']}
    ];
    try {
      final res = await _ref.read(dioProvider).get<dynamic>('/calls/ice-servers');
      var data = res.data;
      if (data is Map && data['data'] is Map) data = data['data'];
      final list = (data is Map ? data['iceServers'] : null) as List?;
      if (list == null || list.isEmpty) return fallback;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _flushIce() async {
    final pending = List<RTCIceCandidate>.from(_pendingIce);
    _pendingIce.clear();
    for (final c in pending) {
      try {
        await _pc?.addCandidate(c);
      } catch (_) {}
    }
  }

  void _markActive() {
    if (phase == CallPhase.active || phase == CallPhase.ended) return;
    phase = CallPhase.active;
    _startedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null) {
        elapsed = DateTime.now().difference(_startedAt!);
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _vibrateLoop() {
    Future.doWhile(() async {
      if (phase != CallPhase.incoming) return false;
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      return phase == CallPhase.incoming;
    });
  }

  Future<void> _finish(String reason, {required bool notifyPeer}) async {
    if (phase == CallPhase.ended || phase == CallPhase.idle) return;
    final wasOutgoing = isOutgoing;
    final invited = _invited;
    final convId = conversationId;
    final talked = phase == CallPhase.active;

    endReason = reason;
    phase = CallPhase.ended;
    _ringTimeout?.cancel();
    _ticker?.cancel();
    notifyListeners();
    await _ring.stop();

    if (notifyPeer && convId != null) {
      try {
        await _hub.invokeChat('CallEnd', [convId, reason]);
      } catch (_) {}
    }

    await _releaseMedia();

    // Запись о звонке в переписке пишет только звонивший — чтобы не было дублей.
    if (wasOutgoing && invited && convId != null) {
      final text = talked
          ? '📞 Аудиозвонок · ${_fmt(elapsed)}'
          : switch (reason) {
              'declined' => '📞 Звонок отклонён',
              'busy' => '📞 Собеседник был занят',
              'failed' => '📞 Звонок не удался',
              'cancelled' => '📞 Звонок отменён',
              _ => '📞 Пропущенный звонок',
            };
      try {
        await _ref.read(chatRepositoryProvider).sendMessage(conversationId: convId, text: text);
      } catch (_) {}
    }

    // Через пару секунд экран звонка закрывается, контроллер готов к новому звонку.
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (phase == CallPhase.ended) {
        phase = CallPhase.idle;
        notifyListeners();
      }
    });
  }

  Future<void> _releaseMedia() async {
    try {
      for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      remoteRenderer.srcObject = null;
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    _remoteSet = false;
    _pendingIce.clear();
    if (speakerOn && !kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(false);
      } catch (_) {}
    }
  }

  void _reset() {
    _ringTimeout?.cancel();
    _ticker?.cancel();
    muted = false;
    speakerOn = false;
    endReason = null;
    elapsed = Duration.zero;
    _startedAt = null;
    _pendingOfferSdp = null;
    _pendingIce.clear();
    _remoteSet = false;
    _invited = false;
  }

  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission') || s.contains('notallowed') || s.contains('denied')) {
      return 'Разрешите доступ к микрофону, чтобы звонить';
    }
    return 'Не удалось начать звонок. Проверьте интернет.';
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _ringTimeout?.cancel();
    _ticker?.cancel();
    unawaited(_ring.stop());
    unawaited(_releaseMedia());
    if (_rendererReady) unawaited(remoteRenderer.dispose());
    super.dispose();
  }
}

final callControllerProvider = Provider<CallController>((ref) {
  final c = CallController(ref);
  ref.onDispose(c.dispose);
  return c;
});
