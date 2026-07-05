class MasterReview {
  const MasterReview({
    required this.id,
    required this.masterKey,
    required this.authorName,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.clientPhone,
  });

  final String id;
  final String masterKey;
  final String authorName;
  final int rating;
  final String body;
  final DateTime createdAt;
  final String? clientPhone;

  String get dateLabel {
    final d = createdAt;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'masterKey': masterKey,
        'authorName': authorName,
        'rating': rating,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        if (clientPhone != null) 'clientPhone': clientPhone,
      };

  factory MasterReview.fromJson(Map<String, dynamic> json) {
    return MasterReview(
      id: json['id'] as String,
      masterKey: json['masterKey'] as String,
      authorName: json['authorName'] as String,
      rating: (json['rating'] as num).toInt(),
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      clientPhone: json['clientPhone'] as String?,
    );
  }
}

class MasterReviewStats {
  const MasterReviewStats({
    required this.count,
    required this.averageRating,
  });

  final int count;
  final double averageRating;
}
