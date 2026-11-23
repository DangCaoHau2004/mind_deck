import 'package:mind_deck/core/failures.dart';

abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordOtpSentSuccess extends ForgotPasswordState {
  final String email;
  final int cooldownRemaining;
  ForgotPasswordOtpSentSuccess({required this.email, this.cooldownRemaining = 60});
}

class ForgotPasswordOtpVerifySuccess extends ForgotPasswordState {
  final String email;
  final String resetToken;
  ForgotPasswordOtpVerifySuccess({required this.email, required this.resetToken});
}

class ForgotPasswordResetSuccess extends ForgotPasswordState {}

class ForgotPasswordFailure extends ForgotPasswordState {
  final Failure failure;
  ForgotPasswordFailure({required this.failure});
}
