import 'package:equatable/equatable.dart';

abstract class ClassListEvent extends Equatable {
  const ClassListEvent();

  @override
  List<Object?> get props => [];
}

class ClassListLoaded extends ClassListEvent {}

/// Cuộn gần cuối danh sách lớp: tải trang kế tiếp.
class ClassListMoreLoaded extends ClassListEvent {}

/// Bấm "Tải thêm lời mời": tải trang lời mời kế tiếp.
class ClassInvitationsMoreLoaded extends ClassListEvent {}

/// Tham gia lớp bằng mã lớp (`joinCode`) HOẶC bằng `classId` (lớp công khai).
class ClassJoined extends ClassListEvent {
  final String? classId;
  final String? joinCode;

  const ClassJoined({this.classId, this.joinCode});

  @override
  List<Object?> get props => [classId, joinCode];
}

class ClassCreated extends ClassListEvent {
  final String name;
  final String? description;
  final bool requireApproval;
  final bool isPublic;

  const ClassCreated({
    required this.name,
    this.description,
    this.requireApproval = false,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [name, description, requireApproval, isPublic];
}

/// Chấp nhận / từ chối lời mời vào lớp.
/// `notify = true` (danh sách lời mời ở màn lớp) -> bloc phát `notice` để màn hình hiện toast;
/// hộp thoại tham gia tự xử lý qua `processSuccess` / `processErrorMessage`.
class ClassInvitationResponded extends ClassListEvent {
  final String classId;
  final bool accept;
  final bool notify;

  const ClassInvitationResponded({
    required this.classId,
    required this.accept,
    this.notify = false,
  });

  @override
  List<Object?> get props => [classId, accept, notify];
}
