import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/auth/auth_response_model.dart';

abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {
  final AuthResponseModel authResponse;
  SignUpSuccess({required this.authResponse});
}

/// Tài khoản đã tạo nhưng chưa có phiên: người dùng phải đăng nhập lại.
class SignUpRequireLogin extends SignUpState {}

class SignUpFailure extends SignUpState {
  final Failure failure;
  SignUpFailure({required this.failure});
}
