import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/user_model.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'package:mind_deck/core/services/crashlytics_service.dart';
import 'package:mind_deck/data/repositories/profile_repository.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/data/repositories/tag_repository.dart';
import 'package:mind_deck/utils/timezone_utils.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final StorageService storageService;
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final NotificationRepository notificationRepository;
  final StudyRepository studyRepository;
  final TagRepository tagRepository;
  final ICrashlyticsService crashlyticsService;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late final AppLifecycleListener _lifecycleListener;
  bool _retryingProfile = false;

  AuthBloc({
    required this.storageService,
    required this.profileRepository,
    required this.authRepository,
    required this.notificationRepository,
    required this.studyRepository,
    required this.tagRepository,
    required this.crashlyticsService,
  }) : super(AuthUnknown()) {
    on<AppStarted>(_onAppStarted);
    on<ProfileRetried>(_onProfileRetried);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);

    // Tự thử tải lại hồ sơ khi mạng có lại hoặc khi quay lại app; handler tự bỏ qua nếu không offline.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) _retryProfile();
    });
    _lifecycleListener = AppLifecycleListener(onResume: _retryProfile);
  }

  void _retryProfile() {
    if (!isClosed) add(const ProfileRetried());
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await storageService.getAccessToken();
    if (token == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final profileResponse = await profileRepository.getProfile();
      final user = profileResponse.data;
      if (profileResponse.success && user != null) {
        await _completeSession(user, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    } on Failure catch (f) {
      // Lỗi tạm: giữ phiên, vào app ở trạng thái offline thay vì đẩy ra màn đăng nhập.
      emit(_isTemporary(f) ? AuthAuthenticatedOffline(failure: f) : const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onProfileRetried(ProfileRetried event, Emitter<AuthState> emit) async {
    if (state is! AuthAuthenticatedOffline || _retryingProfile) return;
    _retryingProfile = true;
    try {
      final token = await storageService.getAccessToken();
      if (token == null) {
        emit(const AuthUnauthenticated());
        return;
      }
      final profileResponse = await profileRepository.getProfile();
      final user = profileResponse.data;
      if (profileResponse.success && user != null) {
        await _completeSession(user, emit, requireOffline: true);
      } else {
        emit(const AuthUnauthenticated());
      }
    } on Failure catch (f) {
      // Lỗi tạm thì im lặng, chờ lần kích hoạt sau; lỗi thật của phiên thì đăng xuất.
      if (!_isTemporary(f)) emit(const AuthUnauthenticated());
    } catch (_) {
      // Lỗi bất ngờ khi thử lại: giữ trạng thái offline.
    } finally {
      _retryingProfile = false;
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) {
    // Có thể là tài khoản khác: bỏ danh sách tag đã nhớ của phiên trước
    tagRepository.clearCache();
    return _completeSession(event.user, emit);
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await authRepository.logout(fcmToken: fcmToken);
    } catch (_) {}
    await storageService.clearTokens();
    await studyRepository.localDataSource.clearAll();
    tagRepository.clearCache();
    await crashlyticsService.setUserId('');
    emit(AuthUnauthenticated(failure: event.failure));
  }

  /// Việc cần làm khi đã có hồ sơ: đăng ký nhận thông báo, gắn người dùng cho Crashlytics,
  /// đồng bộ phiên học dở, rồi vào trạng thái đã đăng nhập.
  /// [requireOffline]: chỉ làm khi vẫn đang offline, để lần thử lại chạy chậm không đè lên
  /// trạng thái đăng xuất xảy ra trong lúc chờ.
  Future<void> _completeSession(
    UserModel user,
    Emitter<AuthState> emit, {
    bool requireOffline = false,
  }) async {
    if (requireOffline && state is! AuthAuthenticatedOffline) return;
    await _registerFCMToken();
    await crashlyticsService.setUserId(user.id);
    unawaited(studyRepository.syncPendingSessions());
    if (requireOffline && state is! AuthAuthenticatedOffline) return;
    emit(AuthAuthenticated(user: user));
  }

  /// Lỗi tạm (mất mạng, timeout, 5xx, 429): không phải phiên hỏng nên không đăng xuất.
  bool _isTemporary(Failure f) {
    final status = f.statusCode;
    return f is NetworkFailure || (status != null && (status >= 500 || status == 429));
  }

  Future<void> _registerFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await notificationRepository.registerDevice(
          fcmToken: fcmToken,
          timezone: await localTimezone(),
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _connectivitySub.cancel();
    _lifecycleListener.dispose();
    return super.close();
  }
}
