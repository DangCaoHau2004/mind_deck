import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_event.dart';
import 'package:mind_deck/ui/screens/splash_screen.dart';
import 'package:mind_deck/ui/screens/auth/login/login_screen.dart';
import 'package:mind_deck/ui/screens/auth/sign_up/sign_up_screen.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/forgot_password_screen.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/otp_verification_screen.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/create_new_password_screen.dart';
import 'package:mind_deck/ui/screens/dashboard/dashboard_screen.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_bloc.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_event.dart';
import 'package:mind_deck/ui/screens/deck/library_deck_tab.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_bloc.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_event.dart';
import 'package:mind_deck/ui/screens/folder/library_folder_tab.dart';
import 'package:mind_deck/ui/screens/library/library_screen.dart';
import 'package:mind_deck/ui/screens/folder/folder_form/folder_form_screen.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/folder_detail_screen.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/deck_form_screen.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/deck_detail_screen.dart';
import 'package:mind_deck/ui/screens/folder/folder_form/bloc/folder_form_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/bloc/deck_form_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/study_flashcard/bloc/flashcard_study_bloc.dart';
import 'package:mind_deck/ui/screens/study_flashcard/bloc/flashcard_study_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/take_test_screen.dart';
import 'package:mind_deck/ui/screens/study_flashcard/flashcard_study_screen.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/ui/screens/home/home_screen.dart';
import 'package:mind_deck/ui/screens/discover/discover_screen.dart';
import 'package:mind_deck/ui/screens/discover/popular_content/discover_popular_screen.dart';
import 'package:mind_deck/ui/screens/profile/profile_screen.dart';
import 'package:mind_deck/ui/screens/setting/settings_screen.dart';
import 'package:mind_deck/ui/screens/profile/stats_overview/stats_overview_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_hub/class_hub_screen.dart';
import 'package:mind_deck/ui/screens/classroom/classrooms_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/class_test_screen.dart';
import 'package:mind_deck/ui/screens/report/report_history/report_history_screen.dart';
import 'package:mind_deck/ui/screens/report/report_form/report_form_screen.dart';
import 'package:mind_deck/ui/screens/profile/test_history/test_history_screen.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_bloc.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/test_history_detail_screen.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_bloc.dart';
import 'package:mind_deck/ui/screens/report/report_detail/report_detail_screen.dart';
import 'package:mind_deck/ui/screens/report/report_history/bloc/report_history_bloc.dart';
import 'package:mind_deck/ui/screens/discover/bloc/discover_bloc.dart';
import 'package:mind_deck/ui/screens/discover/popular_content/bloc/discover_popular_bloc.dart';
import 'package:mind_deck/ui/screens/report/report_form/bloc/report_form_bloc.dart';
import 'package:mind_deck/ui/screens/report/report_detail/bloc/report_detail_bloc.dart';
import 'package:mind_deck/ui/screens/notification/notification_list_screen.dart';

class AppRouter {
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter router;
  String? _savedDeepLink;

