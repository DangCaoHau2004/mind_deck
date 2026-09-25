import 'package:mind_deck/data/models/user_model.dart';

class ResetPasswordResponseModel {
  final String message;
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String sid;

  ResetPasswordResponseModel({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.sid,
  });

  factory ResetPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponseModel(
      message: json['message'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      sid: json['sid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'sid': sid,
    };
  }
}
