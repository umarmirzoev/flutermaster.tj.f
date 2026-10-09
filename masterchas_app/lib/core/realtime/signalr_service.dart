import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

typedef OrderStatusChangedHandler = void Function(String orderId, String newStatus);
typedef OrderAssignedHandler = void Function(String orderId);
typedef ChatMessageHandler = void Function(Map<String, dynamic> message);

class SignalRService {
  HubConnection? _ordersHub;
  HubConnection? _chatHub;
  final _storage = const FlutterSecureStorage();

  OrderStatusChangedHandler? onOrderStatusChanged;
  OrderAssignedHandler? onOrderAssigned;
  ChatMessageHandler? onChatMessage;

  Future<void> connect() async {
    await _connectOrdersHub();
  }

  /// Обработчики событий звонков (call.incoming, call.answered, call.ice, call.ended).
  final Map<String, void Function(Map<String, dynamic> payload)> _callHandlers = {};
  Future<void>? _connecting;

  bool get isChatConnected => _chatHub?.state == HubConnectionState.Connected;

  /// Подписка на событие хаба чата. Можно вызывать до подключения —
  /// обработчик подключится, как только появится соединение.
  void onChatEvent(String event, void Function(Map<String, dynamic> payload) handler) {
    final isNew = !_callHandlers.containsKey(event);
    _callHandlers[event] = handler;
    if (isNew && _chatHub != null) _bindEvent(event);
  }

  void _bindEvent(String event) {
    _chatHub!.on(event, (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _callHandlers[event]?.call(Map<String, dynamic>.from(raw));
      }
    });
  }

  Future<void> connectChat() async {
    if (isChatConnected) return;
    if (_connecting != null) return _connecting;
    _connecting = _doConnectChat();
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _doConnectChat() async {
    if (_chatHub == null) {
      _chatHub = HubConnectionBuilder()
          .withUrl(
            AppConfig.chatHubUrl,
            options: HttpConnectionOptions(
              // Токен читаем каждый раз заново — после входа/выхода он меняется.
              accessTokenFactory: () async =>
                  await _storage.read(key: SecureStorageService.authTokenKey) ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();

      _chatHub!.on('message.received', (args) {
        if (args == null || args.isEmpty) return;
        final raw = args.first;
        if (raw is Map) {
          onChatMessage?.call(Map<String, dynamic>.from(raw as Map));
        }
      });
      for (final event in _callHandlers.keys) {
        _bindEvent(event);
      }
      // Автопереподключение сдалось — пробуем снова через 5 секунд.
      final hub = _chatHub!;
      hub.onclose(({error}) {
        Future<void>.delayed(const Duration(seconds: 5), () {
          if (identical(_chatHub, hub)) connectChat().catchError((_) {});
        });
      });
    }

    if (_chatHub!.state == HubConnectionState.Disconnected) {
      await _chatHub!.start();
    }
  }

  /// Вызов метода хаба чата (сигналинг звонков).
  Future<void> invokeChat(String method, List<Object> args) async {
    await connectChat();
    await _chatHub!.invoke(method, args: args);
  }

  Future<void> joinConversation(String conversationId) async {
    await connectChat();
    await _chatHub!.invoke('JoinConversation', args: [conversationId]);
  }

  Future<void> sendChatMessage({
    required String conversationId,
    required String text,
  }) async {
    await connectChat();
    await _chatHub!.invoke('SendMessage', args: [
      {
        'conversationId': conversationId,
        'text': text,
        'messageType': 1,
      }
    ]);
  }

  Future<void> _connectOrdersHub() async {
    if (_ordersHub != null) return;

    final token = await _storage.read(key: SecureStorageService.authTokenKey);
    _ordersHub = HubConnectionBuilder()
        .withUrl(
          AppConfig.ordersHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _ordersHub!.on('OrderStatusChanged', (args) {
      if (args == null || args.length < 2) return;
      onOrderStatusChanged?.call(
        args[0]?.toString() ?? '',
        args[1]?.toString() ?? '',
      );
    });

    _ordersHub!.on('OrderAssigned', (args) {
      if (args == null || args.isEmpty) return;
      onOrderAssigned?.call(args[0]?.toString() ?? '');
    });

    await _ordersHub!.start();
  }

  Future<void> disconnect() async {
    await _ordersHub?.stop();
    await _chatHub?.stop();
    _ordersHub = null;
    _chatHub = null;
  }
}
