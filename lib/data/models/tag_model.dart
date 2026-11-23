class TagModel {
  final String id;
  final String name;
  final String? color;
  final String? userId;
  final bool isSystem;
  final int searchVolume;

  const TagModel({
    required this.id,
    required this.name,
    this.color,
    this.userId,
    this.isSystem = false,
    this.searchVolume = 0,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String?,
      isSystem: json['isSystem'] as bool? ?? json['is_system'] as bool? ?? false,
      searchVolume: json['searchVolume'] as int? ?? json['search_volume'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (color != null) 'color': color,
      if (userId != null) 'userId': userId,
      'isSystem': isSystem,
      'searchVolume': searchVolume,
    };
  }

  TagModel copyWith({
    String? id,
    String? name,
    String? color,
    String? userId,
    bool? isSystem,
    int? searchVolume,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      isSystem: isSystem ?? this.isSystem,
      searchVolume: searchVolume ?? this.searchVolume,
    );
  }
}
