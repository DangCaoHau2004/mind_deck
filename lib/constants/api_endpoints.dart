import 'package:mind_deck/configs/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Địa chỉ theo flavor, xem AppConfig.
  static String get baseUrl => AppConfig.current.baseUrl;
  static String get url => AppConfig.current.url;

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String loginGoogle = '/auth/google';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  // Sessions
  static const String sessions = '/auth/sessions';
  static const String sessionById = '/auth/sessions/'; // Append {sid} dynamically

  // Profile
  static const String profile = '/profile';
  static const String linkGoogle = '/profile/link-google';
  static const String unlinkGoogle = '/profile/unlink-google';

  // Folders
  static const String folders = '/folders';
  static const String folderById = '/folders/'; // Append {id}
  static const String shareFolder = '/folders/'; // Append {id}/share
  static const String cloneFolder = '/folders/'; // Append {id}/clone
  static const String starFolder = '/folders/'; // Append {id}/star

  // Decks
  static const String decks = '/decks';
  static const String deckById = '/decks/'; // Append {id}
  static const String shareDeck = '/decks/'; // Append {id}/share
  static const String cloneDeck = '/decks/'; // Append {id}/clone
  static const String starDeck = '/decks/'; // Append {id}/star

  // Tags
  static const String tags = '/tags';

  // Shared
  static const String sharedDeck = '/shared/decks/'; // Append {token}
  static const String sharedFolder = '/shared/folders/'; // Append {token}
  static const String sharedGenerateLink = '/shared/generate-link';
  static const String sharedRevokeLink = '/shared/revoke-link';

  // Images
  static const String uploadImage = '/images/upload';
  static const String getImageUrl = '/images'; // Append /*path
  static const String imageSearch = '/images/search';
  static const String imageSearchSelect = '/images/search/select';

  // Coins
  static const String coins = '/coins';
  static const String coinsHistory = '/coins/history';

  // Sync
  static const String syncDown = '/sync/down';
  static const String syncUp = '/sync/up';

  // Study
  static const String study = '/study';
  static const String studyActive = '/study/active';

  // Home
  static const String home = '/home';

  // Review
  static const String review = '/review/';

  // Custom Tests
  static const String tests = '/tests';
  static const String testsGenerate = '/tests/generate';
  static const String testsPreview = '/tests/preview';
  static const String testById = '/tests/'; // Append {testId}  (GET/PUT chi tiết, /start, /submit)
  static const String testsSubmit = '/tests/'; // Append {testId}/submit
  static const String testsSessions = '/tests/sessions/'; // Append {sessionId}/resume | /progress
  static const String testsSessionsList = '/tests/sessions'; // Danh sách phiên làm bài dang dở
  static const String historyTests = '/history/tests';
  static const String testsResolveSources = '/tests/resolve-sources';
  static const String testsPersonalSources = '/tests/sources/personal';
  static const String testsClassSources = '/tests/sources/classes';
  static const String testsAvailableSources = '/tests/available-sources';
  static const String testsAvailableDecks = '/tests/available-sources/decks';

  // Reports
  static const String reports = '/reports';
  static const String reportById = '/reports/'; // Append {id}

  // Document import (tạo thẻ từ tài liệu)
  static const String documentImports = '/document-imports';
  static const String documentImportQuota = '/document-imports/quota';
  static String documentImportById(String id) => '/document-imports/$id';
  static String documentImportStream(String id) => '/document-imports/$id/stream';
  static String documentImportCommit(String id) => '/document-imports/$id/commit';

  // Discovery
  static const String discovery = '/discovery';
  static const String discoveryPopular = '/discovery/popular';

  // Search
  static const String search = '/search';
  static const String searchSuggest = '/search/suggest';

  // Classes
  static const String classes = '/classes';
  static const String classesJoin = '/classes/join';
  static const String classMembers = '/classes/'; // Append {id}/members
  static const String classMembersPending = '/classes/'; // Append {id}/members/pending
  static const String classApproveMember = '/classes/'; // Append {id}/members/{userId}/approve
  static const String classKickMember = '/classes/'; // Append {id}/members/{userId}
  static const String classMaterials = '/classes/'; // Append {id}/materials
  static const String classDecks = '/classes/'; // Append {id}/decks
  static const String classClone = '/classes/'; // Append {id}/clone
  static const String classAssignments = '/classes/'; // Append {id}/assignments
  static const String classSubmitAssignment =
      '/classes/'; // Append {id}/assignments/{assignmentId}/submit
  static const String classAssignmentSubmissions =
      '/classes/'; // Append {id}/assignments/{assignmentId}/submissions
  static const String classMySubmissions = '/classes/'; // Append {id}/my-submissions
  static const String classLeaderboard = '/classes/'; // Append {id}/leaderboard
  static const String classInvitations = '/classes/invitations'; // Lời mời của tôi
  static const String classSettings = '/classes/'; // Append {id}/settings
  static const String classMyNotifications = '/classes/'; // Append {id}/members/me/notifications
  static const String classLeave = '/classes/'; // Append {id}/leave
  static const String classInvites =
      '/classes/'; // Append {id}/invitations[/lookup|/accept|/decline|/{userId}]
  static const String classMaterialsCheck = '/classes/'; // Append {id}/materials/check
  static const String classMaterialFolderDecks =
      '/classes/'; // Append {id}/materials/folders/{folderId}/decks
  static const String classAssignmentsOverdue = '/classes/'; // Append {id}/assignments/overdue

  // Analytics
  static const String analyticsReviewWorkload =
      '/analytics/classes/'; // Append {id}/review-workload
  static const String analyticsHardestCards = '/analytics/classes/'; // Append {id}/hardest-cards
  static const String analyticsDeckHealth = '/analytics/classes/'; // Append {id}/deck-health
  static const String analyticsAssignmentProgress =
      '/analytics/classes/'; // Append {id}/assignments/{assignmentId}/progress
  static const String analyticsAssignmentDrillDown =
      '/analytics/classes/'; // Append {id}/assignments/{assignmentId}/drill-down
  static const String analyticsScoreDistribution =
      '/analytics/classes/'; // Append {id}/assignments/{assignmentId}/score-distribution
  static const String analyticsStudentAttempts =
      '/analytics/classes/'; // Append {id}/assignments/{assignmentId}/students/{userId}/attempts
  static const String analyticsAttemptDetail =
      '/analytics/classes/'; // Append {id}/attempts/{attemptId}
  static const String analyticsStudentAssignments =
      '/analytics/classes/'; // Append {id}/students/{userId}/assignments

  // Notifications
  static const String notificationDevices = '/notifications/devices';
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationSettings = '/notifications/settings';
  static const String notificationRead = '/notifications/'; // Append {id}/read

  // Stats
  static const String statsFSRS = '/stats/deck/'; // Append {deckId}/fsrs
  static const String statsOverview = '/stats/overview';

  // Admin
  static const String adminFolders = '/admin/folders/'; // Append {id}
  static const String adminDecks = '/admin/decks/'; // Append {id}
  static const String adminReports = '/admin/reports';
  static const String adminResolveReport = '/admin/reports/'; // Append {id}/resolve
  static const String adminUsers = '/admin/users';
  static const String adminLockUser = '/admin/users/'; // Append {id}/lock
  static const String adminUnlockUser = '/admin/users/'; // Append {id}/unlock
  static const String adminSendNotification = '/admin/notifications/send';
}
