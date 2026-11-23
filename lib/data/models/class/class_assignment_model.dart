import 'package:mind_deck/data/models/test_settings_model.dart';

enum AssignmentType {
  studyMission('study_mission'),
  gradedTest('graded_test');

  final String value;
  const AssignmentType(this.value);

  static AssignmentType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'graded_test':
        return AssignmentType.gradedTest;
      case 'study_mission':
      default:
        return AssignmentType.studyMission;
    }
  }

  String toJson() => value;
}

/// Trạng thái của MỘT học viên trên một bài giao.
enum AssignmentStatus {
  /// Bài chưa đến giờ bắt đầu.
  scheduled,
  pending,
  inProgress,
  completed,
  overdue,

  /// Học viên không còn thẻ phù hợp nên không được giao (không thông báo).
  skipped;

  static AssignmentStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'scheduled':
        return AssignmentStatus.scheduled;
      case 'in_progress':
        return AssignmentStatus.inProgress;
      case 'completed':
        return AssignmentStatus.completed;
      case 'overdue':
        return AssignmentStatus.overdue;
      case 'skipped':
        return AssignmentStatus.skipped;
      case 'pending':
      default:
        return AssignmentStatus.pending;
    }
  }

  String toJson() => switch (this) {
    AssignmentStatus.inProgress => 'in_progress',
    _ => name,
  };

  String get label => switch (this) {
    AssignmentStatus.scheduled => 'Chưa đến giờ',
    AssignmentStatus.pending => 'Chưa làm',
    AssignmentStatus.inProgress => 'Đang làm dở',
    AssignmentStatus.completed => 'Đã hoàn thành',
    AssignmentStatus.overdue => 'Quá hạn',
    AssignmentStatus.skipped => 'Không được giao',
  };
}

/// Giai đoạn của bài giao.
enum AssignmentPhase {
  scheduled,
  running,
  ended;

  static AssignmentPhase fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'scheduled':
        return AssignmentPhase.scheduled;
      case 'ended':
        return AssignmentPhase.ended;
      case 'running':
      default:
        return AssignmentPhase.running;
    }
  }

  String get label => switch (this) {
    AssignmentPhase.scheduled => 'Chưa bắt đầu',
    AssignmentPhase.running => 'Đang diễn ra',
    AssignmentPhase.ended => 'Đã kết thúc',
  };
}

/// Chế độ học của bài học: học mọi thẻ hay chỉ thẻ mới.
class AssignmentMode {
  AssignmentMode._();

  static const String allCards = 'all_cards';
  static const String newOnly = 'new_only';
}

/// Khối lượng của bài học: tất cả hoặc N thẻ.
class AssignmentScope {
  AssignmentScope._();

  static const String all = 'all';
  static const String count = 'count';
}

/// Nguồn thẻ của bài học: id BẢN SAO deck / folder của lớp (không có tên -> tra từ học liệu lớp).
class AssignmentSource {
  /// deck | folder
  final String type;
  final String id;

  const AssignmentSource({required this.type, required this.id});

  factory AssignmentSource.fromJson(Map<String, dynamic> json) =>
      AssignmentSource(type: json['type'] as String? ?? 'deck', id: json['id'] as String? ?? '');

  Map<String, dynamic> toJson() => {'type': type, 'id': id};

  bool get isFolder => type == 'folder';
}

/// `test{}` của bài kiểm tra (chỉ có ở danh sách bài giao).
class AssignmentTestInfo {
  final String id;
  final String name;

  /// auto | manual
  final String kind;

  /// Chỉ đề manual (đề auto là null).
  final int? questionCount;

  /// Số thẻ nguồn; đề auto số câu thực tế ≤ cardCount (ghép cặp gom tối đa 5 thẻ/câu).
  final int cardCount;
  final TestSettings settings;

  const AssignmentTestInfo({
    required this.id,
    required this.name,
    this.kind = 'auto',
    this.questionCount,
    this.cardCount = 0,
    this.settings = const TestSettings(),
  });

  factory AssignmentTestInfo.fromJson(Map<String, dynamic> json) => AssignmentTestInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    kind: json['kind'] as String? ?? 'auto',
    questionCount: (json['questionCount'] as num?)?.toInt(),
    cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
    settings: TestSettings.fromJson(json['settings'] as Map<String, dynamic>?),
  );
}

/// `my{}`: tiến độ của TÔI trên bài giao. null = không thuộc diện được giao
/// (giảng viên, hoặc học viên vào lớp sau `startAt`).
class AssignmentMine {
  final AssignmentStatus status;

  // Bài học
  final int? targetCount;

