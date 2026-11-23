class DiscoverySuggestedClassModel {
  final String id;
  final String name;
  final String? description;
  final String? ownerName;
  final int memberCount;
  final bool isJoined;
  final bool isPending;
  final String joinCode;

  DiscoverySuggestedClassModel({
    required this.id,
    required this.name,
    this.description,
    this.ownerName,
    required this.memberCount,
    required this.isJoined,
    this.isPending = false,
    this.joinCode = '',
  });

  factory DiscoverySuggestedClassModel.fromJson(Map<String, dynamic> json) {
    return DiscoverySuggestedClassModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      ownerName: json['ownerName'] as String? ?? json['owner_name'] as String?,
      memberCount: json['memberCount'] as int? ?? json['member_count'] as int? ?? 0,
      isJoined: json['isJoined'] as bool? ?? json['is_joined'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? json['is_pending'] as bool? ?? false,
      joinCode: json['joinCode'] as String? ?? json['join_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (ownerName != null) 'ownerName': ownerName,
      'memberCount': memberCount,
      'isJoined': isJoined,
      'isPending': isPending,
      'joinCode': joinCode,
    };
  }
}
