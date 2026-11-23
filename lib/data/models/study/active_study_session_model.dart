import 'package:equatable/equatable.dart';

/// Phiên học flashcard đang dở (`GET /study/active`, và phần tử `sessionKind: "study"` của Home).
class ActiveStudySession extends Equatable {
  final String sessionId;

  /// `deck` (học theo bộ thẻ) hoặc `cards` (nhiều nguồn, từ Ôn tập / "Học nhanh").
  final String type;
  final String? deckId;
  final String? deckName;
  final int totalCards;

  /// Chỉ tính tới lần lưu tiến trình gần nhất.
  final int learnedCount;
  final int elapsedSeconds;
  final int timeLimitSeconds;
  final DateTime? updatedAt;

  const ActiveStudySession({
    required this.sessionId,
    required this.type,
    this.deckId,
    this.deckName,
    this.totalCards = 0,
    this.learnedCount = 0,
    this.elapsedSeconds = 0,
    this.timeLimitSeconds = 0,
    this.updatedAt,
  });

  bool get isDeck => type == 'deck' && (deckId?.isNotEmpty ?? false);

  double get progress => totalCards > 0 ? (learnedCount / totalCards).clamp(0.0, 1.0) : 0;

  factory ActiveStudySession.fromJson(Map<String, dynamic> json) {
    return ActiveStudySession(
      sessionId: json['sessionId'] as String? ?? '',
      type: json['type'] as String? ?? 'cards',
      deckId: json['deckId'] as String?,
      deckName: json['deckName'] as String?,
      totalCards: (json['totalCards'] as num?)?.toInt() ?? 0,
      learnedCount: (json['learnedCount'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    type,
    deckId,
    deckName,
    totalCards,
    learnedCount,
    elapsedSeconds,
    timeLimitSeconds,
    updatedAt,
  ];
}
