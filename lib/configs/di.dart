import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mind_deck/configs/dio/app_dio.dart';
import 'package:mind_deck/configs/notification_config.dart';
import 'package:mind_deck/data/data_sources/local/study_local_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/study_remote_data_source.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/core/services/crashlytics_service.dart';
import 'package:mind_deck/services/ad_service.dart';
import 'package:mind_deck/services/media_service.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'package:mind_deck/services/tts_service.dart';
import 'package:mind_deck/navigation/app_router.dart';
import 'package:mind_deck/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/google_auth_remote_datasource.dart';
import 'package:mind_deck/data/data_sources/remote/profile_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/session_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/folder_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/deck_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/image_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/shared_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/sync_remote_data_source.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'package:mind_deck/data/repositories/profile_repository.dart';
import 'package:mind_deck/data/repositories/session_repository.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/image_repository.dart';
import 'package:mind_deck/data/repositories/shared_repository.dart';
import 'package:mind_deck/data/repositories/sync_repository.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/login/bloc/login_bloc.dart';
import 'package:mind_deck/ui/screens/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_bloc.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_form/bloc/folder_form_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/bloc/deck_form_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_bloc.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_bloc.dart';
import 'package:mind_deck/data/data_sources/remote/test_remote_data_source.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/data/data_sources/remote/report_remote_data_source.dart';
import 'package:mind_deck/data/repositories/report_repository.dart';
import 'package:mind_deck/ui/screens/report/report_history/bloc/report_history_bloc.dart';
import 'package:mind_deck/ui/screens/report/report_form/bloc/report_form_bloc.dart';
import 'package:mind_deck/ui/screens/report/report_detail/bloc/report_detail_bloc.dart';
import 'package:mind_deck/data/data_sources/remote/discovery_remote_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/search_remote_data_source.dart';
import 'package:mind_deck/data/repositories/discovery_repository.dart';
import 'package:mind_deck/data/repositories/search_repository.dart';
import 'package:mind_deck/data/data_sources/remote/tag_remote_data_source.dart';
import 'package:mind_deck/data/repositories/tag_repository.dart';
import 'package:mind_deck/ui/screens/discover/bloc/discover_bloc.dart';
import 'package:mind_deck/ui/screens/discover/popular_content/bloc/discover_popular_bloc.dart';
import 'package:mind_deck/data/data_sources/remote/class_remote_data_source.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/data_sources/remote/stats_remote_data_source.dart';
import 'package:mind_deck/data/repositories/stats_repository.dart';
import 'package:mind_deck/data/data_sources/remote/notification_remote_data_source.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';
import 'package:mind_deck/ui/screens/notification/bloc/notification_list_bloc.dart';
import 'package:mind_deck/ui/screens/notification/settings/bloc/notification_settings_bloc.dart';
import 'package:mind_deck/data/data_sources/remote/document_import_remote_data_source.dart';
import 'package:mind_deck/data/repositories/document_import_repository.dart';
import 'package:mind_deck/ui/screens/document_import/bloc/document_import_bloc.dart';
import 'package:mind_deck/ui/screens/document_import/bloc/document_import_draft_bloc.dart';
import 'package:mind_deck/ui/screens/document_import/bloc/document_import_list_bloc.dart';
import 'package:mind_deck/data/data_sources/remote/home_remote_data_source.dart';
import 'package:mind_deck/data/repositories/home_repository.dart';
import 'package:mind_deck/ui/screens/home/bloc/home_bloc.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_hub/bloc/class_hub_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/bloc/class_tests_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_settings/bloc/class_settings_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/image_search/image_search_bloc.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/data/data_sources/remote/coin_remote_data_source.dart';
import 'package:mind_deck/data/repositories/coin_repository.dart';
import 'package:mind_deck/services/coin_reward_service.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/ui/screens/coin/bloc/coin_cubit.dart';

class DI {
  static DI? _instance;

  DI._();

  factory DI() {
    _instance ??= DI._();
    return _instance!;
  }

  final sl = GetIt.instance;

