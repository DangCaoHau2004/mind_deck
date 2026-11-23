import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'class_hub_event.dart';
import 'class_hub_state.dart';

class ClassHubBloc extends Bloc<ClassHubEvent, ClassHubState> {
  final ClassRepository repository;
  final String classId;

  ClassHubBloc({required this.repository, required this.classId, ClassModel? initialClass})
    : super(ClassHubState(classModel: initialClass)) {
    on<ClassHubLoaded>(_onClassHubLoaded);
    on<ClassHubLeaveRequested>(_onLeave);
    on<ClassHubDeleteRequested>(_onDelete);
    on<ClassHubJoinRequested>(_onJoin);
    on<ClassHubInviteResponded>(_onInviteResponded);
  }

  Future<void> _onClassHubLoaded(ClassHubLoaded event, Emitter<ClassHubState> emit) async {
    emit(state.copyWith(status: ClassHubStatus.loading));
    try {
      ClassModel? currentClass = state.classModel;

      final res = await repository.getClassById(classId);
      if (res.success && res.data != null) {
        currentClass = res.data;
      }

      if (currentClass == null) {
        emit(
          state.copyWith(
            status: ClassHubStatus.failure,
            errorMessage: res.message ?? "Không tìm thấy thông tin lớp học",
          ),
        );
        return;
      }

      // Người ngoài lớp (xem trước): không có số liệu, không gọi API của thành viên.
      if (currentClass.isPreview) {
        emit(
          state.copyWith(status: ClassHubStatus.success, classModel: currentClass, pendingCount: 0),
        );
        return;
      }

      int pendingCount = 0;
      if (currentClass.isTeacher) {
        // Chỉ giảng viên gọi được `members/pending` (học viên nhận 403).
        try {
          final pendingRes = await repository.getPendingMembers(currentClass.id);
          if (pendingRes.success) pendingCount = pendingRes.data.length;
        } on Failure {
          // Không có số chờ duyệt vẫn dùng được hub.
        }
      }

      emit(
        state.copyWith(
          status: ClassHubStatus.success,
          classModel: currentClass,
          pendingCount: pendingCount,
        ),
      );
    } on Failure catch (f) {
      if (ClassErrorMessages.isClassGone(f)) {
        emit(
          state.copyWith(
            status: ClassHubStatus.failure,
            errorMessage: ClassErrorMessages.of(f),
            exit: ClassHubExit.gone,
            notice: ClassErrorMessages.of(f),
            noticeIsError: true,
          ),
        );
        return;
      }
      emit(state.copyWith(status: ClassHubStatus.failure, errorMessage: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onLeave(ClassHubLeaveRequested event, Emitter<ClassHubState> emit) async {
    emit(state.copyWith(isBusy: true));
    try {
      await repository.leaveClass(classId);
      emit(state.copyWith(isBusy: false, exit: ClassHubExit.left, notice: 'Đã rời lớp học'));
    } on Failure catch (f) {
      emit(state.copyWith(isBusy: false, notice: ClassErrorMessages.of(f), noticeIsError: true));
    }
  }

  Future<void> _onDelete(ClassHubDeleteRequested event, Emitter<ClassHubState> emit) async {
    emit(state.copyWith(isBusy: true));
    try {
      await repository.deleteClass(classId, reason: event.reason);
      emit(state.copyWith(isBusy: false, exit: ClassHubExit.deleted, notice: 'Đã xóa lớp học'));
    } on Failure catch (f) {
      emit(state.copyWith(isBusy: false, notice: ClassErrorMessages.of(f), noticeIsError: true));
    }
  }

  Future<void> _onJoin(ClassHubJoinRequested event, Emitter<ClassHubState> emit) async {
    emit(state.copyWith(isBusy: true));
    try {
      final res = await repository.joinClass(classId: classId);
      final pending = res.data?.isPending ?? false;
      emit(
        state.copyWith(
          isBusy: false,
          notice: pending
              ? 'Đã gửi yêu cầu tham gia! Vui lòng chờ giáo viên duyệt.'
              : 'Đã tham gia lớp học!',
        ),
      );
      add(ClassHubLoaded());
    } on Failure catch (f) {
      emit(state.copyWith(isBusy: false, notice: ClassErrorMessages.of(f), noticeIsError: true));
    }
  }

  Future<void> _onInviteResponded(
    ClassHubInviteResponded event,
    Emitter<ClassHubState> emit,
  ) async {
    emit(state.copyWith(isBusy: true));
    try {
      if (event.accept) {
        final res = await repository.acceptInvite(classId);
        final pending = res.data?.status == JoinResult.pending;
        emit(
          state.copyWith(
            isBusy: false,
            notice: pending
                ? 'Đã chấp nhận lời mời. Vui lòng chờ giáo viên duyệt.'
                : 'Đã tham gia lớp học!',
          ),
        );
        add(ClassHubLoaded());
      } else {
        await repository.declineInvite(classId);
        emit(
          state.copyWith(isBusy: false, exit: ClassHubExit.declined, notice: 'Đã từ chối lời mời'),
        );
      }
    } on Failure catch (f) {
      emit(state.copyWith(isBusy: false, notice: ClassErrorMessages.of(f), noticeIsError: true));
    }
  }
}
