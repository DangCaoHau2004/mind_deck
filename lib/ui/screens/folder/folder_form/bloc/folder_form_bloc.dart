import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/core/failures.dart';
import 'folder_form_event.dart';
import 'folder_form_state.dart';

class FolderFormBloc extends Bloc<FolderFormEvent, FolderFormState> {
  final FolderRepository folderRepository;

  FolderFormBloc({required this.folderRepository})
    : super(const FolderFormState()) {
    on<FolderFormCreate>(_onCreate);
    on<FolderFormUpdate>(_onUpdate);
  }

  Future<void> _onCreate(
    FolderFormCreate event,
    Emitter<FolderFormState> emit,
  ) async {
    emit(state.copyWith(status: FolderFormStatus.loading));
    try {
      await folderRepository.createFolder(
        name: event.name,
        description: event.description,
        icon: event.icon,
        color: event.color,
        isPublic: event.isPublic,
      );
      emit(
        state.copyWith(
          status: FolderFormStatus.success,
          successMessage: 'Tạo thư mục thành công',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderFormStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    FolderFormUpdate event,
    Emitter<FolderFormState> emit,
  ) async {
    emit(state.copyWith(status: FolderFormStatus.loading));
    try {
      await folderRepository.updateFolder(
        id: event.id,
        name: event.name,
        description: event.description,
        icon: event.icon,
        color: event.color,
        isPublic: event.isPublic,
      );
      emit(
        state.copyWith(
          status: FolderFormStatus.success,
          successMessage: 'Cập nhật thư mục thành công',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderFormStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }
}
