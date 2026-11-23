import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/document_import_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';
import 'package:mind_deck/data/repositories/document_import_repository.dart';

/// Nơi lưu các bộ thẻ khi bấm "Lưu thành bộ thẻ".
enum CommitTargetKind { byFileName, newFolder, existingFolder, none }

class CommitTarget extends Equatable {
  final CommitTargetKind kind;
  final String? folderName; // tên thư mục mới hoặc tên thư mục có sẵn (để hiển thị)
  final String? folderId;

  const CommitTarget._(this.kind, {this.folderName, this.folderId});

  const CommitTarget.byFileName() : this._(CommitTargetKind.byFileName);
  const CommitTarget.none() : this._(CommitTargetKind.none);
  const CommitTarget.newFolder(String name) : this._(CommitTargetKind.newFolder, folderName: name);
  const CommitTarget.existing({required String id, required String name})
    : this._(CommitTargetKind.existingFolder, folderId: id, folderName: name);

  @override
  List<Object?> get props => [kind, folderName, folderId];
}

abstract class DocumentImportDraftEvent extends Equatable {
  const DocumentImportDraftEvent();

  @override
  List<Object?> get props => [];
}

class DocumentImportDraftLoaded extends DocumentImportDraftEvent {
  final String id;
  final DocumentImportDraft? initial;
  const DocumentImportDraftLoaded(this.id, {this.initial});
}

class DraftDeckRenamed extends DocumentImportDraftEvent {
  final int deck;
  final String name;
  const DraftDeckRenamed(this.deck, this.name);
}

class DraftDeckRemoved extends DocumentImportDraftEvent {
  final int deck;
  const DraftDeckRemoved(this.deck);
}

class DraftCardChanged extends DocumentImportDraftEvent {
  final int deck;
  final int card;
  final DraftCard value;
  const DraftCardChanged(this.deck, this.card, this.value);
}

class DraftCardRemoved extends DocumentImportDraftEvent {
  final int deck;
  final int card;
  const DraftCardRemoved(this.deck, this.card);
}

class DraftCardAdded extends DocumentImportDraftEvent {
  final int deck;
  final DraftCard value;
  const DraftCardAdded(this.deck, this.value);
}

class DraftSaveRequested extends DocumentImportDraftEvent {
  const DraftSaveRequested();
}

class DraftCommitRequested extends DocumentImportDraftEvent {
  final CommitTarget target;
  const DraftCommitRequested(this.target);
}

class DraftDiscardRequested extends DocumentImportDraftEvent {
  const DraftDiscardRequested();
}

enum DocumentImportDraftStatus { loading, ready, failure, committed, discarded }

class DocumentImportDraftState extends Equatable {
  final DocumentImportDraftStatus status;
  final DocumentImportDraft? draft;
  final List<DraftDeck> decks;
  final bool dirty;
  final bool saving;
  final bool committing;
  final String? errorMessage;
  final CommitResult? result;
  final String? notice;
  final int noticeId;

  const DocumentImportDraftState({
    this.status = DocumentImportDraftStatus.loading,
    this.draft,
    this.decks = const [],
    this.dirty = false,
    this.saving = false,
    this.committing = false,
    this.errorMessage,
    this.result,
    this.notice,
    this.noticeId = 0,
  });

  int get cardCount => decks.fold<int>(0, (s, d) => s + d.cards.length);

  DocumentImportDraftState copyWith({
    DocumentImportDraftStatus? status,
    DocumentImportDraft? draft,
    List<DraftDeck>? decks,
    bool? dirty,
    bool? saving,
    bool? committing,
    String? errorMessage,
    CommitResult? result,
    String? notice,
    int? noticeId,
  }) {
    return DocumentImportDraftState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      decks: decks ?? this.decks,
      dirty: dirty ?? this.dirty,
      saving: saving ?? this.saving,
      committing: committing ?? this.committing,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    draft?.id,
    decks.map((d) => d.toJson().toString()).join('|'),
    dirty,
    saving,
    committing,
    errorMessage,
    result?.totalCards,
    noticeId,
  ];
}

class DocumentImportDraftBloc extends Bloc<DocumentImportDraftEvent, DocumentImportDraftState> {
  static const int maxDecks = 50;
  static const int maxCards = 500;
  static const int maxFront = 1000;
  static const int maxBack = 5000;

  final DocumentImportRepository repository;

