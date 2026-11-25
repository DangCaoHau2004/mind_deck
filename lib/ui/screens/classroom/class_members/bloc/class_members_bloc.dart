import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/page_info.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_members_event.dart';
import 'class_members_state.dart';

class ClassMembersBloc extends Bloc<ClassMembersEvent, ClassMembersState> {
  final ClassRepository repository;

  /// BE nhận tối đa 50 email mỗi lần; danh sách dài hơn được chia nhóm ở FE.
  static const int inviteBatchSize = 50;

  ClassMembersBloc({required this.repository}) : super(const ClassMembersState()) {
    on<ClassMembersLoaded>(_onClassMembersLoaded);
    on<ClassMembersRefreshed>(_onClassMembersRefreshed);
    on<MemberApproved>(_onMemberApproved);
    on<MemberKicked>(_onMemberKicked);
    on<MemberRoleUpdated>(_onMemberRoleUpdated);
    on<InviteRevoked>(_onInviteRevoked);
    on<InviteLookupRequested>(_onInviteLookup);
    on<InvitesSent>(_onInvitesSent);
    on<InviteRowsCleared>((event, emit) => emit(state.copyWith(inviteRows: const [])));
    on<ClassMembersMoreLoaded>(_onMoreLoaded);
    on<OwnerTransferred>(_onOwnerTransferred);
  }

  PageInfo _pageOf(MemberListKind kind) => switch (kind) {
    MemberListKind.joined => state.membersPage,
    MemberListKind.pending => state.pendingPage,
    MemberListKind.invited => state.invitedPage,
  };

  List<ClassMemberModel> _listOf(MemberListKind kind) => switch (kind) {
    MemberListKind.joined => state.members,
    MemberListKind.pending => state.pendingMembers,
    MemberListKind.invited => state.invitedMembers,
  };

  /// State với danh sách [kind] được thay bằng [list] (nếu có) và tiến độ trang [info].
  ClassMembersState _with(MemberListKind kind, PageInfo info, [List<ClassMemberModel>? list]) =>
      switch (kind) {
        MemberListKind.joined => state.copyWith(members: list, membersPage: info),
        MemberListKind.pending => state.copyWith(pendingMembers: list, pendingPage: info),
        MemberListKind.invited => state.copyWith(invitedMembers: list, invitedPage: info),
      };

