import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/tag_repository.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'deck_form_event.dart';
import 'deck_form_state.dart';

class DeckFormBloc extends Bloc<DeckFormEvent, DeckFormState> {
  final DeckRepository deckRepository;
  final TagRepository tagRepository;

  DeckFormBloc({required this.deckRepository, required this.tagRepository})
    : super(const DeckFormState()) {
    on<DeckFormCreate>(_onCreate);
    on<DeckFormUpdate>(_onUpdate);
    on<DeckFormLoadTags>(_onLoadTags);
    on<DeckFormAddTag>(_onAddTag);
  }

  Future<void> _onCreate(DeckFormCreate event, Emitter<DeckFormState> emit) async {
    emit(state.copyWith(status: DeckFormStatus.loading));
    try {
      await deckRepository.createDeck(event.data);
      emit(
        state.copyWith(status: DeckFormStatus.success, successMessage: 'Tạo học phần thành công'),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckFormStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdate(DeckFormUpdate event, Emitter<DeckFormState> emit) async {
    emit(state.copyWith(status: DeckFormStatus.loading));
    try {
      await deckRepository.updateDeck(event.id, event.data);
      emit(
        state.copyWith(
          status: DeckFormStatus.success,
          successMessage: 'Cập nhật học phần thành công',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckFormStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadTags(DeckFormLoadTags event, Emitter<DeckFormState> emit) async {
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

  Future<void> _onAddTag(DeckFormAddTag event, Emitter<DeckFormState> emit) async {
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
          status: DeckFormStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
        ),
      );
      // Reset status so failure doesn't persist
      emit(state.copyWith(status: DeckFormStatus.initial));
    }
  }
}
