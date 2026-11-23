enum UserRole {
  user,
  admin;

  static UserRole fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String toJson() => name;
}

enum UserPlan {
  free,
  plus,
  pro;

  static UserPlan fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'plus':
        return UserPlan.plus;
      case 'pro':
        return UserPlan.pro;
      case 'free':
      default:
        return UserPlan.free;
    }
  }

  String toJson() => name;
}

enum GoalType {
  longTerm('long_term'),
  shortTerm('short_term');

  final String value;
  const GoalType(this.value);

  static GoalType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'short_term':
        return GoalType.shortTerm;
      case 'long_term':
      default:
        return GoalType.longTerm;
    }
  }

  String toJson() => value;
}

enum CardState {
  newCard('new'),
  learning('learning'),
  review('review'),
  relearning('relearning'),
  mastered('mastered');

  final String value;
  const CardState(this.value);

  static CardState fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'learning':
        return CardState.learning;
      case 'review':
        return CardState.review;
      case 'relearning':
        return CardState.relearning;
      case 'mastered':
        return CardState.mastered;
      case 'new':
      default:
        return CardState.newCard;
    }
  }

  String toJson() => value;
}

enum ClassRole {
  owner,
  admin,
  tutor,
  student;

  static ClassRole fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'owner':
        return ClassRole.owner;
      case 'admin':
        return ClassRole.admin;
      case 'tutor':
        return ClassRole.tutor;
      case 'student':
      default:
        return ClassRole.student;
    }
  }

  String toJson() => name;
}

enum SearchType {
  folder,
  deck,
  tag,
  classroom;

  static SearchType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'deck':
        return SearchType.deck;
      case 'tag':
        return SearchType.tag;
      case 'class':
        return SearchType.classroom;
      case 'folder':
      default:
        return SearchType.folder;
    }
  }

  String toJson() => this == SearchType.classroom ? 'class' : name;
}

enum NotificationType {
  system('system'),
  srsDue('srs_due'),
  dailyStudyTime('daily_study_time'),
  reportResolved('report_resolved'),
  streakWarning('streak_warning'),
  classUpdate('class_update'),
  classInvite('class_invite'),
  classInviteResponse('class_invite_response'),
  classTestStart('class_test_start'),
  classMemberLeft('class_member_left'),
  classAssignment('class_assignment'),
  classAnnouncement('class_announcement'),
  classJoinRequest('class_join_request'),
  classJoinApproved('class_join_approved'),
  classSubmission('class_submission'),
  morningMotivation('morning_motivation');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'srs_due':
        return NotificationType.srsDue;
      case 'daily_study_time':
        return NotificationType.dailyStudyTime;
      case 'report_resolved':
        return NotificationType.reportResolved;
      case 'streak_warning':
        return NotificationType.streakWarning;
      case 'class_update':
        return NotificationType.classUpdate;
      case 'morning_motivation':
        return NotificationType.morningMotivation;
      case 'class_invite':
        return NotificationType.classInvite;
      case 'class_invite_response':
        return NotificationType.classInviteResponse;
      case 'class_test_start':
        return NotificationType.classTestStart;
      case 'class_member_left':
        return NotificationType.classMemberLeft;
      case 'class_assignment':
        return NotificationType.classAssignment;
      case 'class_announcement':
        return NotificationType.classAnnouncement;
      case 'class_join_request':
        return NotificationType.classJoinRequest;
      case 'class_join_approved':
        return NotificationType.classJoinApproved;
      case 'class_submission':
        return NotificationType.classSubmission;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  /// Thông báo thuộc module Lớp học (title/content là tiếng Việt thật, không phải key i18n).
  bool get isClass => value.startsWith('class_');

  String toJson() => value;
}

enum TestQuestionType {
  flashcard('flashcard', 'Flashcard', 'Lật thẻ tiêu chuẩn'),
  multipleChoice('multiple_choice', 'Trắc nghiệm', 'Chọn 1 trong 4'),
  trueFalse('true_false', 'Đúng / Sai', 'Chọn Đúng hoặc Sai'),
  fillInTheBlank('fill_in_the_blank', 'Điền từ', 'Tự gõ đáp án'),
  dictation('dictation', 'Chính tả', 'Nghe và gõ lại'),
  matching('matching', 'Ghép cặp', 'Nối từ - nghĩa');

  final String value;
  final String title;
  final String subtitle;

  const TestQuestionType(this.value, this.title, this.subtitle);

  static TestQuestionType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'flashcard':
        return TestQuestionType.flashcard;
      case 'multiple_choice':
        return TestQuestionType.multipleChoice;
      case 'true_false':
        return TestQuestionType.trueFalse;
      case 'fill_in_the_blank':
        return TestQuestionType.fillInTheBlank;
      case 'dictation':
        return TestQuestionType.dictation;
      case 'matching':
        return TestQuestionType.matching;
      default:
        return TestQuestionType.multipleChoice;
    }
  }

  String toJson() => value;
}

enum TestSourceType {
  deck('deck', 'Bộ thẻ'),
  folder('folder', 'Thư mục'),
  tag('tag', 'Nhãn');

  final String value;
  final String label;

  const TestSourceType(this.value, this.label);

  static TestSourceType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'deck':
        return TestSourceType.deck;
      case 'folder':
        return TestSourceType.folder;
      case 'tag':
        return TestSourceType.tag;
      default:
        return TestSourceType.deck;
    }
  }

  String toJson() => value;
}
