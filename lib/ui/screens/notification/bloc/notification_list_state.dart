import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/notification_model.dart';

abstract class NotificationListState extends Equatable {
  const NotificationListState();

  @override
  List<Object?> get props => [];
}

class NotificationListInitial extends NotificationListState {}

class NotificationListLoading extends NotificationListState {}

class NotificationListSuccess extends NotificationListState {
  final List<NotificationModel> notifications;
  final bool hasReachedMax;
  final int currentPage;

  const NotificationListSuccess({
    required this.notifications,
    required this.hasReachedMax,
    required this.currentPage,
  });

  NotificationListSuccess copyWith({
    List<NotificationModel>? notifications,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return NotificationListSuccess(
      notifications: notifications ?? this.notifications,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [notifications, hasReachedMax, currentPage];
}

class NotificationListFailure extends NotificationListState {
  final String error;

  const NotificationListFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