  AppRouter() {
    final authBloc = DI().sl<AuthBloc>();
    router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoute.splash.path,
      observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: _redirect,
      routes: _routes,
    );
  }

  FutureOr<String?> _redirect(BuildContext context, GoRouterState state) {
    final currentPath = state.uri.path;
    final fullPath = state.uri.toString(); // Lấy toàn bộ link (bao gồm cả ?token=...)
    final authState = DI().sl<AuthBloc>().state;

    final bool isUnknown = authState is AuthUnknown;
    final bool isAuth = authState is AuthAuthenticated;

    // 1. KHI APP VỪA MỞ LÊN (ĐANG CHECK TOKEN)
    if (isUnknown) {
      // BÍ QUYẾT Ở ĐÂY: Nếu user vào bằng Deep Link (không phải gốc / hay splash)
      // thì ta CẤT LINK VÀO TÚI trước khi bắt họ ở lại màn hình Splash.
      if (currentPath != '/' && currentPath != AppRoute.splash.path) {
        _savedDeepLink = fullPath;
      }
      return currentPath == AppRoute.splash.path ? null : AppRoute.splash.path;
    }

    final isAuthRoute =
        currentPath == AppRoute.login.path ||
        currentPath == AppRoute.signup.path ||
        currentPath.startsWith(AppRoute.forgotPassword.path) ||
        currentPath.contains(AppRoute.verifyOtp.path) ||
        currentPath.contains(AppRoute.verifyForgotOtp.path) ||
        currentPath.contains(AppRoute.resetPassword.path);

    if (!isAuth && !isAuthRoute) {
      return AppRoute.login.path;
    }

    // 2. KHI ĐÃ ĐĂNG NHẬP XONG XUÔI
    if (isAuth && (isAuthRoute || currentPath == AppRoute.splash.path)) {
      // Nếu trong túi đang có link cất giấu -> Trả về link đó!
      if (_savedDeepLink != null) {
        final linkToGo = _savedDeepLink;
        _savedDeepLink = null; // Xóa đi để không bị kẹt lần sau
        return linkToGo; // Nhảy thẳng vào màn Folder/Deck!
      }
      // Nếu không có link gì, cho vào Dashboard bình thường
      return AppRoute.dashboard.path;
    }

    // Các trường hợp khác (như đang dùng app mà có link nhảy vào)
    // GoRouter sẽ tự động return null và đi tới đúng đích!
    return null;
  }

  List<RouteBase> get _routes => [
    GoRoute(
      name: AppRoute.splash.name,
      path: AppRoute.splash.path,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: AppRoute.login.name,
      path: AppRoute.login.path,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: AppRoute.signup.name,
      path: AppRoute.signup.path,
      builder: (context, state) => const RegisterScreen(),
      routes: [
        GoRoute(
          name: AppRoute.verifyOtp.name,
          path: AppRoute.verifyOtp.path,
          builder: (context, state) {
            final email = state.extra as String? ?? '';
            return OtpVerificationScreen(email: email, isForForgotPassword: false);
          },
        ),
      ],
    ),
    GoRoute(
      name: AppRoute.forgotPassword.name,
      path: AppRoute.forgotPassword.path,
      builder: (context, state) => const ForgotPasswordScreen(),
      routes: [
        GoRoute(
          name: AppRoute.verifyForgotOtp.name,
          path: AppRoute.verifyForgotOtp.path,
          builder: (context, state) {
            String email = '';
            int cooldown = 60;
            if (state.extra is Map) {
              final map = state.extra as Map;
              email = map['email'] as String? ?? '';
              cooldown = (map['cooldown'] as num?)?.toInt() ?? 60;
            } else if (state.extra is String) {
              email = state.extra as String;
            }
            return OtpVerificationScreen(
              email: email,
              isForForgotPassword: true,
              initialCooldown: cooldown,
            );
          },
        ),
        GoRoute(
          name: AppRoute.resetPassword.name,
          path: AppRoute.resetPassword.path,
          builder: (context, state) {
            final extra = state.extra as Map<String, String>? ?? {};
            final email = extra['email'] ?? '';
            final resetToken = extra['resetToken'] ?? '';
            return CreateNewPasswordScreen(email: email, resetToken: resetToken);
          },
        ),
      ],
    ),

    GoRoute(
      name: AppRoute.notifications.name,
      path: AppRoute.notifications.path,
      builder: (context, state) => const NotificationListScreen(),
    ),

    // === ROOT STATEFUL SHELL ROUTE (CÓ BOTTOM NAVIGATION BAR LƠ LỬNG) ===
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Trang chủ (Dashboard)
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.dashboard.name,
              path: AppRoute.dashboard.path,
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // Tab 1: Thư viện (Library)
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.library.name,
              path: AppRoute.library.path,
              redirect: (context, state) => AppRoute.libraryFolders.path,
            ),
            // Nested StatefulShellRoute cho Thư mục & Học phần
            StatefulShellRoute(
              builder: (context, state, navigationShell) {
                return navigationShell;
              },
              navigatorContainerBuilder: (context, navigationShell, children) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => DI().sl<LibraryFolderBloc>()..add(LibraryFolderLoadStarted()),
                    ),
                    BlocProvider(
                      create: (_) => DI().sl<LibraryDeckBloc>()..add(LibraryDeckLoadStarted()),
                    ),
                  ],
                  child: LibraryScreen(navigationShell: navigationShell, children: children),
                );
              },
              branches: [
                // --- NHÁNH 0: THƯ MỤC (/library/folder) ---
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      name: AppRoute.libraryFolders.name,
                      path: AppRoute.libraryFolders.path,
                      builder: (context, state) => const LibraryFolderTab(),
                      routes: [
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          name: AppRoute.folderCreate.name,
                          path: AppRoute.folderCreate.path,
                          builder: (context, state) => BlocProvider(
                            create: (_) => DI().sl<FolderFormBloc>(),
                            child: const CreateFolderScreen(),
                          ),
                        ),
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          name: AppRoute.folderDetail.name,
                          path: AppRoute.folderDetail.path,
                          builder: (context, state) {
                            final id = state.pathParameters['id']!;
                            final token = state.uri.queryParameters['token'];
                            final initialFolder = state.extra != null
                                ? (state.extra is Map<String, dynamic>
                                      ? FolderModel.fromJson(state.extra as Map<String, dynamic>)
                                      : state.extra as FolderModel)
                                : null;
                            return BlocProvider(
                              create: (_) => DI().sl<FolderDetailBloc>(),
                              child: FolderDetailScreen(
                                folderId: id,
                                initialFolder: initialFolder,
                                token: token,
                              ),
                            );
                          },
                          routes: [
                            GoRoute(
                              parentNavigatorKey: rootNavigatorKey,
                              name: AppRoute.folderEdit.name,
                              path: AppRoute.folderEdit.path,
                              builder: (context, state) {
                                final folder = FolderModel.fromJson(
                                  state.extra as Map<String, dynamic>,
                                );
                                return BlocProvider(
                                  create: (_) => DI().sl<FolderFormBloc>(),
                                  child: EditFolderScreen(folder: folder),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // --- NHÁNH 1: HỌC PHẦN (/library/deck) ---
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      name: AppRoute.libraryDecks.name,
                      path: AppRoute.libraryDecks.path,
                      builder: (context, state) => const LibraryDeckTab(),
                      routes: [
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          name: AppRoute.deckCreate.name,
                          path: AppRoute.deckCreate.path,
                          builder: (context, state) => BlocProvider(
                            create: (_) => DI().sl<DeckFormBloc>(),
                            child: const CreateDeckScreen(),
                          ),
                        ),
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          name: AppRoute.deckDetail.name,
                          path: AppRoute.deckDetail.path,
                          builder: (context, state) {
                            final id = state.pathParameters['id']!;
                            final token = state.uri.queryParameters['token'];
                            DeckModel? initialDeck;
                            String? classId;
                            String? assignmentId;

                            if (state.extra != null) {
                              if (state.extra is Map<String, dynamic>) {
                                final extraMap = state.extra as Map<String, dynamic>;
                                if (extraMap.containsKey('classId') &&
                                    extraMap.containsKey('assignmentId')) {
                                  classId = extraMap['classId'] as String?;
                                  assignmentId = extraMap['assignmentId'] as String?;
                                } else {
                                  initialDeck = DeckModel.fromJson(extraMap);
                                }
                              } else if (state.extra is DeckModel) {
                                initialDeck = state.extra as DeckModel;
                              }
                            }

                            return BlocProvider(
                              create: (_) => DI().sl<DeckDetailBloc>(),
                              child: DeckDetailScreen(
                                deckId: id,
                                initialDeck: initialDeck,
                                token: token,
                                classId: classId,
                                assignmentId: assignmentId,
                              ),
                            );
                          },
                        ),
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          name: AppRoute.deckEdit.name,
                          path: AppRoute.deckEdit.path,
                          builder: (context, state) {
                            final deck = state.extra is Map<String, dynamic>
                                ? DeckModel.fromJson(state.extra as Map<String, dynamic>)
                                : state.extra as DeckModel;
                            return BlocProvider(
                              create: (_) => DI().sl<DeckFormBloc>(),
                              child: EditDeckScreen(deck: deck),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Tab 2: Khám phá (Discover)
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.discover.name,
              path: AppRoute.discover.path,
              builder: (context, state) => BlocProvider(
                create: (_) => DI().sl<DiscoverBloc>(),
                child: const DiscoverScreen(),
              ),
              routes: [
                GoRoute(
                  parentNavigatorKey: rootNavigatorKey,
                  name: AppRoute.discoverPopular.name,
                  path: 'popular',
                  builder: (context, state) => BlocProvider(
                    create: (_) => DI().sl<DiscoverPopularBloc>(),
                    child: const DiscoverPopularScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Hồ sơ & Cài đặt (Profile)
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRoute.profile.name,
              path: AppRoute.profile.path,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  parentNavigatorKey: rootNavigatorKey,
                  name: AppRoute.settings.name,
                  path: AppRoute.settings.path,
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: rootNavigatorKey,
                  name: AppRoute.statistics.name,
                  path: AppRoute.statistics.path,
                  builder: (context, state) => const StatsOverviewScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: rootNavigatorKey,
                  name: AppRoute.classrooms.name,
                  path: AppRoute.classrooms.path,
                  builder: (context, state) => BlocProvider(
                    create: (_) => DI().sl<ClassListBloc>()..add(ClassListLoaded()),
                    child: const ClassRoomsScreen(),
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      name: AppRoute.classJoin.name,
                      path: AppRoute.classJoin.path,
                      builder: (context, state) {
                        final code = state.uri.queryParameters['code'];
                        return ClassRoomsScreen(initialJoinCode: code);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  parentNavigatorKey: rootNavigatorKey,
                  name: AppRoute.reportHistory.name,
                  path: AppRoute.reportHistory.path,
                  builder: (context, state) => BlocProvider(
                    create: (_) => DI().sl<ReportHistoryBloc>(),
                    child: const ReportHistoryScreen(),
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      name: AppRoute.reportCreate.name,
                      path: 'create',
                      builder: (context, state) => BlocProvider(
                        create: (_) => DI().sl<ReportFormBloc>(),
                        child: const ReportFormScreen(),
                      ),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      name: AppRoute.reportDetail.name,
                      path: ':id',
                      builder: (context, state) {
                        final reportId = state.pathParameters['id']!;
                        return BlocProvider(
                          create: (_) => DI().sl<ReportDetailBloc>(),
                          child: ReportDetailScreen(reportId: reportId),
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  parentNavigatorKey: rootNavigatorKey,
                  name: AppRoute.testHistory.name,
                  path: AppRoute.testHistory.path,
                  builder: (context, state) => BlocProvider(
                    create: (_) => DI().sl<TestHistoryBloc>(),
                    child: const TestHistoryScreen(),
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      name: AppRoute.testHistoryDetail.name,
                      path: ':attemptId',
                      builder: (context, state) {
                        final attemptId = state.pathParameters['attemptId']!;
                        return BlocProvider(
                          create: (_) => DI().sl<TestHistoryDetailBloc>(),
                          child: TestHistoryDetailScreen(attemptId: attemptId),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: AppRoute.testSetup.name,
      path: AppRoute.testSetup.path,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final String type = extra['type'] as String? ?? "";
        dynamic initData;
        if (type == "folder") {
          initData = FolderModel.fromJson(extra['data'] as Map<String, dynamic>);
        }
        if (type == "deck") {
          initData = DeckModel.fromJson(extra['data'] as Map<String, dynamic>);
        }
        return BlocProvider(
          create: (_) => DI().sl<TestSetupBloc>()..add(TestSetupInitialized(initData: initData)),
          child: const TakeTestScreen(),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: AppRoute.classTest.name,
      path: AppRoute.classTest.path,
      builder: (context, state) {
        final classId = state.pathParameters['classId']!;
        final assignmentId = state.pathParameters['assignmentId']!;
        final testId = state.pathParameters['testId']!;
        return ClassTestScreen(classId: classId, assignmentId: assignmentId, testId: testId);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: AppRoute.classroomDetail.name,
      path: AppRoute.classroomDetail.path,
      builder: (context, state) {
        final classId = state.pathParameters['id']!;
        final classModel = state.extra != null
            ? (state.extra is Map<String, dynamic>
                  ? ClassModel.fromJson(state.extra as Map<String, dynamic>)
                  : state.extra as ClassModel)
            : null;
        return ClassHubScreen(classId: classId, classModel: classModel);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: AppRoute.flashcardStudy.name,
      path: AppRoute.flashcardStudy.path,
      builder: (context, state) {
        final extraMap = state.extra as Map<String, dynamic>?;
        final sessionId = extraMap?['sessionId'] as String? ?? '';
        final rawCards = extraMap?['cards'] as List<dynamic>? ?? [];
        final cards = rawCards
            .map(
              (e) => e is FlashcardModel ? e : FlashcardModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        final rawLogs = extraMap?['reviewLogs'] as List<dynamic>? ?? [];
        final reviewLogs = rawLogs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return BlocProvider(
          create: (context) =>
              FlashcardStudyBloc(studyRepository: DI().sl<StudyRepository>())
                ..add(InitStudyEvent(sessionId: sessionId, cards: cards, reviewLogs: reviewLogs)),
          child: const FlashcardStudyScreen(),
        );
      },
    ),
  ];
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
