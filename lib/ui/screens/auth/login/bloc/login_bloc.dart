import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/validators.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'login_event.dart';
import 'login_state.dart';

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
      emit(LoginFailure(error: 'auth_email_invalid'.tr));
      return;
    }

    if (password.isEmpty) {
      emit(LoginFailure(error: 'auth_password_empty'.tr));
      return;
    }

    emit(LoginLoading());
    try {
      final response = await authRepository.login(email: email, password: password);
      if (response.success && response.data != null) {
        final authData = response.data!;
        await storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        emit(LoginSuccess(authResponse: authData));
      } else {
        emit(LoginFailure(error: response.message ?? 'login_failed'.tr));
      }
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
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
        await storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        emit(LoginSuccess(authResponse: authData));
      } else {
        emit(LoginFailure(error: response.message ?? 'login_google_failed'.tr));
      }
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }
}
