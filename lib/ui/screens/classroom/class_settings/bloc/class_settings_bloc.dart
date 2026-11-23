import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_settings_event.dart';
import 'class_settings_state.dart';

class ClassSettingsBloc extends Bloc<ClassSettingsEvent, ClassSettingsState> {
  final ClassRepository repository;

  ClassSettingsBloc({required this.repository}) : super(const ClassSettingsState()) {
    on<UpdateClassRequested>(_onUpdateClassRequested);
    on<ClassSettingsInitialized>(
      (event, emit) => emit(state.copyWith(settings: event.settings, mySettings: event.mySettings)),
    );
    on<ClassSettingToggled>(_onSettingToggled);
    on<ClassNotifyToggled>(_onClassNotifyToggled);
    on<MyNotifyToggled>(_onMyNotifyToggled);
  }

  Future<void> _onUpdateClassRequested(
    UpdateClassRequested event,
    Emitter<ClassSettingsState> emit,
  ) async {
    emit(state.copyWith(status: ClassSettingsStatus.loading));
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
    } on Failure catch (f) {
      emit(
        state.copyWith(status: ClassSettingsStatus.failure, errorMessage: ClassErrorMessages.of(f)),
      );
    }
  }

  /// Cập nhật lạc quan: đổi công tắc ngay, gọi API, lỗi thì hoàn lại giá trị cũ.
  Future<void> _onSettingToggled(
    ClassSettingToggled event,
    Emitter<ClassSettingsState> emit,
  ) async {
    final before = state.settings;
    emit(
      state.copyWith(
        settings: switch (event.key) {
          ClassSettingKey.allowMemberAdd => before.copyWith(allowMemberAdd: event.value),
          ClassSettingKey.allowMemberClone => before.copyWith(allowMemberClone: event.value),
          ClassSettingKey.showLeaderboard => before.copyWith(showLeaderboard: event.value),
          ClassSettingKey.showMemberEmails => before.copyWith(showMemberEmails: event.value),
        },
      ),
    );
    try {
      final res = await repository.updateClassSettings(
        event.classId,
        allowMemberAdd: event.key == ClassSettingKey.allowMemberAdd ? event.value : null,
        allowMemberClone: event.key == ClassSettingKey.allowMemberClone ? event.value : null,
        showLeaderboard: event.key == ClassSettingKey.showLeaderboard ? event.value : null,
        showMemberEmails: event.key == ClassSettingKey.showMemberEmails ? event.value : null,
      );
      emit(state.copyWith(settings: res.data ?? state.settings, hasChanges: true));
    } on Failure catch (f) {
      emit(state.copyWith(settings: before, notice: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onClassNotifyToggled(
    ClassNotifyToggled event,
    Emitter<ClassSettingsState> emit,
  ) async {
    final before = state.settings;
    emit(
      state.copyWith(
        settings: before.copyWith(
          notifications: {...before.notifications, event.type: event.value},
        ),
      ),
    );
    try {
      final res = await repository.updateClassSettings(
        event.classId,
        notifications: {event.type: event.value},
      );
      emit(state.copyWith(settings: res.data ?? state.settings, hasChanges: true));
    } on Failure catch (f) {
      emit(state.copyWith(settings: before, notice: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onMyNotifyToggled(MyNotifyToggled event, Emitter<ClassSettingsState> emit) async {
    final before = state.mySettings;
    final type = event.type;
    emit(
      state.copyWith(
        mySettings: type == null
            ? before.copyWith(muted: event.value)
            : before.copyWith(types: {...before.types, type: event.value}),
      ),
    );
    try {
      final res = await repository.updateMyNotifications(
        event.classId,
        muted: type == null ? event.value : null,
        types: type == null ? null : {type: event.value},
      );
      emit(state.copyWith(mySettings: res.data ?? state.mySettings, hasChanges: true));
    } on Failure catch (f) {
      emit(state.copyWith(mySettings: before, notice: ClassErrorMessages.of(f)));
    }
  }
}
