import '../flashcard_model.dart';

class StudySessionModel {
  final String sessionId;
  final String deckId;
  final List<Map<String, dynamic>> reviewLogs;
  final List<FlashcardModel> cards;

  StudySessionModel({
    required this.sessionId,
    required this.deckId,
    required this.reviewLogs,
    required this.cards,
  });

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['reviewLogs'] as List<dynamic>? ?? [];
    final rawCards = json['cards'] as List<dynamic>? ?? [];

    return StudySessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      deckId: json['deckId'] as String? ?? '',
      reviewLogs: rawLogs
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      cards: rawCards.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'deckId': deckId,
      'reviewLogs': reviewLogs,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}
