import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/validators.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'login_event.dart';
import 'login_state.dart';
import 'package:mind_deck/core/failures.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  final StorageService storageService;

  LoginBloc({required this.authRepository, required this.storageService}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginWithGoogleSubmitted>(_onLoginWithGoogleSubmitted);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    final email = event.email.trim();
    final password = event.password;

    if (!Validators.isValidEmail(email)) {
      emit(LoginFailure(failure: ValidationFailure('auth_email_invalid'.tr)));
      return;
    }

    if (password.isEmpty) {
      emit(LoginFailure(failure: ValidationFailure('auth_password_empty'.tr)));
      return;
    }

    emit(LoginLoading());
    try {
      final response = await authRepository.login(email: email, password: password);
      if (response.success && response.data != null) {
        final authData = response.data!;
        if (authData.requireLogin) {
          emit(LoginFailure(failure: UnknownFailure(message: 'login_failed'.tr)));
          return;
        }
        await storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        emit(LoginSuccess(authResponse: authData));
      } else {
        emit(
          LoginFailure(
            failure: UnknownFailure(
              message: AppErrorCodes.requestFailed.tr,
              errorCode: AppErrorCodes.requestFailed,
            ),
          ),
        );
      }
    } on Failure catch (f) {
      emit(LoginFailure(failure: f));
    } catch (e) {
      emit(LoginFailure(failure: UnknownFailure(message: e.toString())));
    }
  }

  Future<void> _onLoginWithGoogleSubmitted(
    LoginWithGoogleSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final response = await authRepository.loginGoogle();
      if (response == null) {
        emit(LoginCancelled(message: 'login_google_cancelled'.tr));
        return;
      }
      if (response.success && response.data != null) {
        final authData = response.data!;
        if (authData.requireLogin) {
          emit(LoginFailure(failure: UnknownFailure(message: 'login_failed'.tr)));
          return;
        }
        await storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        emit(LoginSuccess(authResponse: authData));
      } else {
        emit(
          LoginFailure(
            failure: UnknownFailure(
              message: AppErrorCodes.requestFailed.tr,
              errorCode: AppErrorCodes.requestFailed,
            ),
          ),
        );
      }
    } on Failure catch (f) {
      emit(LoginFailure(failure: f));
    } catch (e) {
      emit(LoginFailure(failure: UnknownFailure(message: e.toString())));
    }
  }
}
