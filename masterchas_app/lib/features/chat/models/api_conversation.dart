class ApiConversation {
  const ApiConversation({
    required this.id,
    required this.title,
    required this.type,
    required this.participantUserIds,
    this.orderId,
    this.isLocal = false,
    this.peerName,
    this.peerPhone,
    this.orderTitle,
    this.orderStatus,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageType,
    this.unreadCount = 0,
  });

  final String id;
  final String title;
  final String type;
  final List<String> participantUserIds;
  final String? orderId;
  final bool isLocal;

  /// Имя собеседника (из его профиля на сервере) или его номер телефона.
  final String? peerName;
  final String? peerPhone;
  final String? orderTitle;
  final int? orderStatus;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int? lastMessageType;

  /// Непрочитанные сообщения собеседника (как счётчик в Instagram).
  final int unreadCount;

  /// Что показывать в заголовке чата.
  String get displayName {
    final name = peerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return title;
  }

  factory ApiConversation.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Чат';
    // Сервер называет чат заказа «Заказ xxxxxxxx» (первые 8 символов id заказа).
    // Если orderId не пришёл явно — берём этот префикс, чтобы связать чат с заказом.
    final explicitOrderId = json['orderId']?.toString();
    final prefix = RegExp(r'([0-9a-fA-F]{8})').firstMatch(title)?.group(1);
    return ApiConversation(
      id: json['id']?.toString() ?? '',
      title: title,
      type: json['conversationType']?.toString() ?? 'Direct',
      participantUserIds: (json['participantUserIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      orderId: (explicitOrderId != null && explicitOrderId.isNotEmpty)
          ? explicitOrderId
          : prefix?.toLowerCase(),
      peerName: json['peerName'] as String?,
      peerPhone: json['peerPhone'] as String?,
      orderTitle: json['orderTitle'] as String?,
      orderStatus: (json['orderStatus'] as num?)?.toInt(),
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())?.toLocal()
          : null,
      lastMessageType: (json['lastMessageType'] as num?)?.toInt(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Относится ли этот чат к заказу [orderId] (полный id или его префикс).
  bool matchesOrder(String orderId) {
    final mine = orderId.trim().toLowerCase();
    final theirs = this.orderId?.trim().toLowerCase();
    if (theirs == null || theirs.isEmpty || mine.isEmpty) return false;
    return mine == theirs || mine.startsWith(theirs) || theirs.startsWith(mine);
  }
}

class ApiMessage {
  const ApiMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.text,
    required this.createdAt,
    this.messageType = 1,
  });

  final String id;
  final String conversationId;
  final String senderUserId;
  final String text;
  final DateTime? createdAt;

  /// 1 — текст, 2 — фото, 3 — файл, 4 — системное, 5 — геолокация.
  final int messageType;

  factory ApiMessage.fromJson(Map<String, dynamic> json) {
    return ApiMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      messageType: _parseMessageType(json['messageType']),
    );
  }

  static int _parseMessageType(dynamic raw) {
    if (raw is num) return raw.toInt();
    return switch (raw?.toString().toLowerCase()) {
      'image' => 2,
      'file' => 3,
      'system' => 4,
      'location' => 5,
      'voice' => 6,
      _ => 1,
    };
  }
}
