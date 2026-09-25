import 'package:equatable/equatable.dart';
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

class LoggedOut extends AuthEvent {}
