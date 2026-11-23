import 'package:equatable/equatable.dart';

enum HomeActivityType { assignment, newDecks, none }

/// Hoạt động nổi bật của lớp; `type` lạ hoặc thiếu khóa → `none`.
class HomeClassActivity extends Equatable {
  final HomeActivityType type;
  final String? assignmentId;
  final String title;
  final DateTime? endAt;
  final bool endsToday;
  final int count;

  const HomeClassActivity({
    this.type = HomeActivityType.none,
    this.assignmentId,
    this.title = '',
    this.endAt,
    this.endsToday = false,
    this.count = 0,
  });

  factory HomeClassActivity.fromJson(dynamic json) {
    if (json is! Map) return const HomeClassActivity();
    switch (json['type']) {
      case 'assignment':
        return HomeClassActivity(
          type: HomeActivityType.assignment,
          assignmentId: json['assignmentId']?.toString(),
          title: json['title']?.toString() ?? '',
          endAt: DateTime.tryParse(json['endAt']?.toString() ?? '')?.toLocal(),
          endsToday: json['endsToday'] == true,
        );
      case 'new_decks':
        final count = (json['count'] as num?)?.toInt() ?? 0;
        if (count <= 0) return const HomeClassActivity();
        return HomeClassActivity(type: HomeActivityType.newDecks, count: count);
      default:
        return const HomeClassActivity();
    }
  }

  @override
  List<Object?> get props => [type, assignmentId, title, endAt, endsToday, count];
}

class HomeClassModel extends Equatable {
  final String id;
  final String name;
  final HomeClassActivity activity;

  const HomeClassModel({
    required this.id,
    required this.name,
    this.activity = const HomeClassActivity(),
  });

  factory HomeClassModel.fromJson(Map<String, dynamic> json) {
    return HomeClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      activity: HomeClassActivity.fromJson(json['activity']),
    );
  }

  @override
  List<Object?> get props => [id, name, activity];
}
