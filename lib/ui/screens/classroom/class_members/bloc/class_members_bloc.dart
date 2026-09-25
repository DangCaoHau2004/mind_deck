import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_members_event.dart';
import 'class_members_state.dart';

class ClassMembersBloc extends Bloc<ClassMembersEvent, ClassMembersState> {
  final ClassRepository repository;

  ClassMembersBloc({required this.repository}) : super(const ClassMembersState()) {
    on<ClassMembersLoaded>(_onClassMembersLoaded);
    on<ClassMembersRefreshed>(_onClassMembersRefreshed);
    on<MemberApproved>(_onMemberApproved);
    on<MemberKicked>(_onMemberKicked);
    on<MemberRoleUpdated>(_onMemberRoleUpdated);
  }

  Future<void> _onClassMembersLoaded(
    ClassMembersLoaded event,
    Emitter<ClassMembersState> emit,
  ) async {
    emit(state.copyWith(status: ClassMembersStatus.loading));
    try {
      // Call both APIs concurrently
      final responses = await Future.wait([
        repository.getMembers(event.classId),
        repository.getPendingMembers(event.classId),
      ]);

      final membersRes = responses[0];
      final pendingRes = responses[1];

      if (membersRes.success && pendingRes.success) {
        emit(
          state.copyWith(
            status: ClassMembersStatus.success,
            members: membersRes.data,
            pendingMembers: pendingRes.data,
          ),
        );
      } else {
        emit(state.copyWith(status: ClassMembersStatus.failure, errorMessage: membersRes.message));
      }
    } catch (e) {
      emit(state.copyWith(status: ClassMembersStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onClassMembersRefreshed(
    ClassMembersRefreshed event,
    Emitter<ClassMembersState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final responses = await Future.wait([
        repository.getMembers(event.classId),
        repository.getPendingMembers(event.classId),
      ]);

      final membersRes = responses[0];
      final pendingRes = responses[1];

      if (membersRes.success && pendingRes.success) {
        emit(
          state.copyWith(
            status: ClassMembersStatus.success,
            members: membersRes.data,
            pendingMembers: pendingRes.data,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ClassMembersStatus.failure,
            errorMessage: membersRes.message,
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassMembersStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onMemberApproved(MemberApproved event, Emitter<ClassMembersState> emit) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.approveMember(event.classId, event.userId);
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassMembersLoaded(event.classId));
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể duyệt thành viên',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }

  Future<void> _onMemberKicked(MemberKicked event, Emitter<ClassMembersState> emit) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.kickMember(event.classId, event.userId);
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassMembersLoaded(event.classId));
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể xóa thành viên',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }

  Future<void> _onMemberRoleUpdated(
    MemberRoleUpdated event,
    Emitter<ClassMembersState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.updateMemberRole(
        event.classId,
        event.userId,
        event.newRole,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassMembersLoaded(event.classId));
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể thay đổi quyền',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }
}
