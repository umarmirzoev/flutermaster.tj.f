class ApiOrder {
  const ApiOrder({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    required this.statusCode,
    required this.price,
    this.payableAmount,
    this.serviceId,
    this.acceptedAt,
    this.scheduledDate,
  });

  final String id;
  final String title;
  final String description;
  final String address;
  final String status;
  final int? statusCode;
  final double price;
  final double? payableAmount;
  final String? serviceId;
  final DateTime? acceptedAt;
  final String? scheduledDate;

  bool get isCancelled {
    if (statusCode == 7 || statusCode == 8) return true;
    final lower = status.toLowerCase();
    return lower.contains('cancel');
  }

  bool get isActive => !isCancelled && !status.toLowerCase().contains('completed');

  bool get isPendingMasterAccept => statusCode == 3;

  bool get isMasterAccepted => statusCode == 4;

  ApiOrder copyWith({
    String? title,
    String? description,
    String? address,
    String? status,
    int? statusCode,
    double? price,
  }) {
    return ApiOrder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      status: status ?? this.status,
      statusCode: statusCode ?? this.statusCode,
      price: price ?? this.price,
      payableAmount: payableAmount,
      serviceId: serviceId,
      acceptedAt: acceptedAt,
      scheduledDate: scheduledDate,
    );
  }

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final statusCode = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus?.toString() ?? '');

    return ApiOrder(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: rawStatus?.toString() ?? 'Created',
      statusCode: statusCode,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble(),
      serviceId: json['serviceId']?.toString(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'].toString())
          : null,
      scheduledDate: json['scheduledDate']?.toString(),
    );
  }
}
