class LocalChatMessage {
  const LocalChatMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderRole; // client | master
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderRole': senderRole,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalChatMessage.fromJson(Map<String, dynamic> json) {
    return LocalChatMessage(
      id: json['id'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? 'client',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class LocalConversation {
  const LocalConversation({
    required this.id,
    required this.orderId,
    required this.title,
    required this.clientPhone,
    required this.masterPhone,
    this.masterName,
    this.messages = const [],
  });

  final String id;
  final String orderId;
  final String title;
  final String clientPhone;
  final String masterPhone;
  final String? masterName;
  final List<LocalChatMessage> messages;

  LocalConversation copyWith({
    List<LocalChatMessage>? messages,
  }) {
    return LocalConversation(
      id: id,
      orderId: orderId,
      title: title,
      clientPhone: clientPhone,
      masterPhone: masterPhone,
      masterName: masterName,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'title': title,
        'clientPhone': clientPhone,
        'masterPhone': masterPhone,
        'masterName': masterName,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory LocalConversation.fromJson(Map<String, dynamic> json) {
    return LocalConversation(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      title: json['title'] as String? ?? 'Чат',
      clientPhone: json['clientPhone'] as String? ?? '',
      masterPhone: json['masterPhone'] as String? ?? '',
      masterName: json['masterName'] as String?,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => LocalChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class OrderWorkflowEntry {
  const OrderWorkflowEntry({
    required this.orderId,
    required this.title,
    required this.description,
    required this.address,
    required this.price,
    required this.clientName,
    required this.clientPhone,
    required this.masterName,
    required this.masterPhone,
    required this.statusCode,
    this.declineReason,
    this.conversationId,
    this.scheduledDate,
    this.scheduledTime,
    required this.createdAt,
    required this.updatedAt,
  });

  final String orderId;
  final String title;
  final String description;
  final String address;
  final double price;
  final String clientName;
  final String clientPhone;
  final String masterName;
  final String masterPhone;
  final int statusCode;
  final String? declineReason;
  final String? conversationId;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPendingMaster => statusCode == 3;
  bool get isMasterAccepted => statusCode == 4;
  bool get isDeclined => statusCode == 7;

  OrderWorkflowEntry copyWith({
    int? statusCode,
    String? declineReason,
    String? conversationId,
    DateTime? updatedAt,
  }) {
    return OrderWorkflowEntry(
      orderId: orderId,
      title: title,
      description: description,
      address: address,
      price: price,
      clientName: clientName,
      clientPhone: clientPhone,
      masterName: masterName,
      masterPhone: masterPhone,
      statusCode: statusCode ?? this.statusCode,
      declineReason: declineReason ?? this.declineReason,
      conversationId: conversationId ?? this.conversationId,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'title': title,
        'description': description,
        'address': address,
        'price': price,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'masterName': masterName,
        'masterPhone': masterPhone,
        'statusCode': statusCode,
        'declineReason': declineReason,
        'conversationId': conversationId,
        'scheduledDate': scheduledDate?.toIso8601String(),
        'scheduledTime': scheduledTime,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OrderWorkflowEntry.fromJson(Map<String, dynamic> json) {
    return OrderWorkflowEntry(
      orderId: json['orderId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      clientName: json['clientName'] as String? ?? 'Клиент',
      clientPhone: json['clientPhone'] as String? ?? '',
      masterName: json['masterName'] as String? ?? 'Мастер',
      masterPhone: json['masterPhone'] as String? ?? '',
      statusCode: json['statusCode'] as int? ?? 1,
      declineReason: json['declineReason'] as String?,
      conversationId: json['conversationId'] as String?,
      scheduledDate: DateTime.tryParse(json['scheduledDate'] as String? ?? ''),
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OrderWorkflowState {
  const OrderWorkflowState({
    this.orders = const {},
    this.conversations = const {},
  });

  final Map<String, OrderWorkflowEntry> orders;
  final Map<String, LocalConversation> conversations;

  OrderWorkflowState copyWith({
    Map<String, OrderWorkflowEntry>? orders,
    Map<String, LocalConversation>? conversations,
  }) {
    return OrderWorkflowState(
      orders: orders ?? this.orders,
      conversations: conversations ?? this.conversations,
    );
  }

  Map<String, dynamic> toJson() => {
        'orders': orders.map((k, v) => MapEntry(k, v.toJson())),
        'conversations':
            conversations.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory OrderWorkflowState.fromJson(Map<String, dynamic> json) {
    final ordersMap = <String, OrderWorkflowEntry>{};
    final rawOrders = json['orders'];
    if (rawOrders is Map) {
      for (final entry in rawOrders.entries) {
        ordersMap[entry.key.toString()] = OrderWorkflowEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    final chatsMap = <String, LocalConversation>{};
    final rawChats = json['conversations'];
    if (rawChats is Map) {
      for (final entry in rawChats.entries) {
        chatsMap[entry.key.toString()] = LocalConversation.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    return OrderWorkflowState(orders: ordersMap, conversations: chatsMap);
  }
}
