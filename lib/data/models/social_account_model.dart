class SocialAccountModel {
  final String id;
  final String userId;
  final String provider;
  final String providerId;

  SocialAccountModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerId,
  });

  factory SocialAccountModel.fromJson(Map<String, dynamic> json) {
    return SocialAccountModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      provider: json['provider'] as String? ?? 'google',
      providerId:
          json['providerId'] as String? ?? json['provider_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'provider': provider,
      'providerId': providerId,
    };
  }

  SocialAccountModel copyWith({
    String? id,
    String? userId,
    String? provider,
    String? providerId,
  }) {
    return SocialAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
    );
  }
}
