import 'package:equatable/equatable.dart';

class HomeRecentDeckModel extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int studiedCards;
  final int totalCards;

  const HomeRecentDeckModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.studiedCards = 0,
    this.totalCards = 0,
  });

  double get progress => totalCards <= 0 ? 0 : (studiedCards / totalCards).clamp(0.0, 1.0);

  factory HomeRecentDeckModel.fromJson(Map<String, dynamic> json) {
    return HomeRecentDeckModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'default_deck',
      color: json['color'] ?? '#02569B',
      studiedCards: (json['studiedCards'] as num?)?.toInt() ?? 0,
      totalCards: (json['totalCards'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, studiedCards, totalCards];
}
