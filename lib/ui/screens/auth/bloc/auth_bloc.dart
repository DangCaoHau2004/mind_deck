import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'package:mind_deck/core/services/crashlytics_service.dart';
import 'package:mind_deck/data/repositories/profile_repository.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final StorageService storageService;
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final NotificationRepository notificationRepository;
  final StudyRepository studyRepository;
  final ICrashlyticsService crashlyticsService;

  AuthBloc({
    required this.storageService,
    required this.profileRepository,
    required this.authRepository,
    required this.notificationRepository,
    required this.studyRepository,
    required this.crashlyticsService,
  }) : super(AuthUnknown()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await storageService.getAccessToken();
    if (token != null) {
      try {
        final profileResponse = await profileRepository.getProfile();
        if (profileResponse.success && profileResponse.data != null) {
          await _registerFCMToken();
          await crashlyticsService.setUserId(profileResponse.data!.id);
          unawaited(studyRepository.syncPendingSessions());
          emit(AuthAuthenticated(user: profileResponse.data!));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    await _registerFCMToken();
    await crashlyticsService.setUserId(event.user.id);
    unawaited(studyRepository.syncPendingSessions());
    emit(AuthAuthenticated(user: event.user));
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await authRepository.logout(fcmToken: fcmToken);
    } catch (_) {}
    await storageService.clearTokens();
    await studyRepository.localDataSource.clearAll();
    await crashlyticsService.setUserId('');
    emit(AuthUnauthenticated());
  }

  Future<void> _registerFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await notificationRepository.registerDevice(fcmToken: fcmToken);
      }
    } catch (_) {}
  }
}
