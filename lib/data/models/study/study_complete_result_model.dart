class StudyCompleteResultModel {
  final String? sessionId;
  final String? deckId;
  final int totalCards;
  final int rememberedCount;
  final int forgotCount;
  final DateTime completedAt;

  StudyCompleteResultModel({
    this.sessionId,
    this.deckId,
    required this.totalCards,
    required this.rememberedCount,
    required this.forgotCount,
    required this.completedAt,
  });

  factory StudyCompleteResultModel.fromJson(Map<String, dynamic> json) {
    return StudyCompleteResultModel(
      sessionId: json['sessionId'] as String?,
      deckId: json['deckId'] as String?,
      totalCards: json['totalCards'] as int? ?? 0,
      rememberedCount: json['rememberedCount'] as int? ?? 0,
      forgotCount: json['forgotCount'] as int? ?? 0,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'sessionId': sessionId,
      if (deckId != null) 'deckId': deckId,
      'totalCards': totalCards,
      'rememberedCount': rememberedCount,
      'forgotCount': forgotCount,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
