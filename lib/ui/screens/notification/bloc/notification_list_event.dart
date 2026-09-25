import 'package:equatable/equatable.dart';

abstract class NotificationListEvent extends Equatable {
  const NotificationListEvent();

  @override
  List<Object?> get props => [];
}

class NotificationListLoadStarted extends NotificationListEvent {
  const NotificationListLoadStarted();
}

class NotificationListLoadMore extends NotificationListEvent {
  const NotificationListLoadMore();
}

class NotificationMarkAsRead extends NotificationListEvent {
  final String notificationId;

  const NotificationMarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllAsRead extends NotificationListEvent {
  const NotificationMarkAllAsRead();
}
