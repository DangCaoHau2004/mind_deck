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
      currentStreak: json['currentStreak'] as int? ?? json['current_streak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? json['max_streak'] as int? ?? 0,
      lastStudyAt: DateTime.tryParse(
        json['lastStudyAt']?.toString() ?? json['last_study_at']?.toString() ?? '',
      ),
      isIntact: json['isIntact'] as bool? ?? json['is_intact'] as bool? ?? false,
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
    return HeatmapStats(date: json['date'] as String? ?? '', count: json['count'] as int? ?? 0);
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
  final String deckId;
  final String deckName;

  /// `null` = thẻ cá nhân; khác null = thẻ của lớp [className].
  final String? classId;
  final String? className;

  DifficultCardStats({
    required this.cardId,
    required this.frontText,
    required this.difficulty,
    this.deckId = '',
    this.deckName = '',
    this.classId,
    this.className,
  });

  factory DifficultCardStats.fromJson(Map<String, dynamic> json) {
    return DifficultCardStats(
      cardId: json['cardId'] as String? ?? json['card_id'] as String? ?? '',
      frontText: json['frontText'] as String? ?? json['front_text'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
      deckId: json['deckId'] as String? ?? '',
      deckName: json['deckName'] as String? ?? '',
      classId: json['classId'] as String?,
      className: json['className'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'frontText': frontText,
      'difficulty': difficulty,
      'deckId': deckId,
      'deckName': deckName,
      'classId': classId,
      'className': className,
    };
  }
}

/// Độ nhớ trung bình (R, S) và số thẻ nguy cơ quên. R/S `null` khi chưa học thẻ nào.
class MemoryStats {
  final double? avgRetrievability;
  final double? avgStabilityDays;
  final int atRiskCount;
  final double atRiskThreshold;
  final int reviewedCards;

  const MemoryStats({
    this.avgRetrievability,
    this.avgStabilityDays,
    this.atRiskCount = 0,
    this.atRiskThreshold = 0.7,
    this.reviewedCards = 0,
  });

  factory MemoryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MemoryStats();
    return MemoryStats(
      avgRetrievability: (json['avgRetrievability'] as num?)?.toDouble(),
      avgStabilityDays: (json['avgStabilityDays'] as num?)?.toDouble(),
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
      // Ngưỡng do BE trả về, không hardcode.
      atRiskThreshold: (json['atRiskThreshold'] as num?)?.toDouble() ?? 0.7,
      reviewedCards: (json['reviewedCards'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Thẻ đến hạn: hôm nay và quá hạn (không tính thẻ đã thuộc).
class DueNowStats {
  final int dueToday;
  final int overdue;
  final int total;

  const DueNowStats({this.dueToday = 0, this.overdue = 0, this.total = 0});

  factory DueNowStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DueNowStats();
    return DueNowStats(
      dueToday: (json['dueToday'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Tiến độ bài học: `done/target` (thẻ khác nhau đã ôn / mục tiêu riêng).
class AssignmentProgress {
  final int done;
  final int target;

  const AssignmentProgress({required this.done, required this.target});

  factory AssignmentProgress.fromJson(Map<String, dynamic> json) {
    return AssignmentProgress(
      done: (json['done'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Bài giao chưa xong trong 7 ngày tới. `type`: study_mission | graded_test.
class OpenAssignmentModel {
  final String assignmentId;
  final String classId;
  final String className;
  final String title;
  final String type;
  final DateTime endAt;
  final bool endsToday;

  /// pending | in_progress
  final String status;

  /// `null` với bài kiểm tra.
  final AssignmentProgress? progress;

  const OpenAssignmentModel({
    required this.assignmentId,
    required this.classId,
    required this.className,
    required this.title,
    required this.type,
    required this.endAt,
    required this.endsToday,
    required this.status,
    this.progress,
  });

  bool get isTest => type == 'graded_test';

  factory OpenAssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    return OpenAssignmentModel(
      assignmentId: json['assignmentId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'study_mission',
      endAt: DateTime.tryParse(json['endAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      endsToday: json['endsToday'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      progress: rawProgress is Map<String, dynamic>
          ? AssignmentProgress.fromJson(rawProgress)
          : null,
    );
  }
}

class AssignmentsOverview {
  final int dueTodayCount;
  final int totalCount;
  final List<OpenAssignmentModel> items;

  const AssignmentsOverview({this.dueTodayCount = 0, this.totalCount = 0, this.items = const []});

  /// Số bài chưa được hiện trong danh sách (BE chỉ trả tối đa 10 bài).
  int get hiddenCount => totalCount > items.length ? totalCount - items.length : 0;

  factory AssignmentsOverview.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AssignmentsOverview();
    return AssignmentsOverview(
      dueTodayCount: (json['dueTodayCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(OpenAssignmentModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

class StatsOverviewModel {
  final StreakStats streak;
  final List<HeatmapStats> heatmap;
  final List<AccuracyStats> accuracy;
  final List<FutureReviewStats> futureReviews;
  final List<DifficultCardStats> difficultCards;
  final MemoryStats memory;

  /// Phân bố trạng thái FSRS của mọi thẻ (thẻ chưa học = `new`). Cùng khóa với [FSRSStatsModel].
  final FSRSStatsModel cardStates;
  final DueNowStats dueNow;
  final int studiedToday;
  final AssignmentsOverview assignments;

  StatsOverviewModel({
    required this.streak,
    required this.heatmap,
    required this.accuracy,
    required this.futureReviews,
    required this.difficultCards,
    this.memory = const MemoryStats(),
    required this.cardStates,
    this.dueNow = const DueNowStats(),
    this.studiedToday = 0,
    this.assignments = const AssignmentsOverview(),
  });

  factory StatsOverviewModel.fromJson(Map<String, dynamic> json) {
    return StatsOverviewModel(
      streak: StreakStats.fromJson(json['streak'] as Map<String, dynamic>? ?? {}),
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
              ?.map((e) => FutureReviewStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['future_reviews'] as List<dynamic>?)
              ?.map((e) => FutureReviewStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      difficultCards:
          (json['difficultCards'] as List<dynamic>?)
              ?.map((e) => DifficultCardStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['difficult_cards'] as List<dynamic>?)
              ?.map((e) => DifficultCardStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      memory: MemoryStats.fromJson(json['memory'] as Map<String, dynamic>?),
      cardStates: FSRSStatsModel.fromJson(json['cardStates'] as Map<String, dynamic>? ?? const {}),
      dueNow: DueNowStats.fromJson(json['dueNow'] as Map<String, dynamic>?),
      studiedToday: (json['studiedToday'] as num?)?.toInt() ?? 0,
      assignments: AssignmentsOverview.fromJson(json['assignments'] as Map<String, dynamic>?),
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
