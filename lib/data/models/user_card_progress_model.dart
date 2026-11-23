import 'enums.dart';

class UserCardProgressModel {
  final String id;
  final String userId;
  final String cardId;
  final CardState state;
  final double difficulty;
  final double? stability;
  final DateTime? dueDate;
  final DateTime? lastReview;
  final double? scheduledDays;

  UserCardProgressModel({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.state,
    this.difficulty = 4.0,
    this.stability,
    this.dueDate,
    this.lastReview,
    this.scheduledDays,
  });

  factory UserCardProgressModel.fromJson(Map<String, dynamic> json) {
    return UserCardProgressModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      cardId: json['cardId'] as String? ?? json['card_id'] as String? ?? '',
      state: CardState.fromString(json['state'] as String?),
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 4.0,
      stability: (json['stability'] as num?)?.toDouble(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : (json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null),
      lastReview: json['lastReview'] != null
          ? DateTime.tryParse(json['lastReview'].toString())
          : (json['last_review'] != null
                ? DateTime.tryParse(json['last_review'].toString())
                : null),
      scheduledDays:
          (json['scheduledDays'] as num?)?.toDouble() ??
          (json['scheduled_days'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardId': cardId,
      'state': state.toJson(),
      'difficulty': difficulty,
      if (stability != null) 'stability': stability,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (lastReview != null) 'lastReview': lastReview!.toIso8601String(),
      if (scheduledDays != null) 'scheduledDays': scheduledDays,
    };
  }

  UserCardProgressModel copyWith({
    String? id,
    String? userId,
    String? cardId,
    CardState? state,
    double? difficulty,
    double? stability,
    DateTime? dueDate,
    DateTime? lastReview,
    double? scheduledDays,
  }) {
    return UserCardProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      state: state ?? this.state,
      difficulty: difficulty ?? this.difficulty,
      stability: stability ?? this.stability,
      dueDate: dueDate ?? this.dueDate,
      lastReview: lastReview ?? this.lastReview,
      scheduledDays: scheduledDays ?? this.scheduledDays,
    );
  }
}
