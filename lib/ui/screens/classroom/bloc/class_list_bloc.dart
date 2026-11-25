import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/models/page_info.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_list_event.dart';
import 'class_list_state.dart';

class ClassListBloc extends Bloc<ClassListEvent, ClassListState> {
  final ClassRepository repository;

  ClassListBloc({required this.repository}) : super(const ClassListState()) {
    on<ClassListLoaded>(_onClassListLoaded);
    on<ClassJoined>(_onClassJoined);
    on<ClassCreated>(_onClassCreated);
    on<ClassInvitationResponded>(_onInvitationResponded);
    on<ClassListMoreLoaded>(_onMoreClasses);
    on<ClassInvitationsMoreLoaded>(_onMoreInvitations);
  }

  /// Tải trang lớp kế tiếp (nối vào cuối, bỏ dòng trùng vì danh sách có thể dịch chuyển).
  Future<void> _onMoreClasses(ClassListMoreLoaded event, Emitter<ClassListState> emit) async {
    final info = state.classesPage;
    if (state.status != ClassListStatus.success || !info.canLoadMore) return;
    emit(state.copyWith(classesPage: info.copyWith(isLoadingMore: true)));
    try {
      final page = info.page + 1;
      final res = await repository.getClasses(page: page);
      final known = {for (final c in state.classes) c.id};
      emit(
        state.copyWith(
          classes: [...state.classes, ...res.data.where((c) => !known.contains(c.id))],
          classesPage: PageInfo.loaded(page: page, loaded: res.data.length, limit: classPageSize),
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          classesPage: info.copyWith(isLoadingMore: false),
          notice: ClassErrorMessages.of(f),
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onMoreInvitations(
    ClassInvitationsMoreLoaded event,
    Emitter<ClassListState> emit,
  ) async {
    final info = state.invitationsPage;
    if (state.status != ClassListStatus.success || !info.canLoadMore) return;
    emit(state.copyWith(invitationsPage: info.copyWith(isLoadingMore: true)));
    try {
      final page = info.page + 1;
      final res = await repository.getInvitations(page: page);
      final known = {for (final i in state.invitations) i.classId};
      emit(
        state.copyWith(
          invitations: [...state.invitations, ...res.data.where((i) => !known.contains(i.classId))],
          invitationsPage: PageInfo.loaded(
            page: page,
            loaded: res.data.length,
            limit: classPageSize,
          ),
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          invitationsPage: info.copyWith(isLoadingMore: false),
          notice: ClassErrorMessages.of(f),
          noticeIsError: true,
        ),
      );
    }
  }

  Future<void> _onClassListLoaded(ClassListLoaded event, Emitter<ClassListState> emit) async {
    emit(state.copyWith(status: ClassListStatus.loading));
    try {
      final results = await (
        repository.getClasses(),
        // Lời mời hỏng không được làm hỏng cả danh sách lớp.
        repository
            .getInvitations()
            .then<List<ClassInvitationModel>?>((r) => r.data)
            .catchError((_) => null),
      ).wait;

      final response = results.$1;
      if (response.success) {
        emit(
          state.copyWith(
            status: ClassListStatus.success,
            classes: response.data,
            classesPage: PageInfo.loaded(
              page: 1,
              loaded: response.data.length,
              limit: classPageSize,
            ),
            invitations: results.$2 ?? state.invitations,
            invitationsPage: results.$2 == null
                ? state.invitationsPage
                : PageInfo.loaded(page: 1, loaded: results.$2!.length, limit: classPageSize),
          ),
        );
      } else {
        emit(state.copyWith(status: ClassListStatus.failure, errorMessage: response.message));
      }
    } on Failure catch (f) {
      emit(state.copyWith(status: ClassListStatus.failure, errorMessage: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onClassJoined(ClassJoined event, Emitter<ClassListState> emit) async {
    emit(state.copyWith(isProcessing: true, processSuccess: false));
    try {
      final response = await repository.joinClass(joinCode: event.joinCode, classId: event.classId);
      if (response.success) {
        emit(state.copyWith(isProcessing: false, processSuccess: true, joinResult: response.data));
        add(ClassListLoaded()); // Reload list after joining
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Mã lớp không hợp lệ',
          ),
        );
      }
    } on Failure catch (f) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onInvitationResponded(
    ClassInvitationResponded event,
    Emitter<ClassListState> emit,
  ) async {
    emit(
      state.copyWith(isProcessing: true, processSuccess: false, respondingClassId: event.classId),
    );
    try {
      if (event.accept) {
        final res = await repository.acceptInvite(event.classId);
        final result = res.data;
        emit(
          state.copyWith(
            isProcessing: false,
            processSuccess: true,
            joinResult: result,
            notice: event.notify
                ? (result?.isPending ?? false)
                      ? 'Đã chấp nhận lời mời. Vui lòng chờ giáo viên duyệt.'
                      : 'Đã tham gia lớp học!'
                : null,
          ),
        );
      } else {
        await repository.declineInvite(event.classId);
        emit(
          state.copyWith(
            isProcessing: false,
            processSuccess: true,
            notice: event.notify ? 'Đã từ chối lời mời' : null,
          ),
        );
      }
      add(ClassListLoaded());
    } on Failure catch (f) {
      final message = ClassErrorMessages.of(f);
      emit(
        state.copyWith(
          isProcessing: false,
          processErrorMessage: message,
          notice: event.notify ? message : null,
          noticeIsError: true,
        ),
      );
      // Lời mời đã được xử lý ở nơi khác / không còn: làm mới để thẻ biến mất.
      if (f.errorCode == AppErrorCodes.classInviteNotFound || ClassErrorMessages.isClassGone(f)) {
        add(ClassListLoaded());
      }
    }
  }

  Future<void> _onClassCreated(ClassCreated event, Emitter<ClassListState> emit) async {
    emit(state.copyWith(isProcessing: true, processSuccess: false));
    try {
      final response = await repository.createClass(
        name: event.name,
        description: event.description,
        requireApproval: event.requireApproval,
        isPublic: event.isPublic,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false, processSuccess: true));
        add(ClassListLoaded()); // Reload list after creating
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể tạo lớp học',
          ),
        );
      }
    } on Failure catch (f) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: ClassErrorMessages.of(f)));
    }
  }
}
