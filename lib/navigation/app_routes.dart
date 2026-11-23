enum AppRoute {
  // --- Auth & Onboarding ---
  splash(name: 'splash', path: '/'),
  login(name: 'login', path: '/login'),
  signup(name: 'signup', path: '/signup'),
  forgotPassword(name: 'forgot_password', path: '/forgot-password'),
  verifyOtp(name: 'verify_otp', path: 'verify-otp'),
  verifyForgotOtp(name: 'verify_forgot_otp', path: 'verify-forgot-otp'),
  resetPassword(name: 'reset_password', path: 'reset-password'),

  // --- Main ---
  home(name: 'home', path: '/home'),
  notifications(name: 'notifications', path: '/notifications'),
  notificationSettings(name: 'notification_settings', path: '/notification-settings'),

  library(name: 'library', path: '/library'),
  discover(name: 'discover', path: '/discover'),
  discoverPopular(name: 'discover_popular', path: '/discover/popular'),
  // --- Nhánh 3: Hồ sơ ---
  profile(name: 'profile', path: '/profile'),
  settings(name: 'settings', path: 'settings'),
  statistics(name: 'statistics', path: 'statistics'),
  coins(name: 'coins', path: 'coins'),
  reportHistory(name: 'report_history', path: 'reports'),
  reportCreate(name: 'report_create', path: 'reports/create'),
  reportDetail(name: 'report_detail', path: 'reports/:id'),
  documentImport(name: 'document_import', path: 'document-import'),
  documentImportDrafts(name: 'document_import_drafts', path: 'document-import/drafts'),
  documentImportDraft(name: 'document_import_draft', path: 'document-import/drafts/:id'),
  classrooms(name: 'classrooms', path: 'classrooms'),
  classJoin(name: 'class_join', path: 'join'),
  classroomDetail(name: 'classroom_detail', path: '/classroom/:id'),
  testHistory(name: 'test_history', path: 'test-history'),
  testHistoryDetail(name: 'test_history_detail', path: 'test-history/:attemptId'),

  // --- Nhánh 0: Thư mục ---
  libraryFolders(name: 'library_folders', path: '/library/folder'),
  folderDetail(name: 'folder_detail', path: ':id'),
  folderCreate(name: 'folder_create', path: 'create'),
  folderEdit(name: 'folder_edit', path: 'edit'),

  // --- Nhánh 1: Học phần ---
  libraryDecks(name: 'library_decks', path: '/library/deck'),
  deckDetail(name: 'deck_detail', path: ':id'),
  deckCreate(name: 'deck_create', path: 'create'),
  deckEdit(name: 'deck_edit', path: ':id/edit'),

  // --- Study & Test ---
  testSetup(name: 'test_setup', path: '/test-setup'),
  classTest(
    name: 'class_test',
    path: '/classrooms/:classId/assignments/:assignmentId/test/:testId',
  ),
  flashcardStudy(name: 'flashcard_study', path: '/flashcard-study');

  final String name;
  final String path;

  const AppRoute({required this.name, required this.path});
}
