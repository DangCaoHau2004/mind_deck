/// Cài đặt đề kiểm tra phiên bản 2 (`settings` của `POST /tests/generate`, `PUT /tests/:id`).
/// Giờ bắt đầu / kết thúc KHÔNG nằm ở đây mà ở bài giao.
class TestSettings {
  static const String scoreHighest = 'highest';
  static const String scoreLatest = 'latest';
  static const String scoreFirst = 'first';

  static const String sideFront = 'front';
  static const String sideBack = 'back';
  static const String sideMixed = 'mixed';

  final bool timeLimitEnabled;

  /// 1–600, bắt buộc khi `timeLimitEnabled`; null khi tắt.
  final int? timeLimitMinutes;

  /// App hiện đúng/sai ngay từng câu trong lúc làm.
  final bool showAnswerInstantly;

  /// Xem điểm sau khi nộp (tự bật nếu `showAnswers`).
  final bool showScore;

  /// Xem đáp án chi tiết sau khi nộp (kéo theo `showScore`).
  final bool showAnswers;

  /// Số lượt làm tối đa 1–20 (1 = không làm lại).
  final int attempts;

  /// highest | latest | first: cách tính điểm bài giao khi làm lại.
  final String scorePolicy;

  /// Đề auto LUÔN đảo; manual đảo câu + đáp án trắc nghiệm + hai cột ghép cặp.
  final bool shuffle;

  /// front | back | mixed: chiều hỏi khi hệ thống sinh câu (đề auto và xem thử).
  final String questionSide;

  const TestSettings({
    this.timeLimitEnabled = false,
    this.timeLimitMinutes,
    this.showAnswerInstantly = false,
    this.showScore = true,
    this.showAnswers = false,
    this.attempts = 1,
    this.scorePolicy = scoreHighest,
    this.shuffle = true,
    this.questionSide = sideFront,
  });

  factory TestSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TestSettings();
    bool b(String key, bool fallback) => json[key] is bool ? json[key] as bool : fallback;
    return TestSettings(
      timeLimitEnabled: b('timeLimitEnabled', false),
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt(),
      showAnswerInstantly: b('showAnswerInstantly', false),
      showScore: b('showScore', true),
      showAnswers: b('showAnswers', false),
      attempts: (json['attempts'] as num?)?.toInt() ?? 1,
      scorePolicy: json['scorePolicy'] as String? ?? scoreHighest,
      shuffle: b('shuffle', true),
      questionSide: json['questionSide'] as String? ?? sideFront,
    );
  }

  /// Body gửi lên BE. `showAnswers` bật thì BE tự bật `showScore`; ở FE ta chuẩn hóa trước.
  Map<String, dynamic> toJson() {
    final normalizedShowScore = showAnswers ? true : showScore;
    return {
      'timeLimitEnabled': timeLimitEnabled,
      if (timeLimitEnabled) 'timeLimitMinutes': timeLimitMinutes ?? 15,
      'showAnswerInstantly': showAnswerInstantly,
      'showScore': normalizedShowScore,
      'showAnswers': showAnswers,
      'attempts': attempts,
      'scorePolicy': scorePolicy,
      'shuffle': shuffle,
      'questionSide': questionSide,
    };
  }

  TestSettings copyWith({
    bool? timeLimitEnabled,
    int? timeLimitMinutes,
    bool? showAnswerInstantly,
    bool? showScore,
    bool? showAnswers,
    int? attempts,
    String? scorePolicy,
    bool? shuffle,
    String? questionSide,
  }) {
    final nextShowAnswers = showAnswers ?? this.showAnswers;
    return TestSettings(
      timeLimitEnabled: timeLimitEnabled ?? this.timeLimitEnabled,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      showAnswerInstantly: showAnswerInstantly ?? this.showAnswerInstantly,
      // Bật xem đáp án thì phải xem được điểm.
      showScore: nextShowAnswers ? true : (showScore ?? this.showScore),
      showAnswers: nextShowAnswers,
      attempts: attempts ?? this.attempts,
      scorePolicy: scorePolicy ?? this.scorePolicy,
      shuffle: shuffle ?? this.shuffle,
      questionSide: questionSide ?? this.questionSide,
    );
  }

  String get scorePolicyLabel => switch (scorePolicy) {
    scoreLatest => 'Lần làm gần nhất',
    scoreFirst => 'Lần làm đầu tiên',
    _ => 'Lần cao nhất',
  };
}

/// Phần kết quả được phép hiện sau khi nộp (theo cài đặt đề).
class TestVisibility {
  final bool showScore;
  final bool showAnswers;

  const TestVisibility({this.showScore = true, this.showAnswers = true});

  factory TestVisibility.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const TestVisibility();
    return TestVisibility(
      showScore: json['showScore'] as bool? ?? true,
      showAnswers: json['showAnswers'] as bool? ?? true,
    );
  }
}
