import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';

enum ClassMembersStatus { initial, loading, success, failure }

class ClassMembersState extends Equatable {
  final ClassMembersStatus status;
  final List<ClassMemberModel> members;

  /// Yêu cầu xin vào lớp đang chờ duyệt (chỉ owner/admin).
  final List<ClassMemberModel> pendingMembers;

  /// Lời mời đã gửi nhưng người được mời chưa trả lời (chỉ owner/admin).
  final List<ClassMemberModel> invitedMembers;
  final String? errorMessage;

  /// Owner/admin: có tab chờ duyệt / đã mời.
  final bool canManage;

  // Hành động xử lý
  final bool isProcessing;
  final bool isRefreshing;

  // Mời bằng email
  final List<InviteLookupRow> inviteRows;
  final bool isInviteBusy;

  /// Thông báo một lần; `noticeId` tăng mỗi lần để listener bắt được cả khi nội dung trùng.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  const ClassMembersState({
    this.status = ClassMembersStatus.initial,
    this.members = const [],
    this.pendingMembers = const [],
    this.invitedMembers = const [],
    this.errorMessage,
    this.canManage = false,
    this.isProcessing = false,
    this.isRefreshing = false,
    this.inviteRows = const [],
    this.isInviteBusy = false,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  ClassMembersState copyWith({
    ClassMembersStatus? status,
    List<ClassMemberModel>? members,
    List<ClassMemberModel>? pendingMembers,
    List<ClassMemberModel>? invitedMembers,
    String? errorMessage,
    bool? canManage,
    bool? isProcessing,
    bool? isRefreshing,
    List<InviteLookupRow>? inviteRows,
    bool? isInviteBusy,
    String? notice,
    bool noticeIsError = false,
  }) {
    return ClassMembersState(
      status: status ?? this.status,
      members: members ?? this.members,
      pendingMembers: pendingMembers ?? this.pendingMembers,
      invitedMembers: invitedMembers ?? this.invitedMembers,
      errorMessage: errorMessage ?? this.errorMessage,
      canManage: canManage ?? this.canManage,
      isProcessing: isProcessing ?? this.isProcessing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      inviteRows: inviteRows ?? this.inviteRows,
      isInviteBusy: isInviteBusy ?? this.isInviteBusy,
      notice: notice,
      noticeIsError: noticeIsError,
      noticeId: notice != null ? noticeId + 1 : noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    members,
    pendingMembers,
    invitedMembers,
    errorMessage,
    canManage,
    isProcessing,
    isRefreshing,
    inviteRows,
    isInviteBusy,
    notice,
    noticeIsError,
    noticeId,
  ];
}
