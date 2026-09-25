class ChangePasswordResponseModel {
  final String message;
  final int sessionsRevoked;
  final String accessToken;
  final String refreshToken;
  final String sid;

  ChangePasswordResponseModel({
    required this.message,
    required this.sessionsRevoked,
    required this.accessToken,
    required this.refreshToken,
    required this.sid,
  });

  factory ChangePasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponseModel(
      message: json['message'] as String? ?? '',
      sessionsRevoked: json['sessionsRevoked'] as int? ?? json['sessions_revoked'] as int? ?? 0,
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      sid: json['sid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'sessionsRevoked': sessionsRevoked,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'sid': sid,
    };
  }
}
