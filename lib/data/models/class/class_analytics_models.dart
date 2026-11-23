int _asInt(Object? v, [int fallback = 0]) => (v as num?)?.toInt() ?? fallback;
double? _asDoubleOrNull(Object? v) => (v as num?)?.toDouble();

class ReviewWorkloadModel {
  final DateTime day;
  final int count;

  ReviewWorkloadModel({required this.day, required this.count});

  factory ReviewWorkloadModel.fromJson(Map<String, dynamic> json) {
    return ReviewWorkloadModel(day: DateTime.parse(json['day']), count: _asInt(json['count']));
  }

  /// BE chỉ trả những ngày có thẻ, không gồm thẻ quá hạn. Điền `count: 0` cho đủ 7 ngày
  /// bắt đầu từ hôm nay (theo giờ máy) để biểu đồ luôn có 7 cột.
  static List<ReviewWorkloadModel> fillNext7Days(
    List<ReviewWorkloadModel> items, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final date = DateTime(start.year, start.month, start.day + i);
      var count = 0;
      for (final item in items) {
        final local = item.day.toLocal();
        if (local.year == date.year && local.month == date.month && local.day == date.day) {
          count += item.count;
        }
      }
      return ReviewWorkloadModel(day: date, count: count);
    });
  }
}

class HardestCardModel {
  final String cardId;
  final String frontText;
  final String backText;
  final String? deckId;
  final String? deckName;
  final int wrongCount;

  /// Số học viên khác nhau từng sai (= 1 khi xem một người).
  final int studentCount;

  HardestCardModel({
    required this.cardId,
    required this.frontText,
    this.backText = '',
    this.deckId,
    this.deckName,
    required this.wrongCount,
    this.studentCount = 0,
  });

  factory HardestCardModel.fromJson(Map<String, dynamic> json) {
    return HardestCardModel(
      cardId: json['cardId'] as String? ?? '',
      frontText: json['frontText'] as String? ?? '',
      backText: json['backText'] as String? ?? '',
      deckId: json['deckId'] as String?,
      deckName: json['deckName'] as String?,
      wrongCount: _asInt(json['wrongCount']),
      studentCount: _asInt(json['studentCount']),
    );
  }
}

class AssignmentProgressModel {
  /// scheduled | pending | in_progress | completed | overdue | skipped
  final String status;
  final int count;

  AssignmentProgressModel({required this.status, required this.count});

  factory AssignmentProgressModel.fromJson(Map<String, dynamic> json) {
    return AssignmentProgressModel(
      status: json['status'] as String? ?? '',
      count: _asInt(json['count']),
    );
  }
}

/// Một học viên trong roster của bài giao (drill-down / submissions / kết quả của học viên).
class AssignmentDrillDownModel {
  final String userId;
  final String fullName;
  final String? email;

  /// scheduled | pending | in_progress | completed | overdue | skipped
  final String status;

  /// Chỉ bài học.
  final int? targetCount;
  final int? progressCount;

  /// Chỉ bài kiểm tra (giảng viên luôn thấy điểm).
  final double? scorePercentage;
  final double? bestScore;
  final double? lastScore;
  final double? firstScore;
  final int attemptsCount;
  final DateTime? completedAt;
  final String? testAttemptId;
  final bool isLate;

  AssignmentDrillDownModel({
    required this.userId,
    required this.fullName,
    this.email,
    required this.status,
    this.targetCount,
    this.progressCount,
    this.scorePercentage,
    this.bestScore,
    this.lastScore,
    this.firstScore,
    this.attemptsCount = 0,
    this.completedAt,
    this.testAttemptId,
    this.isLate = false,
  });

  factory AssignmentDrillDownModel.fromJson(Map<String, dynamic> json) {
    return AssignmentDrillDownModel(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      status: json['status'] as String? ?? '',
      targetCount: (json['targetCount'] as num?)?.toInt(),
      progressCount: (json['progressCount'] as num?)?.toInt(),
      scorePercentage: _asDoubleOrNull(json['scorePercentage']),
      bestScore: _asDoubleOrNull(json['bestScore']),
      lastScore: _asDoubleOrNull(json['lastScore']),
      firstScore: _asDoubleOrNull(json['firstScore']),
      attemptsCount: _asInt(json['attemptsCount']),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      testAttemptId: json['testAttemptId'] as String?,
      isLate: json['isLate'] as bool? ?? false,
    );
  }
}

class DeckHealthStateCount {
  /// new | learning | review | relearning | mastered
  final String state;
  final int count;

  const DeckHealthStateCount({required this.state, required this.count});

  factory DeckHealthStateCount.fromJson(Map<String, dynamic> json) {
    return DeckHealthStateCount(
      state: json['state'] as String? ?? '',
      count: _asInt(json['count']),
    );
  }
}

/// `GET /analytics/classes/:id/deck-health` (BE trả OBJECT, trước đây là mảng).
/// Đơn vị là CẶP (học viên, thẻ) nên tổng = `totalCards × studentCount`.
class DeckHealthResponse {
  /// class | self | student
  final String scope;
  final String? studentId;
  final String? deckId;
  final int totalCards;
  final int studentCount;
  final List<DeckHealthStateCount> states;

  /// Độ nhớ trung bình R (0..1); null khi chưa ai học.
  final double? avgRetrievability;

  /// Độ bền trung bình S (ngày); null khi chưa ai học.
  final double? avgStabilityDays;
  final int atRiskCount;
  final double atRiskThreshold;

