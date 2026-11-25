import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/page_info.dart';

enum ClassMembersStatus { initial, loading, success, failure }

class ClassMembersState extends Equatable {
  final ClassMembersStatus status;
  final List<ClassMemberModel> members;

  /// Yêu cầu xin vào lớp đang chờ duyệt (chỉ owner/admin).
  final List<ClassMemberModel> pendingMembers;

  /// Lời mời đã gửi nhưng người được mời chưa trả lời (chỉ owner/admin).
  final List<ClassMemberModel> invitedMembers;

  /// Tiến độ tải thêm của từng danh sách (cuộn để tải thêm).
  final PageInfo membersPage;
  final PageInfo pendingPage;
  final PageInfo invitedPage;
  final String? errorMessage;

  /// Vừa chuyển quyền chủ lớp xong: màn thoát về hub để hub tải lại vai trò của tôi.
  final bool ownerTransferred;

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
    this.membersPage = const PageInfo(),
    this.pendingPage = const PageInfo(),
    this.invitedPage = const PageInfo(),
    this.errorMessage,
    this.ownerTransferred = false,
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
    PageInfo? membersPage,
    PageInfo? pendingPage,
    PageInfo? invitedPage,
    String? errorMessage,
    bool? ownerTransferred,
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
      membersPage: membersPage ?? this.membersPage,
      pendingPage: pendingPage ?? this.pendingPage,
      invitedPage: invitedPage ?? this.invitedPage,
      errorMessage: errorMessage ?? this.errorMessage,
      ownerTransferred: ownerTransferred ?? this.ownerTransferred,
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
    membersPage,
    pendingPage,
    invitedPage,
    errorMessage,
    ownerTransferred,
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
