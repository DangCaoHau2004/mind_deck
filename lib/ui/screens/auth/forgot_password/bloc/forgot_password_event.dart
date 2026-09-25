abstract class ForgotPasswordEvent {}

class ForgotPasswordEmailSubmitted extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordEmailSubmitted({required this.email});
}

class ForgotPasswordOtpSubmitted extends ForgotPasswordEvent {
  final String email;
  final String otp;
  ForgotPasswordOtpSubmitted({required this.email, required this.otp});
}

class ForgotPasswordResetSubmitted extends ForgotPasswordEvent {
  final String email;
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  ForgotPasswordResetSubmitted({
    required this.email,
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });
}
