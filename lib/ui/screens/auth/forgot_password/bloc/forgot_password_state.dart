abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordOtpSentSuccess extends ForgotPasswordState {
  final String email;
  final int cooldownRemaining;
  ForgotPasswordOtpSentSuccess({
    required this.email,
    this.cooldownRemaining = 60,
  });
}

class ForgotPasswordOtpVerifySuccess extends ForgotPasswordState {
  final String email;
  final String resetToken;
  ForgotPasswordOtpVerifySuccess({required this.email, required this.resetToken});
}

class ForgotPasswordResetSuccess extends ForgotPasswordState {}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String error;
  ForgotPasswordFailure({required this.error});
}
