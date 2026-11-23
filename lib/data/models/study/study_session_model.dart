import '../flashcard_model.dart';

class StudySessionModel {
  /// Rỗng khi học thử (BE trả `sessionId: null`).
  final String sessionId;
  final String deckId;

  /// Học thử deck công khai/được chia sẻ của người khác: không lưu tiến trình, không ghi FSRS.
  final bool readOnly;

  /// BE trả lại phiên đang dở của deck thay vì tạo mới (`POST /study/start` theo `deckId`).
  final bool resumed;
  final int timeLimitSeconds;
  final int elapsedSeconds;
  final List<Map<String, dynamic>> reviewLogs;
  final List<FlashcardModel> cards;

  StudySessionModel({
    required this.sessionId,
    required this.deckId,
    this.readOnly = false,
    this.resumed = false,
    this.timeLimitSeconds = 0,
    this.elapsedSeconds = 0,
    required this.reviewLogs,
    required this.cards,
  });

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['reviewLogs'] as List<dynamic>? ?? [];
    final rawCards = json['cards'] as List<dynamic>? ?? [];

    return StudySessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      deckId: json['deckId'] as String? ?? '',
      readOnly:
          json['readOnly'] == true || (json.containsKey('sessionId') && json['sessionId'] == null),
      resumed: json['resumed'] == true,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? json['time_limit_seconds'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? json['elapsed_seconds'] as int? ?? 0,
      reviewLogs: rawLogs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      cards: rawCards.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'deckId': deckId,
      'readOnly': readOnly,
      'resumed': resumed,
      'timeLimitSeconds': timeLimitSeconds,
      'elapsedSeconds': elapsedSeconds,
      'reviewLogs': reviewLogs,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}
