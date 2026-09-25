import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/validators.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordBloc({required this.authRepository})
    : super(ForgotPasswordInitial()) {
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
      emit(ForgotPasswordFailure(error: 'auth_email_invalid'.tr));
      return;
    }

    emit(ForgotPasswordLoading());
    try {
      final response = await authRepository.forgotPassword(email: email);
      if (response.success) {
        final cooldown = response.data?.cooldownRemaining ?? 60;
        emit(
          ForgotPasswordOtpSentSuccess(
            email: event.email,
            cooldownRemaining: cooldown,
          ),
        );
      } else {
        emit(
          ForgotPasswordFailure(
            error: response.message ?? 'forgot_send_otp_failed'.tr,
          ),
        );
      }
    } catch (e) {
      emit(ForgotPasswordFailure(error: e.toString()));
    }
  }

  Future<void> _onOtpSubmitted(
    ForgotPasswordOtpSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (event.otp.length != 6) {
      emit(ForgotPasswordFailure(error: 'otp_invalid'.tr));
      return;
    }

    emit(ForgotPasswordLoading());
    try {
      final response = await authRepository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      if (response.success && response.data != null) {
        emit(
          ForgotPasswordOtpVerifySuccess(
            email: event.email,
            resetToken: response.data!.resetToken,
          ),
        );
      } else {
        emit(
          ForgotPasswordFailure(
            error: response.message ?? 'forgot_verify_otp_failed'.tr,
          ),
        );
      }
    } catch (e) {
      emit(ForgotPasswordFailure(error: e.toString()));
    }
  }

  Future<void> _onResetSubmitted(
    ForgotPasswordResetSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final newPassword = event.newPassword;
    final confirmPassword = event.confirmPassword;

    if (newPassword.length < 8 || newPassword.length > 64) {
      emit(
        ForgotPasswordFailure(
          error: 'auth_password_length_invalid'.tr,
        ),
      );
      return;
    }

    if (newPassword.contains(' ')) {
      emit(
        ForgotPasswordFailure(
          error: 'auth_password_no_space'.tr,
        ),
      );
      return;
    }

    if (!Validators.isValidPasswordCharacters(newPassword)) {
      emit(
        ForgotPasswordFailure(
          error: 'auth_password_invalid_characters'.tr,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      emit(
        ForgotPasswordFailure(
          error: 'new_password_not_match'.tr,
        ),
      );
      return;
    }

    if (event.resetToken.isEmpty) {
      emit(
        ForgotPasswordFailure(
          error: 'auth_reset_session_invalid'.tr,
        ),
      );
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
            error: response.message ?? 'forgot_reset_failed'.tr,
          ),
        );
      }
    } catch (e) {
      emit(ForgotPasswordFailure(error: e.toString()));
    }
  }
}
