import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/auth/auth_response_model.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final AuthResponseModel authResponse;
  LoginSuccess({required this.authResponse});
}

class LoginFailure extends LoginState {
  final Failure failure;
  LoginFailure({required this.failure});
}

class LoginCancelled extends LoginState {
  final String message;
  LoginCancelled({required this.message});
}
