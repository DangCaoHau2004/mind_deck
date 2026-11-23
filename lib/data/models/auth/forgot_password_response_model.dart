class ForgotPasswordResponseModel {
  final String message;
  final String email;
  final int cooldownRemaining;

  ForgotPasswordResponseModel({
    required this.message,
    required this.email,
    this.cooldownRemaining = 60,
  });

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponseModel(
      message: json['message'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cooldownRemaining: (json['cooldownRemaining'] as num?)?.toInt() ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'email': email, 'cooldownRemaining': cooldownRemaining};
  }
}
