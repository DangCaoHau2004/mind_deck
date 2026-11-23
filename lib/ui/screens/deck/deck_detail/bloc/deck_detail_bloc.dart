import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/shared_repository.dart';
import 'deck_detail_event.dart';
import 'deck_detail_state.dart';

class DeckDetailBloc extends Bloc<DeckDetailEvent, DeckDetailState> {
  final DeckRepository deckRepository;
  final SharedRepository sharedRepository;

  DeckDetailBloc({required this.deckRepository, required this.sharedRepository})
    : super(const DeckDetailState()) {
    on<DeckDetailLoaded>(_onLoaded);
    on<DeckDetailRefreshed>(_onRefreshed);
    on<DeckDeleted>(_onDeleted);
    on<DeckDetailStarToggled>(_onStarToggled);
    on<DeckShareUpdated>(_onShareUpdated);
    on<DeckDetailCloned>(_onCloned);
  }

  Future<void> _onLoaded(DeckDetailLoaded event, Emitter<DeckDetailState> emit) async {
    emit(state.copyWith(status: DeckDetailStatus.loading));
    try {
      final result = await deckRepository.getDeckById(event.id, token: event.token);
      emit(
        state.copyWith(
          status: DeckDetailStatus.success,
          deck: _keepPendingStar(result.data),
          clearStarOverride: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(DeckDetailRefreshed event, Emitter<DeckDetailState> emit) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final result = await deckRepository.getDeckById(event.id, token: event.token);
      emit(
        state.copyWith(
          status: DeckDetailStatus.success,
          isRefreshing: false,
          deck: _keepPendingStar(result.data),
          clearStarOverride: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onDeleted(DeckDeleted event, Emitter<DeckDetailState> emit) async {
    emit(state.copyWith(status: DeckDetailStatus.loading));
    try {
      await deckRepository.deleteDeck(event.id);
      emit(state.copyWith(status: DeckDetailStatus.deleted, successMessage: 'Đã xóa học phần'));
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onStarToggled(DeckDetailStarToggled event, Emitter<DeckDetailState> emit) async {
    // Đổi ngôi sao ngay trên giao diện, không chờ API; API chạy ngầm, lỗi mới khôi phục và báo.
    _setStar(emit, !event.isStarred);
    try {
      await deckRepository.starDeck(event.id);
    } catch (e) {
      _setStar(emit, event.isStarred, error: e is Failure ? e.displayMessage : e.toString());
    }
  }

  /// Đặt trạng thái sao: có dữ liệu đầy đủ thì đổi trên `deck`, chưa có thì lưu tạm để hiển thị.
  void _setStar(Emitter<DeckDetailState> emit, bool value, {String? error}) {
    final deck = state.deck;
    emit(
      state.copyWith(
        deck: deck?.copyWith(isStarred: value),
        starOverride: deck == null ? value : null,
        clearStarOverride: deck != null,
        errorMessage: error,
        toastTriggerTime: error != null ? DateTime.now() : null,
      ),
    );
  }

  /// Dữ liệu đầy đủ vừa về: nếu người dùng đã bấm sao trong lúc chờ thì giữ lựa chọn đó.
  DeckModel? _keepPendingStar(DeckModel? deck) {
    final pending = state.starOverride;
    return deck != null && pending != null ? deck.copyWith(isStarred: pending) : deck;
  }

  Future<void> _onShareUpdated(DeckShareUpdated event, Emitter<DeckDetailState> emit) async {
    final currentDeck = state.deck;
    final String accessLevel =
        event.accessLevel ??
        (event.isPublic ? 'public' : (event.generateLink ? 'restricted' : 'private'));

    // 1. Optimistic Update: Cập nhật lập tức trên FE
    if (currentDeck != null) {
      final optimisticDeck = currentDeck.copyWith(
        shareMode: accessLevel,
        isPublic: accessLevel == 'public',
      );
      emit(state.copyWith(deck: optimisticDeck));
    }

    try {
      // 2. Gọi API cập nhật
      await deckRepository.shareDeck(event.id, accessLevel: accessLevel);

      // 3. Reload và merge dữ liệu chuẩn bảo toàn shareMode vừa chọn
      final result = await deckRepository.getDeckById(event.id);
      if (result.data != null) {
        final mergedDeck = result.data!.copyWith(
          shareMode: accessLevel,
          isPublic: accessLevel == 'public',
          shareToken: result.data!.shareToken ?? currentDeck?.shareToken,
          flashcards: currentDeck?.flashcards ?? result.data!.flashcards,
        );
        emit(
          state.copyWith(
            status: DeckDetailStatus.success,
            deck: mergedDeck,
            successMessage: event.isSilent ? null : 'Cập nhật quyền riêng tư thành công',
            toastTriggerTime: event.isSilent ? null : DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // 4. Nếu lỗi -> Khôi phục lại trạng thái cũ
      if (currentDeck != null) {
        emit(
          state.copyWith(
            deck: currentDeck,
            errorMessage: event.isSilent ? null : (e is Failure ? e.message : e.toString()),
            toastTriggerTime: event.isSilent ? null : DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> _onCloned(DeckDetailCloned event, Emitter<DeckDetailState> emit) async {
    emit(state.copyWith(status: DeckDetailStatus.loading));
    try {
      final response = await deckRepository.cloneDeck(event.id, token: event.token);
      emit(
        state.copyWith(
          status: DeckDetailStatus.success,
          successMessage: 'Nhân bản bộ thẻ thành công!',
          toastTriggerTime: DateTime.now(),
          clonedDeckId: response.data?.id,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }
}
