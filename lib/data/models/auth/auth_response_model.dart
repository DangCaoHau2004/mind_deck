import 'package:mind_deck/data/models/user_model.dart';

class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String sid;

  AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.sid,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      sid: json['sid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'sid': sid,
    };
  }
}
