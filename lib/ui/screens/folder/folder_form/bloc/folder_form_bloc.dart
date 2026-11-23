import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/data/repositories/tag_repository.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'folder_form_event.dart';
import 'folder_form_state.dart';

class FolderFormBloc extends Bloc<FolderFormEvent, FolderFormState> {
  final FolderRepository folderRepository;
  final TagRepository tagRepository;

  FolderFormBloc({required this.folderRepository, required this.tagRepository})
    : super(const FolderFormState()) {
    on<FolderFormCreate>(_onCreate);
    on<FolderFormUpdate>(_onUpdate);
    on<FolderFormLoadTags>(_onLoadTags);
    on<FolderFormAddTag>(_onAddTag);
  }

  Future<void> _onCreate(FolderFormCreate event, Emitter<FolderFormState> emit) async {
    emit(state.copyWith(status: FolderFormStatus.loading));
    try {
      await folderRepository.createFolder(
        name: event.name,
        description: event.description,
        icon: event.icon,
        color: event.color,
        isPublic: event.isPublic,
        tagIds: event.tagIds,
        deckIds: event.deckIds,
      );
      emit(
        state.copyWith(status: FolderFormStatus.success, successMessage: 'Tạo thư mục thành công'),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderFormStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdate(FolderFormUpdate event, Emitter<FolderFormState> emit) async {
    emit(state.copyWith(status: FolderFormStatus.loading));
    try {
      await folderRepository.updateFolder(
        id: event.id,
        name: event.name,
        description: event.description,
        icon: event.icon,
        color: event.color,
        isPublic: event.isPublic,
        tagIds: event.tagIds,
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
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadTags(FolderFormLoadTags event, Emitter<FolderFormState> emit) async {
    // Có bản đã nhớ thì hiện ngay, rồi tải lại ngầm để cập nhật
    final cached = tagRepository.cachedTags;
    if (cached != null) emit(state.copyWith(availableTags: cached, isLoadingTags: false));
    try {
      final res = await tagRepository.getTags();
      emit(state.copyWith(availableTags: res.data, isLoadingTags: false));
    } catch (_) {
      // Lỗi thì giữ danh sách đang có (bản đã nhớ hoặc rỗng), không chặn form
      emit(state.copyWith(isLoadingTags: false));
    }
  }

  Future<void> _onAddTag(FolderFormAddTag event, Emitter<FolderFormState> emit) async {
    try {
      final res = await tagRepository.createTag(name: event.name, color: event.color);
      if (res.data != null) {
        final newTags = List.of(state.availableTags)..add(res.data!);
        emit(state.copyWith(availableTags: newTags, recentlyAddedTag: res.data));
      }
    } catch (e) {
      // Tag trùng tên (danh sách chưa kịp cập nhật): dùng luôn tag đã có thay vì báo lỗi
      Object? existing;
      if (e is Failure && e.errorCode == AppErrorCodes.tagAlreadyExists) {
        existing = e.params?['existingTag'];
      }
      if (existing is Map<String, dynamic>) {
        final tag = TagModel.fromJson(existing);
        final tags = state.availableTags.any((t) => t.id == tag.id)
            ? state.availableTags
            : [...state.availableTags, tag];
        emit(state.copyWith(availableTags: tags, recentlyAddedTag: tag));
        return;
      }
      emit(
        state.copyWith(
          status: FolderFormStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
        ),
      );
    }
  }
}
