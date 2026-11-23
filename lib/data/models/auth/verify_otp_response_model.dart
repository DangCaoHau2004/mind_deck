class VerifyOtpResponseModel {
  final String email;
  final String resetToken;

  VerifyOtpResponseModel({required this.email, required this.resetToken});

  factory VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseModel(
      email: json['email'] as String? ?? '',
      resetToken: json['resetToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'resetToken': resetToken};
  }
}