  /// Tải trang kế tiếp của một danh sách (nối vào cuối, bỏ dòng trùng).
  Future<void> _onMoreLoaded(ClassMembersMoreLoaded event, Emitter<ClassMembersState> emit) async {
    final kind = event.kind;
    final info = _pageOf(kind);
    if (state.status != ClassMembersStatus.success || !info.canLoadMore) return;
    emit(_with(kind, info.copyWith(isLoadingMore: true)));
    try {
      final page = info.page + 1;
      final res = kind == MemberListKind.joined
          ? await repository.getMembers(event.classId, page: page)
          : await repository.getPendingMembers(
              event.classId,
              status: kind == MemberListKind.pending ? 'pending' : 'invited',
              page: page,
            );
      final current = _listOf(kind);
      final known = {for (final m in current) m.userId};
      emit(
        _with(kind, PageInfo.loaded(page: page, loaded: res.data.length, limit: classPageSize), [
          ...current,
          ...res.data.where((m) => !known.contains(m.userId)),
        ]),
      );
    } on Failure catch (f) {
      emit(
        _with(
          kind,
          info.copyWith(isLoadingMore: false),
        ).copyWith(notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  Future<void> _onOwnerTransferred(OwnerTransferred event, Emitter<ClassMembersState> emit) async {
    emit(state.copyWith(isProcessing: true));
    try {
      await repository.transferOwner(event.classId, event.userId);
      emit(
        state.copyWith(
          isProcessing: false,
          ownerTransferred: true,
          notice: 'Đã chuyển quyền chủ lớp',
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(isProcessing: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  Future<T?> _safe<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      return null;
    }
  }

  Future<void> _load(
    String classId,
    Emitter<ClassMembersState> emit, {
    required bool canManage,
    required bool refreshing,
  }) async {
    try {
      final membersRes = await repository.getMembers(classId);

      // Chỉ owner/admin mới gọi `members/pending` (học viên nhận 403 làm hỏng cả màn hình).
      var pending = state.pendingMembers;
      var invited = state.invitedMembers;
      var pendingPage = state.pendingPage;
      var invitedPage = state.invitedPage;
      PageInfo pageOf(List<ClassMemberModel> list) =>
          PageInfo.loaded(page: 1, loaded: list.length, limit: classPageSize);
      if (canManage) {
        final lists = await (
          _safe(() => repository.getPendingMembers(classId)),
          _safe(() => repository.getPendingMembers(classId, status: 'invited')),
        ).wait;
        if (lists.$1 != null) {
          pending = lists.$1!.data;
          pendingPage = pageOf(pending);
        }
        if (lists.$2 != null) {
          invited = lists.$2!.data;
          invitedPage = pageOf(invited);
        }
      } else {
        pending = const [];
        invited = const [];
        pendingPage = const PageInfo();
        invitedPage = const PageInfo();
      }

      emit(
        state.copyWith(
          status: ClassMembersStatus.success,
          members: membersRes.data,
          membersPage: pageOf(membersRes.data),
          pendingMembers: pending,
          pendingPage: pendingPage,
          invitedMembers: invited,
          invitedPage: invitedPage,
          canManage: canManage,
          isRefreshing: false,
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: ClassMembersStatus.failure,
          errorMessage: ClassErrorMessages.of(f),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onClassMembersLoaded(
    ClassMembersLoaded event,
    Emitter<ClassMembersState> emit,
  ) async {
    emit(state.copyWith(status: ClassMembersStatus.loading, canManage: event.canManage));
    await _load(event.classId, emit, canManage: event.canManage, refreshing: false);
  }

  Future<void> _onClassMembersRefreshed(
    ClassMembersRefreshed event,
    Emitter<ClassMembersState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _load(event.classId, emit, canManage: state.canManage, refreshing: true);
  }

  /// Thực hiện một thao tác lên thành viên rồi tải lại danh sách.
  Future<void> _act(
    Emitter<ClassMembersState> emit,
    String classId,
    Future<void> Function() action,
    String successNotice,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      await action();
      emit(state.copyWith(isProcessing: false, notice: successNotice));
      add(ClassMembersLoaded(classId, canManage: state.canManage));
    } on Failure catch (f) {
      emit(
        state.copyWith(isProcessing: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  Future<void> _onMemberApproved(MemberApproved event, Emitter<ClassMembersState> emit) => _act(
    emit,
    event.classId,
    () => repository.approveMember(event.classId, event.userId),
    'Đã duyệt thành viên',
  );

  Future<void> _onMemberKicked(MemberKicked event, Emitter<ClassMembersState> emit) => _act(
    emit,
    event.classId,
    () => repository.kickMember(event.classId, event.userId),
    'Đã xóa khỏi lớp',
  );

  Future<void> _onMemberRoleUpdated(MemberRoleUpdated event, Emitter<ClassMembersState> emit) =>
      _act(
        emit,
        event.classId,
        () => repository.updateMemberRole(event.classId, event.userId, event.newRole),
        'Đã đổi quyền',
      );

  Future<void> _onInviteRevoked(InviteRevoked event, Emitter<ClassMembersState> emit) async {
    // Cập nhật luôn dòng đang hiển thị trong màn mời (nếu có) về trạng thái có thể mời lại.
    final rows = [
      for (final r in state.inviteRows)
        if (r.userId == event.userId)
          InviteLookupRow(
            email: r.email,
            status: InviteLookupRow.ok,
            userId: r.userId,
            fullName: r.fullName,
          )
        else
          r,
    ];
    emit(state.copyWith(isProcessing: true));
    try {
      await repository.revokeInvite(event.classId, event.userId);
      emit(state.copyWith(isProcessing: false, inviteRows: rows, notice: 'Đã thu hồi lời mời'));
      if (state.canManage) add(ClassMembersLoaded(event.classId, canManage: true));
    } on Failure catch (f) {
      emit(
        state.copyWith(isProcessing: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  List<List<String>> _batches(List<String> emails) => [
    for (var i = 0; i < emails.length; i += inviteBatchSize)
      emails.sublist(i, i + inviteBatchSize > emails.length ? emails.length : i + inviteBatchSize),
  ];

  Future<void> _onInviteLookup(InviteLookupRequested event, Emitter<ClassMembersState> emit) async {
    if (event.emails.isEmpty) return;
    emit(state.copyWith(isInviteBusy: true));
    try {
      final rows = <InviteLookupRow>[];
      for (final batch in _batches(event.emails)) {
        final res = await repository.lookupInvites(event.classId, batch);
        rows.addAll(res.data ?? const []);
      }
      emit(state.copyWith(isInviteBusy: false, inviteRows: rows));
    } on Failure catch (f) {
      emit(
        state.copyWith(isInviteBusy: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  Future<void> _onInvitesSent(InvitesSent event, Emitter<ClassMembersState> emit) async {
    if (event.emails.isEmpty) return;
    emit(state.copyWith(isInviteBusy: true));
    try {
      final rows = <InviteLookupRow>[];
      for (final batch in _batches(event.emails)) {
        final res = await repository.sendInvites(event.classId, batch);
        rows.addAll(res.data ?? const []);
      }
      final sent = rows.where((r) => r.newlyInvited).length;
      emit(
        state.copyWith(
          isInviteBusy: false,
          inviteRows: rows,
          notice: sent > 0 ? 'Đã gửi lời mời cho $sent người' : 'Không có lời mời mới nào được gửi',
        ),
      );
      if (state.canManage) add(ClassMembersLoaded(event.classId, canManage: true));
    } on Failure catch (f) {
      emit(
        state.copyWith(isInviteBusy: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }
}
