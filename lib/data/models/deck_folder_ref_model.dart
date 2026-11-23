/// Thư mục chứa một bộ thẻ (rút gọn, BE trả trong `deck.folders` cho chủ sở hữu).
class DeckFolderRef {
  final String id;
  final String name;
  final String color;
  final String icon;

  const DeckFolderRef({
    required this.id,
    required this.name,
    this.color = '#1565C0',
    this.icon = 'default_icon',
  });

  factory DeckFolderRef.fromJson(Map<String, dynamic> json) => DeckFolderRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    color: json['color'] as String? ?? '#1565C0',
    icon: json['icon'] as String? ?? 'default_icon',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color, 'icon': icon};
}
