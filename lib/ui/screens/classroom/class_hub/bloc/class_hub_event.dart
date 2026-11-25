import 'package:equatable/equatable.dart';

abstract class ClassHubEvent extends Equatable {
  const ClassHubEvent();

  @override
  List<Object?> get props => [];
}

class ClassHubLoaded extends ClassHubEvent {}

/// Thành viên (không phải owner) tự rời lớp.
class ClassHubLeaveRequested extends ClassHubEvent {}

/// Chủ lớp xóa lớp (xóa mềm, xóa cứng sau 90 ngày). `reason` tùy chọn.
class ClassHubDeleteRequested extends ClassHubEvent {
  final String? reason;

  const ClassHubDeleteRequested({this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Người ngoài lớp (xem trước lớp công khai) bấm "Tham gia".
class ClassHubJoinRequested extends ClassHubEvent {}

/// Người ngoài lớp hủy yêu cầu xin vào lớp đang chờ duyệt của chính mình.
class ClassHubJoinRequestCancelled extends ClassHubEvent {}

/// Người được mời chấp nhận / từ chối lời mời.
class ClassHubInviteResponded extends ClassHubEvent {
  final bool accept;

  const ClassHubInviteResponded({required this.accept});

  @override
  List<Object?> get props => [accept];
}
