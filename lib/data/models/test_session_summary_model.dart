import 'package:equatable/equatable.dart';

/// Phiên làm bài kiểm tra đang dở (`GET /tests/sessions`, và phần tử `sessionKind: "test"` của Home).
class TestSessionSummary extends Equatable {
  final String sessionId;

  /// `personal` (đề cá nhân) hoặc `assignment` (bài giao của lớp).
  final String kind;
  final String testId;
  final String name;
  final String? assignmentId;
  final String? assignmentTitle;
  final String? classId;
  final String? className;
  final int totalQuestions;
  final int answeredCount;
  final int elapsedSeconds;
  final int timeLimitSeconds;
  final DateTime? expiresAt;
  final int? remainingSeconds;
  final DateTime? updatedAt;

  const TestSessionSummary({
    required this.sessionId,
    required this.kind,
    required this.testId,
    required this.name,
    this.assignmentId,
    this.assignmentTitle,
    this.classId,
    this.className,
    this.totalQuestions = 0,
    this.answeredCount = 0,
    this.elapsedSeconds = 0,
    this.timeLimitSeconds = 0,
    this.expiresAt,
    this.remainingSeconds,
    this.updatedAt,
  });

  bool get isAssignment => kind == 'assignment';

  double get progress => totalQuestions > 0 ? (answeredCount / totalQuestions).clamp(0.0, 1.0) : 0;

  /// Tên hiển thị: bài giao của lớp ưu tiên tiêu đề bài giao.
  String get displayName =>
      isAssignment && (assignmentTitle?.isNotEmpty ?? false) ? assignmentTitle! : name;

  factory TestSessionSummary.fromJson(Map<String, dynamic> json) {
    return TestSessionSummary(
      sessionId: json['sessionId'] as String? ?? '',
      kind: json['kind'] as String? ?? 'personal',
      testId: json['testId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assignmentId: json['assignmentId'] as String?,
      assignmentTitle: json['assignmentTitle'] as String?,
      classId: json['classId'] as String?,
      className: json['className'] as String?,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      answeredCount: (json['answeredCount'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    kind,
    testId,
    name,
    assignmentId,
    assignmentTitle,
    classId,
    className,
    totalQuestions,
    answeredCount,
    elapsedSeconds,
    timeLimitSeconds,
    expiresAt,
    remainingSeconds,
    updatedAt,
  ];
}
