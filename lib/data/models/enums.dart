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
  premium;

  static UserPlan fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'premium':
        return UserPlan.premium;
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
  tag;

  static SearchType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'deck':
        return SearchType.deck;
      case 'tag':
        return SearchType.tag;
      case 'folder':
      default:
        return SearchType.folder;
    }
  }

  String toJson() => name;
}

enum NotificationType {
  system('system'),
  srsDue('srs_due'),
  streakWarning('streak_warning'),
  classUpdate('class_update'),
  morningMotivation('morning_motivation');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'srs_due':
        return NotificationType.srsDue;
      case 'streak_warning':
        return NotificationType.streakWarning;
      case 'class_update':
        return NotificationType.classUpdate;
      case 'morning_motivation':
        return NotificationType.morningMotivation;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

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
