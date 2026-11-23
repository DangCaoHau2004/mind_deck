import 'package:equatable/equatable.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthUnknown extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Có token nhưng chưa tải được hồ sơ vì lỗi tạm (mất mạng, timeout, 5xx, 429).
/// Vẫn cho vào app; hồ sơ được tải lại qua `ProfileRetried`.
class AuthAuthenticatedOffline extends AuthState {
  final Failure failure;

  const AuthAuthenticatedOffline({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class AuthUnauthenticated extends AuthState {
  /// Lý do bị đăng xuất (vd tài khoản bị khóa), hiện thành toast ở `main.dart`.
  final Failure? failure;

  const AuthUnauthenticated({this.failure});

  @override
  List<Object?> get props => [failure];
}
