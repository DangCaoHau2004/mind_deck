import 'package:mind_deck/data/models/auth/auth_response_model.dart';

abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {
  final AuthResponseModel authResponse;
  SignUpSuccess({required this.authResponse});
}

class SignUpFailure extends SignUpState {
  final String error;
  SignUpFailure({required this.error});
}