  /// Tên là `progress` ở danh sách bài giao (khác `progressCount` ở roster). Có thể vượt target.
  final int progress;

  // Bài kiểm tra
  /// null khi đề tắt `showScore`.
  final double? scorePercentage;
  final int attemptsCount;
  final int? attemptsAllowed;
  final int? attemptsLeft;
  final DateTime? completedAt;

  const AssignmentMine({
    required this.status,
    this.targetCount,
    this.progress = 0,
    this.scorePercentage,
    this.attemptsCount = 0,
    this.attemptsAllowed,
    this.attemptsLeft,
    this.completedAt,
  });

  /// Tiến độ đã giới hạn trong [0, targetCount] để hiển thị.
  int get clampedProgress =>
      targetCount == null ? progress : progress.clamp(0, targetCount!).toInt();

  /// Còn lượt làm lại bài kiểm tra.
  bool get canRetry => (attemptsLeft ?? 0) > 0;

  factory AssignmentMine.fromJson(Map<String, dynamic> json) => AssignmentMine(
    status: AssignmentStatus.fromString(json['status'] as String?),
    targetCount: (json['targetCount'] as num?)?.toInt(),
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    scorePercentage: (json['scorePercentage'] as num?)?.toDouble(),
    attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
    attemptsAllowed: (json['attemptsAllowed'] as num?)?.toInt(),
    attemptsLeft: (json['attemptsLeft'] as num?)?.toInt(),
    completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
  );
}

class ClassAssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final AssignmentType type;

  // --- Bài học (study_mission) ---
  /// all_cards | new_only; null với bài kiểm tra.
  final String? mode;

  /// all | count; null với bài kiểm tra.
  final String? scope;
  final int? targetCount;
  final List<AssignmentSource> sources;

  // --- Bài kiểm tra (graded_test) ---
  final String? testId;
  final AssignmentTestInfo? test;

  /// Học viên chỉ thấy bài khi `startAt <= now`; null = giao ngay.
  final DateTime? startAt;
  final DateTime endAt;

  /// Ngay sau khi tạo / sửa luôn là `scheduled` (job nền kích hoạt sau vài giây): tải lại danh sách.
  final AssignmentPhase phase;
  final AssignmentMine? my;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassAssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    required this.type,
    this.mode,
    this.scope,
    this.targetCount,
    this.sources = const [],
    this.testId,
    this.test,
    this.startAt,
    required this.endAt,
    this.phase = AssignmentPhase.running,
    this.my,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Bí danh cũ của `endAt` (BE vẫn trả `deadline`).
  DateTime get deadline => endAt;

  bool get isTest => type == AssignmentType.gradedTest;

  factory ClassAssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final rawTest = json['test'];
    final rawMy = json['my'];
    return ClassAssignmentModel(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? json['class_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: AssignmentType.fromString(json['type'] as String?),
      mode: json['mode'] as String?,
      scope: json['scope'] as String?,
      targetCount: (json['targetCount'] as num?)?.toInt(),
      sources: rawSources is List
          ? [
              for (final s in rawSources)
                if (s is Map<String, dynamic>) AssignmentSource.fromJson(s),
            ]
          : const [],
      testId: json['testId'] as String? ?? json['test_id'] as String?,
      test: rawTest is Map<String, dynamic> ? AssignmentTestInfo.fromJson(rawTest) : null,
      startAt: DateTime.tryParse(json['startAt']?.toString() ?? ''),
      endAt:
          DateTime.tryParse(json['endAt']?.toString() ?? json['deadline']?.toString() ?? '') ??
          DateTime.now(),
      phase: AssignmentPhase.fromString(json['phase'] as String?),
      my: rawMy is Map<String, dynamic> ? AssignmentMine.fromJson(rawMy) : null,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

/// Nhóm đã tính sẵn để hiển thị danh sách bài giao.
extension ClassAssignmentUi on ClassAssignmentModel {
  /// Học viên còn có thể làm bài: đang diễn ra, được giao, và (bài kiểm tra) còn lượt.
  bool get canStudentDo {
    if (phase != AssignmentPhase.running) return false;
    final mine = my;
    if (mine == null) return false;
    if (mine.status == AssignmentStatus.skipped) return false;
    if (isTest) return mine.attemptsAllowed == null || mine.canRetry || mine.attemptsCount == 0;
    return true;
  }

  /// Nút "Làm lại": bài kiểm tra đã nộp ít nhất một lượt, còn đang diễn ra và còn lượt.
  bool get canRetake =>
      isTest &&
      phase == AssignmentPhase.running &&
      (my?.attemptsCount ?? 0) > 0 &&
      (my?.canRetry ?? false);
}
