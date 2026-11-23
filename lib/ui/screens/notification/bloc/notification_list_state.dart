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

  /// Tổng số thông báo trên server (`meta.total`).
  final int total;

  /// Số chưa đọc trên server (`meta.unreadCount`).
  final int unreadCount;

  /// Thông báo một lần dùng (toast); phân biệt các lần bằng `noticeId`.
  final String? notice;
  final int noticeId;

  const NotificationListSuccess({
    required this.notifications,
    required this.hasReachedMax,
    this.total = 0,
    this.unreadCount = 0,
    this.notice,
    this.noticeId = 0,
  });

  NotificationListSuccess copyWith({
    List<NotificationModel>? notifications,
    bool? hasReachedMax,
    int? total,
    int? unreadCount,
    String? notice,
    int? noticeId,
    bool clearNotice = false,
  }) {
    return NotificationListSuccess(
      notifications: notifications ?? this.notifications,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      notice: clearNotice ? null : (notice ?? this.notice),
      noticeId: noticeId ?? this.noticeId,
    );
  }

  @override
  List<Object?> get props => [notifications, hasReachedMax, total, unreadCount, notice, noticeId];
}

class NotificationListFailure extends NotificationListState {
  final String error;

  const NotificationListFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
