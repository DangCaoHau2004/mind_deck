import 'package:mind_deck/data/models/user_model.dart';

class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String sid;

  /// BE tạo tài khoản nhưng không mở được phiên (token rỗng): FE chuyển sang đăng nhập.
  final bool requireLogin;

  AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.sid,
    this.requireLogin = false,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String? ?? json['access_token'] as String? ?? '';
    final refreshToken = json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '';
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: accessToken,
      refreshToken: refreshToken,
      sid: json['sid'] as String? ?? '',
      requireLogin: json['requireLogin'] == true || accessToken.isEmpty || refreshToken.isEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'sid': sid,
      'requireLogin': requireLogin,
    };
  }
}
