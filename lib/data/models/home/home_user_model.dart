import 'package:equatable/equatable.dart';

class HomeUserModel extends Equatable {
  final String fullName;
  final int currentStreak;
  final int unreadNotifications;
  final bool isIntact;

  const HomeUserModel({
    required this.fullName,
    required this.currentStreak,
    required this.unreadNotifications,
    this.isIntact = true,
  });

  factory HomeUserModel.fromJson(Map<String, dynamic> json) {
    return HomeUserModel(
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      currentStreak: json['currentStreak'] ?? json['current_streak'] ?? 0,
      unreadNotifications: json['unreadNotifications'] ?? json['unread_notifications'] ?? 0,
      isIntact: json['isIntact'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [fullName, currentStreak, unreadNotifications, isIntact];
}
