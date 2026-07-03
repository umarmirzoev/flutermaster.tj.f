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

  Future<void> connectChat() async {
    if (_chatHub != null) return;

    final token = await _storage.read(key: SecureStorageService.authTokenKey);
    _chatHub = HubConnectionBuilder()
        .withUrl(
          AppConfig.chatHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
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

    await _chatHub!.start();
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