  const DeckHealthResponse({
    this.scope = 'class',
    this.studentId,
    this.deckId,
    this.totalCards = 0,
    this.studentCount = 0,
    this.states = const [],
    this.avgRetrievability,
    this.avgStabilityDays,
    this.atRiskCount = 0,
    this.atRiskThreshold = 0.7,
  });

  factory DeckHealthResponse.fromJson(Map<String, dynamic> json) {
    return DeckHealthResponse(
      scope: json['scope'] as String? ?? 'class',
      studentId: json['studentId'] as String?,
      deckId: json['deckId'] as String?,
      totalCards: _asInt(json['totalCards']),
      studentCount: _asInt(json['studentCount']),
      states:
          (json['states'] as List<dynamic>?)
              ?.map((e) => DeckHealthStateCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      avgRetrievability: _asDoubleOrNull(json['avgRetrievability']),
      avgStabilityDays: _asDoubleOrNull(json['avgStabilityDays']),
      atRiskCount: _asInt(json['atRiskCount']),
      atRiskThreshold: _asDoubleOrNull(json['atRiskThreshold']) ?? 0.7,
    );
  }

  int countOf(String state) {
    for (final s in states) {
      if (s.state == state) return s.count;
    }
    return 0;
  }

  /// Tổng số cặp (học viên, thẻ).
  int get totalPairs => states.fold(0, (sum, s) => sum + s.count);

  /// Số cặp đã học (khác `new`) – mẫu số của tỉ lệ nguy cơ quên.
  int get learnedPairs => totalPairs - countOf('new');

  /// Tỉ lệ nguy cơ quên trên các cặp đã học (0..1).
  double get atRiskRatio => learnedPairs <= 0 ? 0 : (atRiskCount / learnedPairs).clamp(0.0, 1.0);

  bool get isEmpty => totalPairs == 0;
}

class ScoreBucket {
  final int from;
  final int to;
  final int count;

  const ScoreBucket({required this.from, required this.to, required this.count});

  factory ScoreBucket.fromJson(Map<String, dynamic> json) {
    return ScoreBucket(
      from: _asInt(json['from']),
      to: _asInt(json['to']),
      count: _asInt(json['count']),
    );
  }
}

/// `GET /analytics/classes/:id/assignments/:aid/score-distribution` (chỉ bài kiểm tra).
class ScoreDistribution {
  final String assignmentId;
  final String title;
  final int totalStudents;
  final int submittedCount;
  final int notSubmittedCount;
  final double? averageScore;
  final double? medianScore;
  final double? minScore;
  final double? maxScore;
  final List<ScoreBucket> buckets;

  const ScoreDistribution({
    this.assignmentId = '',
    this.title = '',
    this.totalStudents = 0,
    this.submittedCount = 0,
    this.notSubmittedCount = 0,
    this.averageScore,
    this.medianScore,
    this.minScore,
    this.maxScore,
    this.buckets = const [],
  });

  factory ScoreDistribution.fromJson(Map<String, dynamic> json) {
    return ScoreDistribution(
      assignmentId: json['assignmentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      totalStudents: _asInt(json['totalStudents']),
      submittedCount: _asInt(json['submittedCount']),
      notSubmittedCount: _asInt(json['notSubmittedCount']),
      averageScore: _asDoubleOrNull(json['averageScore']),
      medianScore: _asDoubleOrNull(json['medianScore']),
      minScore: _asDoubleOrNull(json['minScore']),
      maxScore: _asDoubleOrNull(json['maxScore']),
      buckets:
          (json['buckets'] as List<dynamic>?)
              ?.map((e) => ScoreBucket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Một lượt làm bài của học viên trong một bài giao (điểm của TỪNG lượt).
class StudentAttemptModel {
  final String attemptId;
  final int attemptNo;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final int durationMs;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const StudentAttemptModel({
    required this.attemptId,
    required this.attemptNo,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.durationMs,
    this.startedAt,
    this.completedAt,
  });

  factory StudentAttemptModel.fromJson(Map<String, dynamic> json) {
    return StudentAttemptModel(
      attemptId: json['attemptId'] as String? ?? '',
      attemptNo: _asInt(json['attemptNo'], 1),
      totalQuestions: _asInt(json['totalQuestions']),
      correctAnswers: _asInt(json['correctAnswers']),
      scorePercentage: _asDoubleOrNull(json['scorePercentage']) ?? 0,
      durationMs: _asInt(json['durationMs']),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
    );
  }
}

/// `GET /analytics/classes/:id/students/:userId/assignments`.
class StudentAssignmentResult {
  final String assignmentId;
  final String title;

  /// study_mission | graded_test
  final String type;

  /// running | ended | scheduled
  final String phase;
  final DateTime? startAt;
  final DateTime? endAt;
  final AssignmentDrillDownModel result;

  const StudentAssignmentResult({
    required this.assignmentId,
    required this.title,
    required this.type,
    required this.phase,
    this.startAt,
    this.endAt,
    required this.result,
  });

  bool get isTest => type == 'graded_test';

  factory StudentAssignmentResult.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentResult(
      assignmentId: json['assignmentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'study_mission',
      phase: json['phase'] as String? ?? 'running',
      startAt: DateTime.tryParse(json['startAt']?.toString() ?? ''),
      endAt: DateTime.tryParse(json['endAt']?.toString() ?? ''),
      result: AssignmentDrillDownModel.fromJson(
        (json['result'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