  DocumentImportDraftBloc({required this.repository}) : super(const DocumentImportDraftState()) {
    on<DocumentImportDraftLoaded>(_onLoaded);
    on<DraftDeckRenamed>(
      (e, emit) => _editDecks(emit, (decks) {
        decks[e.deck] = decks[e.deck].copyWith(name: e.name);
      }, valid: e.deck),
    );
    on<DraftDeckRemoved>(
      (e, emit) => _editDecks(emit, (decks) {
        decks.removeAt(e.deck);
      }, valid: e.deck),
    );
    on<DraftCardChanged>(
      (e, emit) => _editCards(emit, e.deck, e.card, (cards) {
        cards[e.card] = e.value;
      }),
    );
    on<DraftCardRemoved>(
      (e, emit) => _editCards(emit, e.deck, e.card, (cards) {
        cards.removeAt(e.card);
      }),
    );
    on<DraftCardAdded>(_onCardAdded);
    on<DraftSaveRequested>(_onSave);
    on<DraftCommitRequested>(_onCommit);
    on<DraftDiscardRequested>(_onDiscard);
  }

  String _messageOf(Object e, String fallback) {
    if (e is Failure) return DocumentImportErrorMessages.of(e);
    return fallback;
  }

  Future<void> _onLoaded(
    DocumentImportDraftLoaded event,
    Emitter<DocumentImportDraftState> emit,
  ) async {
    emit(const DocumentImportDraftState());
    try {
      // Luôn tải lại (GET cũng gia hạn thêm 30 ngày); `initial` chỉ để hiện tức thì nếu có.
      final initial = event.initial;
      if (initial != null &&
          initial.status == DocumentImportStatus.done &&
          initial.decks.isNotEmpty) {
        emit(
          state.copyWith(
            status: DocumentImportDraftStatus.ready,
            draft: initial,
            decks: initial.decks,
          ),
        );
      }
      final draft = await repository.getDraft(event.id);
      _applyLoaded(emit, draft);
    } catch (e) {
      if (state.status == DocumentImportDraftStatus.ready) return; // đã có bản `initial` để dùng
      emit(
        state.copyWith(
          status: DocumentImportDraftStatus.failure,
          errorMessage: _messageOf(e, 'Không thể tải bản nháp'),
        ),
      );
    }
  }

  void _applyLoaded(Emitter<DocumentImportDraftState> emit, DocumentImportDraft draft) {
    if (draft.status == DocumentImportStatus.committed) {
      emit(
        state.copyWith(
          status: DocumentImportDraftStatus.failure,
          draft: draft,
          errorMessage: 'Bản nháp này đã được lưu thành bộ thẻ.',
        ),
      );
      return;
    }
    if (draft.contentCleared) {
      emit(
        state.copyWith(
          status: DocumentImportDraftStatus.failure,
          draft: draft,
          errorMessage: 'Nội dung bản nháp đã hết hạn và bị xóa.',
        ),
      );
      return;
    }
    // Đang xử lý/lỗi giữa chừng: dùng phần thẻ đã có trong `chunks` để người dùng vẫn xem được.
    final decks = draft.decks.isNotEmpty
        ? draft.decks
        : (draft.chunks.any((c) => c.cards.isNotEmpty)
              ? [
                  DraftDeck(
                    name: _baseName(draft.fileName),
                    cards: draft.chunks.expand((c) => c.cards).toList(),
                  ),
                ]
              : const <DraftDeck>[]);
    emit(
      state.copyWith(
        status: DocumentImportDraftStatus.ready,
        draft: draft,
        decks: decks,
        dirty: false,
      ),
    );
  }

  String _baseName(String fileName) {
    final i = fileName.lastIndexOf('.');
    return i > 0 ? fileName.substring(0, i) : (fileName.isEmpty ? 'Bộ thẻ mới' : fileName);
  }

  void _editDecks(
    Emitter<DocumentImportDraftState> emit,
    void Function(List<DraftDeck> decks) change, {
    required int valid,
  }) {
    if (valid < 0 || valid >= state.decks.length || state.committing) return;
    final decks = List<DraftDeck>.of(state.decks);
    change(decks);
    emit(state.copyWith(decks: decks, dirty: true));
  }

  void _editCards(
    Emitter<DocumentImportDraftState> emit,
    int deck,
    int card,
    void Function(List<DraftCard> cards) change,
  ) {
    if (deck < 0 || deck >= state.decks.length || state.committing) return;
    final cards = List<DraftCard>.of(state.decks[deck].cards);
    if (card < 0 || card >= cards.length) return;
    change(cards);
    final decks = List<DraftDeck>.of(state.decks);
    decks[deck] = decks[deck].copyWith(cards: cards);
    emit(state.copyWith(decks: decks, dirty: true));
  }

  void _onCardAdded(DraftCardAdded e, Emitter<DocumentImportDraftState> emit) {
    if (e.deck < 0 || e.deck >= state.decks.length || state.committing) return;
    if (state.cardCount >= maxCards) {
      emit(
        state.copyWith(
          notice: 'Tối đa $maxCards thẻ trong một bản nháp.',
          noticeId: state.noticeId + 1,
        ),
      );
      return;
    }
    final decks = List<DraftDeck>.of(state.decks);
    decks[e.deck] = decks[e.deck].copyWith(cards: [...decks[e.deck].cards, e.value]);
    emit(state.copyWith(decks: decks, dirty: true));
  }

