class ReviewLogModel {
  final String id;
  final String userId;
  final String cardId;
  final int grade; // 1 to 4
  final int durationMs;
  final DateTime reviewTimestamp;

  ReviewLogModel({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.grade,
    required this.durationMs,
    required this.reviewTimestamp,
  });

  factory ReviewLogModel.fromJson(Map<String, dynamic> json) {
    return ReviewLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      cardId: json['cardId'] as String? ?? json['card_id'] as String? ?? '',
      grade: json['grade'] as int? ?? 1,
      durationMs: json['durationMs'] as int? ?? json['duration_ms'] as int? ?? 0,
      reviewTimestamp:
          DateTime.tryParse(
            json['reviewTimestamp']?.toString() ?? json['review_timestamp']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardId': cardId,
      'grade': grade,
      'durationMs': durationMs,
      'reviewTimestamp': reviewTimestamp.toIso8601String(),
    };
  }

  ReviewLogModel copyWith({
    String? id,
    String? userId,
    String? cardId,
    int? grade,
    int? durationMs,
    DateTime? reviewTimestamp,
  }) {
    return ReviewLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      grade: grade ?? this.grade,
      durationMs: durationMs ?? this.durationMs,
      reviewTimestamp: reviewTimestamp ?? this.reviewTimestamp,
    );
  }
}
