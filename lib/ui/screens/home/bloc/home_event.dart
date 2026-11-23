import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Tải lần đầu (chưa có dữ liệu thì màn hiện skeleton).
class HomeLoadStarted extends HomeEvent {
  const HomeLoadStarted();
}

/// Bỏ một phiên flashcard đang dở khỏi khối "Đang học dở" (`DELETE /study/:sessionId`).
class HomeContinueSessionDismissed extends HomeEvent {
  final String sessionId;

  const HomeContinueSessionDismissed(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Kéo để làm mới: giữ dữ liệu cũ trên màn, lỗi thì vẫn giữ dữ liệu cũ.
/// Màn chờ `isRefreshing` về false để tắt vòng xoay.
class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}
