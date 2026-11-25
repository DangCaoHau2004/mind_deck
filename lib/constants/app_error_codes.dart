class AppErrorCodes {
  AppErrorCodes._();

  static const String networkError = 'NETWORK_ERROR';
  static const String timeoutError = 'TIMEOUT_ERROR';
  static const String cacheError = 'CACHE_ERROR';
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String unknownError = 'UNKNOWN_ERROR';
  static const String validationError = 'VALIDATION_ERROR';

  /// BE trả HTTP 200 nhưng không có dữ liệu dùng được (`success: false` hoặc `data` rỗng).
  static const String loadDataFailed = 'LOAD_DATA_FAILED';

  /// Thao tác (đăng nhập, gửi OTP...) được BE trả HTTP 200 nhưng không thành công / thiếu dữ liệu.
  static const String requestFailed = 'REQUEST_FAILED';
  // Từ đây trở xuống là mã lỗi do BE trả về (`errorCode`).
  static const String systemInternalError = 'SYSTEM_INTERNAL_ERROR';
  static const String systemInvalidInputFormat = 'SYSTEM_INVALID_INPUT_FORMAT';
  static const String rateLimitExceeded = 'RATE_LIMIT_GLOBAL_API_LIMIT_EXCEEDED';

  // Auth
  static const String authAccountLockedPermanently = 'AUTH_ACCOUNT_LOCKED_PERMANENTLY';
  static const String authAccountLockedTemporarily = 'AUTH_ACCOUNT_LOCKED_TEMPORARILY';
  static const String authPasswordCurrentEmpty = 'AUTH_PASSWORD_CURRENT_EMPTY';
  static const String authCurrentPasswordIncorrect = 'AUTH_CURRENT_PASSWORD_INCORRECT';
  static const String accountOwnsClasses = 'ACCOUNT_OWNS_CLASSES';
  static const String userNotFound = 'USER_NOT_FOUND';

  // Xu
  static const String coinInsufficient = 'COIN_INSUFFICIENT';

  // Tìm ảnh
  static const String imageTempExpired = 'IMAGE_TEMP_EXPIRED';
  static const String tagAlreadyExists = 'TAG_ALREADY_EXISTS';
  static const String imageSearchQueryTooLong = 'IMAGE_SEARCH_QUERY_TOO_LONG';
  static const String imageSearchTooManyRequests = 'IMAGE_SEARCH_TOO_MANY_REQUESTS';
  static const String imageSearchRateLimited = 'IMAGE_SEARCH_RATE_LIMITED';
  static const String imageSearchUnavailable = 'IMAGE_SEARCH_UNAVAILABLE';
  static const String imageSearchNotConfigured = 'IMAGE_SEARCH_NOT_CONFIGURED';

  // Deck / Folder / Share / Study
  static const String deckNotFound = 'DECK_NOT_FOUND';
  static const String folderNotFound = 'FOLDER_NOT_FOUND';
  static const String deckAccessDenied = 'DECK_ACCESS_DENIED';
  static const String folderAccessDenied = 'FOLDER_ACCESS_DENIED';
  static const String shareCannotCopyDeck = 'SHARE_CANNOT_COPY_DECK';
  static const String shareCannotCopyFolder = 'SHARE_CANNOT_COPY_FOLDER';
  static const String shareDeckNotFound = 'SHARE_DECK_NOT_FOUND';
  static const String shareFolderNotFound = 'SHARE_FOLDER_NOT_FOUND';
  static const String studyNoCardsFound = 'STUDY_NO_CARDS_FOUND';
  static const String studyNoActiveSession = 'STUDY_NO_ACTIVE_SESSION';

  // Class - chung / thành viên
  static const String classNotFound = 'CLASS_NOT_FOUND';
  static const String classNotAMember = 'CLASS_NOT_A_MEMBER';
  static const String classInsufficientPermissions = 'CLASS_INSUFFICIENT_PERMISSIONS';
  static const String classClassIdRequired = 'CLASS_CLASS_ID_REQUIRED';
  static const String classNameEmpty = 'CLASS_NAME_EMPTY';
  static const String classNameTooLong = 'CLASS_NAME_TOO_LONG';
  static const String classNewOwnerInvalid = 'CLASS_NEW_OWNER_INVALID';
  static const String tagNameTooLong = 'TAG_NAME_TOO_LONG';
  static const String classSettingsInvalid = 'CLASS_SETTINGS_INVALID';
  static const String classNotifySettingsInvalid = 'CLASS_NOTIFY_SETTINGS_INVALID';
  static const String classJoinCodeOrIdRequired = 'CLASS_JOIN_CODE_OR_ID_REQUIRED';
  static const String classJoinCodeInvalid = 'CLASS_JOIN_CODE_INVALID';
  static const String classPrivateClassRequiresCode = 'CLASS_PRIVATE_CLASS_REQUIRES_CODE';
  static const String classAlreadyJoinedOrPending = 'CLASS_ALREADY_JOINED_OR_PENDING';
  static const String classCannotApproveSelf = 'CLASS_CANNOT_APPROVE_SELF';
  static const String classRequestNotFound = 'CLASS_REQUEST_NOT_FOUND';
  static const String classUserNotPending = 'CLASS_USER_NOT_PENDING';
  static const String classUserNotFound = 'CLASS_USER_NOT_FOUND';
  static const String classCannotKickOwner = 'CLASS_CANNOT_KICK_OWNER';
  static const String classCannotKickSelf = 'CLASS_CANNOT_KICK_SELF';
  static const String classCannotManageHigherRole = 'CLASS_CANNOT_MANAGE_HIGHER_ROLE';
  static const String classMemberStatusInvalid = 'CLASS_MEMBER_STATUS_INVALID';
  static const String classRoleInvalid = 'CLASS_ROLE_INVALID';
  static const String classMemberNotFound = 'CLASS_MEMBER_NOT_FOUND';
  static const String classOwnerCannotLeave = 'CLASS_OWNER_CANNOT_LEAVE';

  // Class - lời mời
  static const String classInviteEmailsRequired = 'CLASS_INVITE_EMAILS_REQUIRED';
  static const String classInviteTooMany = 'CLASS_INVITE_TOO_MANY';
  static const String classInviteNotAllowed = 'CLASS_INVITE_NOT_ALLOWED';
  static const String classInviteNotFound = 'CLASS_INVITE_NOT_FOUND';

  // Class - học liệu / clone
  static const String classMaterialSourceNotAccessible = 'CLASS_MATERIAL_SOURCE_NOT_ACCESSIBLE';
  static const String classMaterialDuplicate = 'CLASS_MATERIAL_DUPLICATE';
  static const String classMaterialsEmpty = 'CLASS_MATERIALS_EMPTY';
  static const String classMaterialDuplicatePolicyInvalid =
      'CLASS_MATERIAL_DUPLICATE_POLICY_INVALID';
  static const String classFolderNotInClass = 'CLASS_FOLDER_NOT_IN_CLASS';
  static const String classMaterialNotInClass = 'CLASS_MATERIAL_NOT_IN_CLASS';
  static const String classMaterialInUse = 'CLASS_MATERIAL_IN_USE';
  static const String classCloneTargetInvalid = 'CLASS_CLONE_TARGET_INVALID';
  static const String classCloneNotAllowed = 'CLASS_CLONE_NOT_ALLOWED';

  // Class - bài giao / xếp hạng
  static const String classAssignmentMissingRequiredFields =
      'CLASS_ASSIGNMENT_MISSING_REQUIRED_FIELDS';
  static const String classAssignmentTypeInvalid = 'CLASS_ASSIGNMENT_TYPE_INVALID';
  static const String classAssignmentTimeInvalid = 'CLASS_ASSIGNMENT_TIME_INVALID';
  static const String classAssignmentModeInvalid = 'CLASS_ASSIGNMENT_MODE_INVALID';
  static const String classAssignmentSourcesInvalid = 'CLASS_ASSIGNMENT_SOURCES_INVALID';
  static const String classAssignmentTestInvalid = 'CLASS_ASSIGNMENT_TEST_INVALID';
  static const String classAssignmentTestMismatch = 'CLASS_ASSIGNMENT_TEST_MISMATCH';
  static const String classAssignmentNotFound = 'CLASS_ASSIGNMENT_NOT_FOUND';
  static const String classAssignmentLocked = 'CLASS_ASSIGNMENT_LOCKED';
  static const String classLeaderboardDisabled = 'CLASS_LEADERBOARD_DISABLED';

  // Test
  static const String testClassRequired = 'TEST_CLASS_REQUIRED';
  static const String testKindInvalid = 'TEST_KIND_INVALID';
  static const String testPersonalAutoOnly = 'TEST_PERSONAL_AUTO_ONLY';
  static const String testSettingsInvalid = 'TEST_SETTINGS_INVALID';
  static const String testQuestionsInvalid = 'TEST_QUESTIONS_INVALID';
  static const String testCardIdsEmpty = 'TEST_CARD_IDS_EMPTY';
  static const String testTooManyCards = 'TEST_TOO_MANY_CARDS';
  static const String testQuestionTypesEmpty = 'TEST_QUESTION_TYPES_EMPTY';
  static const String testAssignmentRequired = 'TEST_ASSIGNMENT_REQUIRED';
  static const String testAnswersEmpty = 'TEST_ANSWERS_EMPTY';
  static const String testSubmitDataInvalid = 'TEST_SUBMIT_DATA_INVALID';
  static const String testSourceRequired = 'TEST_SOURCE_REQUIRED';
  static const String testSourcesTooManyCards = 'TEST_SOURCES_TOO_MANY_CARDS';
  static const String testTeacherOnly = 'TEST_TEACHER_ONLY';
  static const String testEditLocked = 'TEST_EDIT_LOCKED';
  static const String testNotInClass = 'TEST_NOT_IN_CLASS';
  static const String testNotStarted = 'TEST_NOT_STARTED';
  static const String testEnded = 'TEST_ENDED';
  static const String testAttemptsExhausted = 'TEST_ATTEMPTS_EXHAUSTED';
  static const String testSessionExpired = 'TEST_SESSION_EXPIRED';
  static const String testNotFound = 'TEST_NOT_FOUND';
  static const String testNoQuestions = 'TEST_NO_QUESTIONS';
  static const String testNoCardsFound = 'TEST_NO_CARDS_FOUND';
  static const String testSessionNotFound = 'TEST_SESSION_NOT_FOUND';
  static const String testAttemptNotFound = 'TEST_ATTEMPT_NOT_FOUND';

  // Analytics
  static const String analyticsStudentIdRequiredForTeacher =
      'ANALYTICS_STUDENT_ID_REQUIRED_FOR_TEACHER';
  static const String analyticsTimezoneInvalid = 'ANALYTICS_TIMEZONE_INVALID';
  static const String analyticsStatusInvalid = 'ANALYTICS_STATUS_INVALID';
  static const String analyticsNotATest = 'ANALYTICS_NOT_A_TEST';
  static const String analyticsLeaderboardMonthInvalid = 'ANALYTICS_LEADERBOARD_MONTH_INVALID';
}
