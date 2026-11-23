import 'package:equatable/equatable.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final UserModel user;

  const LoggedIn({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Thử tải lại hồ sơ khi đang ở `AuthAuthenticatedOffline` (mạng có lại, quay lại app, người dùng làm mới).
class ProfileRetried extends AuthEvent {
  const ProfileRetried();
}

class LoggedOut extends AuthEvent {
  final Failure? failure;
  const LoggedOut({this.failure});

  @override
  List<Object?> get props => [failure];
}
