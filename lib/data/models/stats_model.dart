class FSRSStatsModel {
  final int newCards;
  final int learning;
  final int review;
  final int relearning;
  final int mastered;
  final int total;

  FSRSStatsModel({
    required this.newCards,
    required this.learning,
    required this.review,
    required this.relearning,
    required this.mastered,
    required this.total,
  });

  factory FSRSStatsModel.fromJson(Map<String, dynamic> json) {
    return FSRSStatsModel(
      newCards: json['new'] as int? ?? 0,
      learning: json['learning'] as int? ?? 0,
      review: json['review'] as int? ?? 0,
      relearning: json['relearning'] as int? ?? 0,
      mastered: json['mastered'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new': newCards,
      'learning': learning,
      'review': review,
      'relearning': relearning,
      'mastered': mastered,
      'total': total,
    };
  }
}

class StreakStats {
  final int currentStreak;
  final int maxStreak;
  final DateTime? lastStudyAt;
  final bool isIntact;

  StreakStats({
    required this.currentStreak,
    required this.maxStreak,
    this.lastStudyAt,
    required this.isIntact,
  });

  factory StreakStats.fromJson(Map<String, dynamic> json) {
    return StreakStats(
      currentStreak:
          json['currentStreak'] as int? ?? json['current_streak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? json['max_streak'] as int? ?? 0,
      lastStudyAt: DateTime.tryParse(
        json['lastStudyAt']?.toString() ??
            json['last_study_at']?.toString() ??
            '',
      ),
      isIntact:
          json['isIntact'] as bool? ?? json['is_intact'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      if (lastStudyAt != null) 'lastStudyAt': lastStudyAt!.toIso8601String(),
      'isIntact': isIntact,
    };
  }
}

class HeatmapStats {
  final String date;
  final int count;

  HeatmapStats({required this.date, required this.count});

  factory HeatmapStats.fromJson(Map<String, dynamic> json) {
    return HeatmapStats(
      date: json['date'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'count': count};
  }
}

class AccuracyStats {
  final String date;
  final double accuracy;

  AccuracyStats({required this.date, required this.accuracy});

  factory AccuracyStats.fromJson(Map<String, dynamic> json) {
    return AccuracyStats(
      date: json['date'] as String? ?? '',
      accuracy: json['accuracy'] != null
          ? double.tryParse(json['accuracy'].toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'accuracy': accuracy};
  }
}

class FutureReviewStats {
  final String date;
  final int dueCount;

  FutureReviewStats({required this.date, required this.dueCount});

  factory FutureReviewStats.fromJson(Map<String, dynamic> json) {
    return FutureReviewStats(
      date: json['date'] as String? ?? '',
      dueCount: json['dueCount'] as int? ?? json['due_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'dueCount': dueCount};
  }
}

class DifficultCardStats {
  final String cardId;
  final String frontText;
  final double difficulty;

  DifficultCardStats({
    required this.cardId,
    required this.frontText,
    required this.difficulty,
  });

  factory DifficultCardStats.fromJson(Map<String, dynamic> json) {
    return DifficultCardStats(
      cardId: json['cardId'] as String? ?? json['card_id'] as String? ?? '',
      frontText:
          json['frontText'] as String? ?? json['front_text'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'cardId': cardId, 'frontText': frontText, 'difficulty': difficulty};
  }
}

class StatsOverviewModel {
  final StreakStats streak;
  final List<HeatmapStats> heatmap;
  final List<AccuracyStats> accuracy;
  final List<FutureReviewStats> futureReviews;
  final List<DifficultCardStats> difficultCards;

  StatsOverviewModel({
    required this.streak,
    required this.heatmap,
    required this.accuracy,
    required this.futureReviews,
    required this.difficultCards,
  });

  factory StatsOverviewModel.fromJson(Map<String, dynamic> json) {
    return StatsOverviewModel(
      streak: StreakStats.fromJson(
        json['streak'] as Map<String, dynamic>? ?? {},
      ),
      heatmap:
          (json['heatmap'] as List<dynamic>?)
              ?.map((e) => HeatmapStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      accuracy:
          (json['accuracy'] as List<dynamic>?)
              ?.map((e) => AccuracyStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      futureReviews:
          (json['futureReviews'] as List<dynamic>?)
              ?.map(
                (e) => FutureReviewStats.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          (json['future_reviews'] as List<dynamic>?)
              ?.map(
                (e) => FutureReviewStats.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      difficultCards:
          (json['difficultCards'] as List<dynamic>?)
              ?.map(
                (e) => DifficultCardStats.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          (json['difficult_cards'] as List<dynamic>?)
              ?.map(
                (e) => DifficultCardStats.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak.toJson(),
      'heatmap': heatmap.map((e) => e.toJson()).toList(),
      'accuracy': accuracy.map((e) => e.toJson()).toList(),
      'futureReviews': futureReviews.map((e) => e.toJson()).toList(),
      'difficultCards': difficultCards.map((e) => e.toJson()).toList(),
    };
  }
}
