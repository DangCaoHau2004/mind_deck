import 'package:equatable/equatable.dart';

abstract class ClassMembersEvent extends Equatable {
  const ClassMembersEvent();

  @override
  List<Object?> get props => [];
}

class ClassMembersLoaded extends ClassMembersEvent {
  final String classId;

  /// Owner/admin: tải thêm danh sách chờ duyệt và đã mời (học viên gọi sẽ nhận 403).
  final bool canManage;

  const ClassMembersLoaded(this.classId, {this.canManage = false});

  @override
  List<Object?> get props => [classId, canManage];
}

class ClassMembersRefreshed extends ClassMembersEvent {
  final String classId;

  const ClassMembersRefreshed(this.classId);

  @override
  List<Object?> get props => [classId];
}

class MemberApproved extends ClassMembersEvent {
  final String classId;
  final String userId;

  const MemberApproved(this.classId, this.userId);

  @override
  List<Object?> get props => [classId, userId];
}

/// Một endpoint cho 3 việc theo trạng thái hiện tại: từ chối yêu cầu (pending), đuổi (approved).
class MemberKicked extends ClassMembersEvent {
  final String classId;
  final String userId;

  const MemberKicked(this.classId, this.userId);

  @override
  List<Object?> get props => [classId, userId];
}

class MemberRoleUpdated extends ClassMembersEvent {
  final String classId;
  final String userId;
  final String newRole;

  const MemberRoleUpdated(this.classId, this.userId, this.newRole);

  @override
  List<Object?> get props => [classId, userId, newRole];
}

/// Thu hồi lời mời (owner/admin hoặc chính người đã mời).
class InviteRevoked extends ClassMembersEvent {
  final String classId;
  final String userId;

  const InviteRevoked(this.classId, this.userId);

  @override
  List<Object?> get props => [classId, userId];
}

/// Tra cứu email trước khi mời (không ghi gì). Tự chia nhóm 50 email.
class InviteLookupRequested extends ClassMembersEvent {
  final String classId;
  final List<String> emails;

  const InviteLookupRequested(this.classId, this.emails);

  @override
  List<Object?> get props => [classId, emails];
}

/// Gửi lời mời; server tự phân loại lại và chỉ mời các dòng `ok`.
class InvitesSent extends ClassMembersEvent {
  final String classId;
  final List<String> emails;

  const InvitesSent(this.classId, this.emails);

  @override
  List<Object?> get props => [classId, emails];
}

class InviteRowsCleared extends ClassMembersEvent {}
