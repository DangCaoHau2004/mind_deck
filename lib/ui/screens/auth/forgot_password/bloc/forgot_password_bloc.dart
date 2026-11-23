import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/core/validators.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordBloc({required this.authRepository}) : super(ForgotPasswordInitial()) {
    on<ForgotPasswordEmailSubmitted>(_onEmailSubmitted);
    on<ForgotPasswordOtpSubmitted>(_onOtpSubmitted);
    on<ForgotPasswordResetSubmitted>(_onResetSubmitted);
  }

  Future<void> _onEmailSubmitted(
    ForgotPasswordEmailSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final email = event.email.trim();
    if (!Validators.isValidEmail(email)) {
      emit(ForgotPasswordFailure(failure: ValidationFailure('auth_email_invalid'.tr)));
      return;
    }

    emit(ForgotPasswordLoading());
    try {
      final response = await authRepository.forgotPassword(email: email);
      if (response.success) {
        final cooldown = response.data?.cooldownRemaining ?? 60;
        emit(ForgotPasswordOtpSentSuccess(email: event.email, cooldownRemaining: cooldown));
      } else {
        emit(
          ForgotPasswordFailure(
            failure: UnknownFailure(
              message: AppErrorCodes.requestFailed.tr,
              errorCode: AppErrorCodes.requestFailed,
            ),
          ),
        );
      }
    } on Failure catch (f) {
      emit(ForgotPasswordFailure(failure: f));
    } catch (e) {
      emit(ForgotPasswordFailure(failure: UnknownFailure(message: e.toString())));
    }
  }

  Future<void> _onOtpSubmitted(
    ForgotPasswordOtpSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (event.otp.length != 6) {
      emit(ForgotPasswordFailure(failure: ValidationFailure('otp_invalid'.tr)));
      return;
    }

    emit(ForgotPasswordLoading());
    try {
      final response = await authRepository.verifyOtp(email: event.email, otp: event.otp);
      if (response.success && response.data != null) {
        emit(
          ForgotPasswordOtpVerifySuccess(email: event.email, resetToken: response.data!.resetToken),
        );
      } else {
        emit(
          ForgotPasswordFailure(
            failure: UnknownFailure(
              message: AppErrorCodes.requestFailed.tr,
              errorCode: AppErrorCodes.requestFailed,
            ),
          ),
        );
      }
    } on Failure catch (f) {
      emit(ForgotPasswordFailure(failure: f));
    } catch (e) {
      emit(ForgotPasswordFailure(failure: UnknownFailure(message: e.toString())));
    }
  }

  Future<void> _onResetSubmitted(
    ForgotPasswordResetSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final newPassword = event.newPassword;
    final confirmPassword = event.confirmPassword;

    final passwordError = Validators.passwordError(newPassword);
    if (passwordError != null) {
      emit(ForgotPasswordFailure(failure: ValidationFailure(passwordError.tr)));
      return;
    }

    if (newPassword != confirmPassword) {
      emit(ForgotPasswordFailure(failure: ValidationFailure('new_password_not_match'.tr)));
      return;
    }

    if (event.resetToken.isEmpty) {
      emit(ForgotPasswordFailure(failure: ValidationFailure('auth_reset_session_invalid'.tr)));
      return;
    }

    emit(ForgotPasswordLoading());
    try {
      final response = await authRepository.resetPassword(
        email: event.email,
        resetToken: event.resetToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      if (response.success) {
        emit(ForgotPasswordResetSuccess());
      } else {
        emit(
          ForgotPasswordFailure(
            failure: UnknownFailure(
              message: AppErrorCodes.requestFailed.tr,
              errorCode: AppErrorCodes.requestFailed,
            ),
          ),
        );
      }
    } on Failure catch (f) {
      emit(ForgotPasswordFailure(failure: f));
    } catch (e) {
      emit(ForgotPasswordFailure(failure: UnknownFailure(message: e.toString())));
    }
  }
}
