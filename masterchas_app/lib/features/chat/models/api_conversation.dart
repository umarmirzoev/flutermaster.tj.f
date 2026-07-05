class ApiConversation {
  const ApiConversation({
    required this.id,
    required this.title,
    required this.type,
    required this.participantUserIds,
    this.orderId,
    this.isLocal = false,
  });

  final String id;
  final String title;
  final String type;
  final List<String> participantUserIds;
  final String? orderId;
  final bool isLocal;

  factory ApiConversation.fromJson(Map<String, dynamic> json) {
    return ApiConversation(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Чат',
      type: json['conversationType']?.toString() ?? 'Direct',
      participantUserIds: (json['participantUserIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      orderId: json['orderId']?.toString(),
    );
  }
}

class ApiMessage {
  const ApiMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderUserId;
  final String text;
  final DateTime? createdAt;

  factory ApiMessage.fromJson(Map<String, dynamic> json) {
    return ApiMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderUserId: json['senderUserId']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