  /// Kiểm tra lỏng trước khi lưu nháp (PATCH): deck phải có tên và không vượt giới hạn.
  String? validateForSave() {
    if (state.decks.length > maxDecks) return 'Tối đa $maxDecks bộ thẻ.';
    if (state.cardCount > maxCards) return 'Tối đa $maxCards thẻ.';
    for (final d in state.decks) {
      if (d.name.trim().isEmpty) return 'Mỗi bộ thẻ cần có tên.';
      for (final c in d.cards) {
        if (c.frontText.length > maxFront) return 'Mặt trước tối đa $maxFront ký tự.';
        if (c.backText.length > maxBack) return 'Mặt sau tối đa $maxBack ký tự.';
      }
    }
    return null;
  }

  /// Kiểm tra chặt trước khi lưu thành bộ thẻ: mỗi deck ≥ 2 thẻ, hai mặt không rỗng.
  String? validateForCommit() {
    if (state.decks.isEmpty) return 'Chưa có bộ thẻ nào để lưu.';
    final loose = validateForSave();
    if (loose != null) return loose;
    for (final d in state.decks) {
      final incomplete = d.cards.where((c) => !c.isComplete).length;
      if (incomplete > 0) {
        return 'Bộ "${d.name}" còn $incomplete thẻ bị trống một mặt. Hãy điền hoặc xóa thẻ đó.';
      }
      if (d.cards.length < 2) return 'Bộ "${d.name}" cần ít nhất 2 thẻ.';
    }
    return null;
  }

  Future<bool> _persist(Emitter<DocumentImportDraftState> emit) async {
    final id = state.draft?.id;
    if (id == null) return false;
    try {
      final saved = await repository.saveDraft(id, state.decks);
      emit(state.copyWith(draft: saved, dirty: false));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          committing: false,
          notice: _messageOf(e, 'Không thể lưu bản nháp'),
          noticeId: state.noticeId + 1,
        ),
      );
      return false;
    }
  }

  Future<void> _onSave(DraftSaveRequested event, Emitter<DocumentImportDraftState> emit) async {
    if (state.saving || state.committing || !state.dirty) return;
    final problem = validateForSave();
    if (problem != null) {
      emit(state.copyWith(notice: problem, noticeId: state.noticeId + 1));
      return;
    }
    emit(state.copyWith(saving: true));
    final ok = await _persist(emit);
    if (ok) {
      emit(state.copyWith(saving: false, notice: 'Đã lưu bản nháp.', noticeId: state.noticeId + 1));
    }
  }

  Future<void> _onCommit(DraftCommitRequested event, Emitter<DocumentImportDraftState> emit) async {
    if (state.saving || state.committing) return;
    final draft = state.draft;
    if (draft == null) return;
    final problem = validateForCommit();
    if (problem != null) {
      emit(state.copyWith(notice: problem, noticeId: state.noticeId + 1));
      return;
    }
    emit(state.copyWith(committing: true));
    final t = event.target;
    try {
      final result = await repository.commit(
        draft.id,
        decks: state.decks, // gửi bản cuối đã sửa để không phụ thuộc vào việc đã lưu nháp hay chưa
        folderId: t.kind == CommitTargetKind.existingFolder ? t.folderId : null,
        folderName: t.kind == CommitTargetKind.newFolder ? t.folderName : null,
        createFolder: t.kind == CommitTargetKind.byFileName
            ? true
            : (t.kind == CommitTargetKind.none ? false : null),
      );
      emit(
        state.copyWith(
          status: DocumentImportDraftStatus.committed,
          committing: false,
          result: result,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          committing: false,
          notice: _messageOf(e, 'Không thể lưu thành bộ thẻ'),
          noticeId: state.noticeId + 1,
        ),
      );
    }
  }

  Future<void> _onDiscard(
    DraftDiscardRequested event,
    Emitter<DocumentImportDraftState> emit,
  ) async {
    final id = state.draft?.id;
    if (id == null || state.saving || state.committing) return;
    try {
      await repository.delete(id);
      emit(state.copyWith(status: DocumentImportDraftStatus.discarded));
    } on Failure catch (f) {
      // Đã bị xóa ở nơi khác: coi như xong.
      if (f.errorCode == 'DOCUMENT_IMPORT_NOT_FOUND') {
        emit(state.copyWith(status: DocumentImportDraftStatus.discarded));
        return;
      }
      emit(state.copyWith(notice: DocumentImportErrorMessages.of(f), noticeId: state.noticeId + 1));
    } catch (_) {
      emit(state.copyWith(notice: 'Không thể xóa bản nháp', noticeId: state.noticeId + 1));
    }
  }
}
