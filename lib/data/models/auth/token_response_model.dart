class TokenResponseModel {
  final String accessToken;

  TokenResponseModel({required this.accessToken});

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenResponseModel(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken};
  }
}
