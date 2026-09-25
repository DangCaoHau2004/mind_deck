import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_settings_event.dart';
import 'class_settings_state.dart';

class ClassSettingsBloc extends Bloc<ClassSettingsEvent, ClassSettingsState> {
  final ClassRepository repository;

  ClassSettingsBloc({required this.repository})
    : super(const ClassSettingsState()) {
    on<UpdateClassRequested>(_onUpdateClassRequested);
  }

  Future<void> _onUpdateClassRequested(
    UpdateClassRequested event,
    Emitter<ClassSettingsState> emit,
  ) async {
    emit(
      state.copyWith(status: ClassSettingsStatus.loading, errorMessage: null),
    );
    try {
      final response = await repository.updateClass(
        event.classId,
        name: event.name,
        description: event.description,
        isPublic: event.isPublic,
        requireApproval: event.requireApproval,
      );

      if (response.success) {
        emit(state.copyWith(status: ClassSettingsStatus.success));
      } else {
        emit(
          state.copyWith(
            status: ClassSettingsStatus.failure,
            errorMessage: response.message ?? 'Cập nhật thất bại',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassSettingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