  Future<void> init() async {
    await _initHive();

    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

    //services
    sl.registerLazySingleton<ImagePicker>(() => ImagePicker());
    sl.registerLazySingleton<MediaService>(() => MediaService(picker: sl()));
    sl.registerLazySingleton<StorageService>(() => StorageService());
    sl.registerLazySingleton<TTSService>(() => TTSService());
    sl.registerLazySingleton<AdService>(() => AdService());
    sl.registerLazySingleton<CoinRemoteDataSource>(() => CoinRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<CoinRepository>(() => CoinRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<CoinRewardService>(
      () => CoinRewardService(
        repository: sl(),
        userId: () {
          final auth = sl<AuthBloc>().state;
          return auth is AuthAuthenticated ? auth.user.id : null;
        },
        playVideo: (userId, placement) =>
            sl<AdService>().showRewarded(AdUnit.rewardedCoin, userId: userId, placement: placement),
      ),
    );
    sl.registerLazySingleton<Dio>(() => AppDio.setupDio());
    sl.registerLazySingleton<AppRouter>(() => AppRouter());

    sl.registerLazySingleton<GoogleAuthRemoteDataSource>(() => GoogleAuthRemoteDataSourceImpl());

    sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
    sl.registerLazySingleton<NotificationConfig>(() => NotificationConfig(prefs: sl(), fcm: sl()));

    // Data Sources
    sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<SessionRemoteDataSource>(() => SessionRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<FolderRemoteDataSource>(() => FolderRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<DeckRemoteDataSource>(() => DeckRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<ImageRemoteDataSource>(() => ImageRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<SharedRemoteDataSource>(() => SharedRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<TagRemoteDataSource>(() => TagRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<SyncRemoteDataSource>(() => SyncRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<TestRemoteDataSource>(() => TestRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<ReportRemoteDataSource>(() => ReportRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<DocumentImportRemoteDataSource>(
      () => DocumentImportRemoteDataSourceImpl(dio: sl()),
    );
    sl.registerLazySingleton<DiscoveryRemoteDataSource>(
      () => DiscoveryRemoteDataSourceImpl(dio: sl()),
    );
    sl.registerLazySingleton<SearchRemoteDataSource>(() => SearchRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<ClassRemoteDataSource>(() => ClassRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<StatsRemoteDataSource>(() => StatsRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(dio: sl()),
    );
    sl.registerLazySingleton<HomeRemoteDataSource>(() => HomeRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<StudyRemoteDataSource>(() => StudyRemoteDataSourceImpl(dio: sl()));
    sl.registerLazySingleton<StudyLocalDataSource>(
      () => StudyLocalDataSourceImpl(studyBox: sl(instanceName: 'studyBox')),
    );

    // Repositories
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl(), googleAuthRemoteDataSource: sl()),
    );
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(remoteDataSource: sl()),
    );
    sl.registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(remoteDataSource: sl()),
    );
    sl.registerLazySingleton<FolderRepository>(() => FolderRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<DeckRepository>(() => DeckRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<ImageRepository>(() => ImageRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<TagRepository>(() => TagRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<SharedRepository>(() => SharedRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<SyncRepository>(() => SyncRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<TestRepository>(() => TestRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<DocumentImportRepository>(
      () => DocumentImportRepositoryImpl(remoteDataSource: sl()),
    );
    sl.registerLazySingleton<DiscoveryRepository>(
      () => DiscoveryRepositoryImpl(remoteDataSource: sl()),
    );
    sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<ClassRepository>(() => ClassRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(remoteDataSource: sl()));
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(remoteDataSource: sl()),
    );
    sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(remoteDataSource: sl()));

    sl.registerLazySingleton<StudyRepository>(
      () => StudyRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
    );

    // Services
    sl.registerLazySingleton<ICrashlyticsService>(() => CrashlyticsService());

    // Blocs
    sl.registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        storageService: sl(),
        profileRepository: sl(),
        authRepository: sl(),
        notificationRepository: sl(),
        studyRepository: sl(),
        tagRepository: sl(),
        crashlyticsService: sl(),
      ),
    );
    sl.registerFactory<LoginBloc>(() => LoginBloc(authRepository: sl(), storageService: sl()));
    sl.registerFactory<SignUpBloc>(() => SignUpBloc(authRepository: sl(), storageService: sl()));
    sl.registerFactory<ForgotPasswordBloc>(() => ForgotPasswordBloc(authRepository: sl()));

    sl.registerFactory<FolderFormBloc>(
      () => FolderFormBloc(folderRepository: sl(), tagRepository: sl()),
    );
    sl.registerFactory(() => DeckFormBloc(deckRepository: sl(), tagRepository: sl()));
    sl.registerFactory(() => ImageSearchBloc(repository: sl()));
    sl.registerFactory<FolderDetailBloc>(
      () => FolderDetailBloc(folderRepository: sl(), sharedRepository: sl()),
    );
    sl.registerFactory<DeckDetailBloc>(
      () => DeckDetailBloc(deckRepository: sl(), sharedRepository: sl()),
    );
    sl.registerFactory<LibraryFolderBloc>(() => LibraryFolderBloc(folderRepository: sl()));
    sl.registerFactory<LibraryDeckBloc>(() => LibraryDeckBloc(deckRepository: sl()));
    sl.registerFactory<TestSetupBloc>(
      () => TestSetupBloc(testRepository: sl(), deckRepository: sl(), folderRepository: sl()),
    );
    sl.registerFactory<ReportHistoryBloc>(() => ReportHistoryBloc(reportRepository: sl()));
    sl.registerFactory<ReportFormBloc>(
      () => ReportFormBloc(reportRepository: sl(), imageRepository: sl()),
    );
    sl.registerFactory<ReportDetailBloc>(() => ReportDetailBloc(reportRepository: sl()));
    sl.registerFactory<DiscoverBloc>(
      () => DiscoverBloc(discoveryRepository: sl(), searchRepository: sl()),
    );
    sl.registerFactory<DiscoverPopularBloc>(() => DiscoverPopularBloc(discoveryRepository: sl()));
    sl.registerFactory<ClassListBloc>(() => ClassListBloc(repository: sl()));
    sl.registerFactoryParam<ClassHubBloc, String, ClassModel?>(
      (classId, initialClass) =>
          ClassHubBloc(repository: sl(), classId: classId, initialClass: initialClass),
    );
    sl.registerFactory<ClassMembersBloc>(() => ClassMembersBloc(repository: sl()));
    sl.registerFactory<ClassMaterialsBloc>(() => ClassMaterialsBloc(repository: sl()));
    sl.registerFactory<ClassAssignmentsBloc>(() => ClassAssignmentsBloc(repository: sl()));
    sl.registerFactory<ClassLeaderboardBloc>(() => ClassLeaderboardBloc(repository: sl()));
    sl.registerFactory<ClassAnalyticsBloc>(() => ClassAnalyticsBloc(repository: sl()));
    sl.registerFactory<ClassSettingsBloc>(() => ClassSettingsBloc(repository: sl()));
    sl.registerFactory<ClassTestBloc>(
      () => ClassTestBloc(testRepository: sl(), classRepository: sl()),
    );
    sl.registerFactory<ClassTestsBloc>(() => ClassTestsBloc(repository: sl()));
    sl.registerFactory<NotificationListBloc>(
      () => NotificationListBloc(notificationRepository: sl()),
    );
    sl.registerFactory<CoinCubit>(() => CoinCubit(repository: sl()));
    sl.registerFactory<DocumentImportBloc>(() => DocumentImportBloc(repository: sl(), prefs: sl()));
    sl.registerFactory<DocumentImportDraftBloc>(() => DocumentImportDraftBloc(repository: sl()));
    sl.registerFactory<DocumentImportListBloc>(() => DocumentImportListBloc(repository: sl()));
    sl.registerFactory<NotificationSettingsBloc>(
      () => NotificationSettingsBloc(notificationRepository: sl()),
    );
    sl.registerFactory<HomeBloc>(() => HomeBloc(repository: sl(), studyRepository: sl()));
    sl.registerFactory<TestHistoryBloc>(() => TestHistoryBloc(testRepository: sl()));
    sl.registerFactory<TestHistoryDetailBloc>(() => TestHistoryDetailBloc(testRepository: sl()));
  }

  Future<void> _initHive() async {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    final studyBox = await Hive.openBox('study_session');
    sl.registerLazySingleton<Box>(() => studyBox, instanceName: 'studyBox');
  }
}
