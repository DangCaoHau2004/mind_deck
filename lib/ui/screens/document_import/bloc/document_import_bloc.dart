import 'dart:async';
import 'dart:typed_data';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/document_import_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';
import 'package:mind_deck/data/repositories/document_import_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tệp người dùng đã chọn (đọc sẵn vào bộ nhớ, tối đa vài chục MB nên chấp nhận được).
class PickedDocument extends Equatable {
  final String name;
  final String extension;
  final int size;
  final Uint8List bytes;

  const PickedDocument({
    required this.name,
    required this.extension,
    required this.size,
    required this.bytes,
  });

  bool get isTable => extension == 'csv' || extension == 'xlsx';

  @override
  List<Object?> get props => [name, extension, size];
}

/// Một ảnh đã chọn/chụp (đã nén khi chọn). Thứ tự trong danh sách = thứ tự trang.
class PickedImage extends Equatable {
  final int id;
  final String name;
  final Uint8List bytes;

  const PickedImage({required this.id, required this.name, required this.bytes});

  /// Đuôi gửi lên BE: jpg/jpeg/png/webp, đuôi khác (vd HEIC đã bị đổi) coi là jpg.
  String get extension {
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    return documentImageExtensions.contains(ext) ? ext : 'jpg';
  }

  @override
  List<Object?> get props => [id];
}

abstract class DocumentImportEvent extends Equatable {
  const DocumentImportEvent();

  @override
  List<Object?> get props => [];
}

class DocumentImportQuotaRequested extends DocumentImportEvent {
  const DocumentImportQuotaRequested();
}

class DocumentImportFilePicked extends DocumentImportEvent {
  final PickedDocument file;
  const DocumentImportFilePicked(this.file);

  @override
  List<Object?> get props => [file];
}

class DocumentImportImagesAdded extends DocumentImportEvent {
  final List<PickedImage> images;
  const DocumentImportImagesAdded(this.images);

  @override
  List<Object?> get props => [images];
}

class DocumentImportImageRemoved extends DocumentImportEvent {
  final int index;
  const DocumentImportImageRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

/// Đổi chỗ ảnh `index` với ảnh kế bên (`delta` = -1 lên, +1 xuống).
class DocumentImportImageMoved extends DocumentImportEvent {
  final int index;
  final int delta;
  const DocumentImportImageMoved(this.index, this.delta);

  @override
  List<Object?> get props => [index, delta];
}

class DocumentImportFileCleared extends DocumentImportEvent {
  const DocumentImportFileCleared();
}

class DocumentImportOptionsChanged extends DocumentImportEvent {
  final DocumentImportOptions options;
  const DocumentImportOptionsChanged(this.options);

  @override
  List<Object?> get props => [options.toFields('pdf'), options.sheet, options.maxCards];
}

class DocumentImportStarted extends DocumentImportEvent {
  const DocumentImportStarted();
}

/// Nối lại luồng của một bản nháp đang xử lý (từ danh sách hoặc lượt đang dở lưu trên máy).
class DocumentImportResumeRequested extends DocumentImportEvent {
  final String draftId;
  const DocumentImportResumeRequested(this.draftId);

  @override
  List<Object?> get props => [draftId];
}

/// Đến giờ nối lại luồng sau khi mất kết nối (giữ nguyên bộ đếm số lần thử).
class DocumentImportReconnectDue extends DocumentImportEvent {
  const DocumentImportReconnectDue();
}

class DocumentImportCancelled extends DocumentImportEvent {
  const DocumentImportCancelled();
}

/// Quay về màn chọn tệp sau khi lỗi (giữ nguyên tệp và cài đặt).
class DocumentImportReset extends DocumentImportEvent {
  const DocumentImportReset();
}

class DocumentImportStreamArrived extends DocumentImportEvent {
  final DocumentImportStreamEvent event;
  final int generation;
  const DocumentImportStreamArrived(this.event, this.generation);
}

class DocumentImportStreamClosed extends DocumentImportEvent {
  final Object? error;
  final int generation;
  const DocumentImportStreamClosed(this.error, this.generation);
}

enum DocumentImportPhase { setup, uploading, processing, done, failed }

class DocumentImportState extends Equatable {
  final DocumentImportPhase phase;
  final DocumentImportQuota? quota;
  final bool quotaLoading;
  final String? quotaError;
  final PickedDocument? file;
  final List<PickedImage> images;
  final DocumentImportOptions options;
  final double uploadProgress;
  final String? draftId;
  final String? fileName;
  final String? fileType;
  final bool usesAi;
  final int totalChunks;
  final int doneChunks;
  final List<DraftChunk> chunks;
  final int reconnectAttempt;
  final String? errorMessage;
  final bool errorIsBusy;
  final DocumentImportDraft? completedDraft;

  /// Lượt đang dở lưu trên máy (mở lại app/màn vẫn nối lại được).
  final String? pendingDraftId;

  /// Thông báo một lần dùng (toast); phân biệt các lần bằng `noticeId`.
  final String? notice;
  final int noticeId;

  const DocumentImportState({
    this.phase = DocumentImportPhase.setup,
    this.quota,
    this.quotaLoading = false,
    this.quotaError,
    this.file,
    this.images = const [],
    this.options = const DocumentImportOptions(),
    this.uploadProgress = 0,
    this.draftId,
    this.fileName,
    this.fileType,
    this.usesAi = false,
    this.totalChunks = 0,
    this.doneChunks = 0,
    this.chunks = const [],
    this.reconnectAttempt = 0,
    this.errorMessage,
    this.errorIsBusy = false,
    this.completedDraft,
    this.pendingDraftId,
    this.notice,
    this.noticeId = 0,
  });

  bool get hasInput => file != null || images.isNotEmpty;

  /// Đầu vào này sẽ dùng AI (tốn lượt): ảnh hoặc tệp văn bản; csv/xlsx thì không.
  bool get willUseAi => images.isNotEmpty || (file != null && !file!.isTable);

  int get cardCount => chunks.fold<int>(0, (s, c) => s + c.cards.length);
  int get failedChunks => chunks.where((c) => c.failed).length;

  DocumentImportState copyWith({
    DocumentImportPhase? phase,
    DocumentImportQuota? quota,
    bool? quotaLoading,
    String? quotaError,
    bool clearQuotaError = false,
    PickedDocument? file,
    bool clearFile = false,
    List<PickedImage>? images,
    DocumentImportOptions? options,
    double? uploadProgress,
    String? draftId,
    bool clearDraftId = false,
    String? fileName,
    String? fileType,
    bool? usesAi,
    int? totalChunks,
    int? doneChunks,
    List<DraftChunk>? chunks,
    int? reconnectAttempt,
    String? errorMessage,
    bool clearError = false,
    bool? errorIsBusy,
    DocumentImportDraft? completedDraft,
    String? pendingDraftId,
    bool clearPending = false,
    String? notice,
    int? noticeId,
  }) {
    return DocumentImportState(
      phase: phase ?? this.phase,
      quota: quota ?? this.quota,
      quotaLoading: quotaLoading ?? this.quotaLoading,
      quotaError: clearQuotaError ? null : (quotaError ?? this.quotaError),
      file: clearFile ? null : (file ?? this.file),
      images: images ?? this.images,
      options: options ?? this.options,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      draftId: clearDraftId ? null : (draftId ?? this.draftId),
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      usesAi: usesAi ?? this.usesAi,
      totalChunks: totalChunks ?? this.totalChunks,
      doneChunks: doneChunks ?? this.doneChunks,
      chunks: chunks ?? this.chunks,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorIsBusy: errorIsBusy ?? this.errorIsBusy,
      completedDraft: completedDraft ?? this.completedDraft,
      pendingDraftId: clearPending ? null : (pendingDraftId ?? this.pendingDraftId),
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    quota?.remainingToday,
    quota?.attemptsToday,
    quota?.aiAvailable,
    quota?.coins?.balance,
    quota?.coins?.mode,
    quota?.coins?.needsVideo,
    quotaLoading,
    quotaError,
    file,
    images,
    fileType,
    options.toFields('pdf'),
    options.sheet,
    options.maxCards,
    uploadProgress,
    draftId,
    fileName,
    usesAi,
    totalChunks,
    doneChunks,
    chunks.length,
    cardCount,
    failedChunks,
    reconnectAttempt,
    errorMessage,
    errorIsBusy,
    completedDraft?.id,
    pendingDraftId,
    noticeId,
  ];
}

class DocumentImportBloc extends Bloc<DocumentImportEvent, DocumentImportState> {
  static const String activeDraftKey = 'document_import_active_draft';

  /// Chờ tăng dần giữa các lần nối lại luồng.
  static const List<Duration> reconnectDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];

  final DocumentImportRepository repository;
  final SharedPreferences prefs;

  StreamSubscription<DocumentImportStreamEvent>? _sub;
  Timer? _reconnectTimer;

  /// Tăng mỗi khi mở luồng mới / hủy; sự kiện của luồng cũ bị bỏ qua.
  int _generation = 0;
  bool _terminal = false;

  DocumentImportBloc({required this.repository, required this.prefs})
    : super(const DocumentImportState()) {
    on<DocumentImportQuotaRequested>(_onQuota);
    on<DocumentImportFilePicked>(_onFilePicked);
    on<DocumentImportFileCleared>(
      (e, emit) => emit(
        state.copyWith(clearFile: true, images: const [], options: const DocumentImportOptions()),
      ),
    );
    on<DocumentImportImagesAdded>(_onImagesAdded);
    on<DocumentImportImageRemoved>(_onImageRemoved);
    on<DocumentImportImageMoved>(_onImageMoved);
    on<DocumentImportOptionsChanged>((e, emit) => emit(state.copyWith(options: e.options)));
    on<DocumentImportStarted>(_onStarted);
    on<DocumentImportResumeRequested>(_onResume);
    on<DocumentImportCancelled>(_onCancelled);
    on<DocumentImportReset>(_onReset);
    on<DocumentImportReconnectDue>(_onReconnectDue);
    on<DocumentImportStreamArrived>(_onArrived, transformer: sequential());
    on<DocumentImportStreamClosed>(_onClosed, transformer: sequential());
  }

  String? _savedDraftId() {
    try {
      final id = prefs.getString(activeDraftKey);
      return (id == null || id.isEmpty) ? null : id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveActive(String id) async {
    try {
      await prefs.setString(activeDraftKey, id);
    } catch (_) {}
  }

  Future<void> _clearActive() async {
    try {
      await prefs.remove(activeDraftKey);
    } catch (_) {}
  }

  String _messageOf(Object e, String fallback) {
    if (e is Failure) return DocumentImportErrorMessages.of(e);
    return fallback;
  }

  Future<void> _onQuota(
    DocumentImportQuotaRequested event,
    Emitter<DocumentImportState> emit,
  ) async {
    emit(
      state.copyWith(
        quotaLoading: true,
        clearQuotaError: true,
        pendingDraftId: _savedDraftId(),
        clearPending: _savedDraftId() == null,
      ),
    );
    try {
      final quota = await repository.getQuota();
      emit(state.copyWith(quota: quota, quotaLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          quotaLoading: false,
          quotaError: _messageOf(e, 'Không thể tải hạn mức hôm nay'),
        ),
      );
    }
  }

  void _onFilePicked(DocumentImportFilePicked event, Emitter<DocumentImportState> emit) {
    final quota = state.quota;
    final limits = quota?.limits ?? const DocumentImportLimits();
    final file = event.file;

    String? error;
    if (!limits.fileTypes.contains(file.extension)) {
      error = 'Chỉ hỗ trợ tệp: ${limits.fileTypes.join(', ')}.';
    } else if (file.size > limits.maxFileMb * 1024 * 1024) {
      error = 'Tệp quá lớn (tối đa ${limits.maxFileMb} MB).';
    } else if (file.size == 0) {
      error = 'Tệp rỗng.';
    }
    if (error != null) {
      emit(state.copyWith(notice: error, noticeId: state.noticeId + 1));
      return;
    }
    // Đổi tệp thì bỏ các cài đặt chỉ có nghĩa với loại tệp trước (và bỏ ảnh đã chọn).
    emit(
      state.copyWith(
        file: file,
        images: const [],
        options: state.options.copyWith(clearPages: true, clearSheet: true, clearMaxCards: true),
      ),
    );
  }

  void _onImagesAdded(DocumentImportImagesAdded event, Emitter<DocumentImportState> emit) {
    final limits = state.quota?.limits ?? const DocumentImportLimits();
    final room = limits.maxImages - state.images.length;
    if (room <= 0) {
      emit(
        state.copyWith(
          notice: 'Tối đa ${limits.maxImages} ảnh mỗi lần.',
          noticeId: state.noticeId + 1,
        ),
      );
      return;
    }
    final maxBytes = limits.maxFileMb * 1024 * 1024;
    final valid = event.images
        .where((i) => i.bytes.isNotEmpty && i.bytes.length <= maxBytes)
        .toList();
    final tooBig = event.images.length - valid.length;
    final accepted = valid.take(room).toList();
    String? notice;
    if (tooBig > 0) {
      notice = '$tooBig ảnh quá lớn (tối đa ${limits.maxFileMb} MB) đã bị bỏ.';
    } else if (valid.length > room) {
      notice = 'Chỉ nhận tối đa ${limits.maxImages} ảnh mỗi lần.';
    }
    if (accepted.isEmpty) {
      if (notice != null) emit(state.copyWith(notice: notice, noticeId: state.noticeId + 1));
      return;
    }
    // Ảnh thay thế tệp đã chọn (không trộn ảnh với loại tệp khác).
    emit(
      state.copyWith(
        clearFile: true,
        images: [...state.images, ...accepted],
        options: state.file == null
            ? state.options
            : state.options.copyWith(clearPages: true, clearSheet: true, clearMaxCards: true),
        notice: notice,
        noticeId: notice == null ? null : state.noticeId + 1,
      ),
    );
  }

  void _onImageRemoved(DocumentImportImageRemoved event, Emitter<DocumentImportState> emit) {
    if (event.index < 0 || event.index >= state.images.length) return;
    final list = List<PickedImage>.of(state.images)..removeAt(event.index);
    emit(state.copyWith(images: list));
  }

  void _onImageMoved(DocumentImportImageMoved event, Emitter<DocumentImportState> emit) {
    final to = event.index + event.delta;
    if (event.index < 0 ||
        event.index >= state.images.length ||
        to < 0 ||
        to >= state.images.length)
      return;
    final list = List<PickedImage>.of(state.images);
    final item = list.removeAt(event.index);
    list.insert(to, item);
    emit(state.copyWith(images: list));
  }

  List<DocumentUploadFile> _uploadFiles() {
    final file = state.file;
    if (file != null) return [DocumentUploadFile(bytes: file.bytes, fileName: file.name)];
    return [
      for (var i = 0; i < state.images.length; i++)
        DocumentUploadFile(
          bytes: state.images[i].bytes,
          fileName: 'trang${i + 1}.${state.images[i].extension}',
        ),
    ];
  }

  /// Lý do không gửi được (kiểm tra phía app trước khi gọi BE); null nếu hợp lệ.
  String? validateBeforeStart() {
    final file = state.file;
    final quota = state.quota;
    if (!state.hasInput) return 'Vui lòng chọn một tệp hoặc ảnh.';
    final isTable = file?.isTable ?? false;
    if (quota != null) {
      if (quota.attemptsExhausted)
        return 'Hôm nay bạn đã thử quá nhiều lần. Vui lòng quay lại vào ngày mai.';
      if (!isTable) {
        if (!quota.aiAvailable) return 'Máy chủ chưa bật AI. Chỉ tệp csv/xlsx dùng được lúc này.';
        final coins = quota.coins;
        if (coins != null) {
          if (!coins.canUse) {
            return 'Bạn đã hết lượt AI miễn phí hôm nay. Xem video để nhận xu, hoặc dùng tệp csv/xlsx.';
          }
        } else if (quota.remainingToday <= 0) {
          return 'Bạn đã hết lượt AI hôm nay. Tệp csv/xlsx vẫn dùng được, hoặc thử lại sau 00:00.';
        }
      }
    }
    final o = state.options;
    if (file?.extension == 'pdf' &&
        o.pageFrom != null &&
        o.pageTo != null &&
        o.pageFrom! > o.pageTo!) {
      return 'Trang bắt đầu phải nhỏ hơn hoặc bằng trang kết thúc.';
    }
    if (isTable && (o.frontColumn < 1 || o.backColumn < 1 || o.frontColumn == o.backColumn)) {
      return 'Cột mặt trước và mặt sau phải khác nhau và bắt đầu từ 1.';
    }
    return null;
  }

  Future<void> _onStarted(DocumentImportStarted event, Emitter<DocumentImportState> emit) async {
    final file = state.file;
    if (!state.hasInput || state.phase == DocumentImportPhase.uploading) return;
    final problem = validateBeforeStart();
    if (problem != null) {
      emit(state.copyWith(notice: problem, noticeId: state.noticeId + 1));
      return;
    }

    _terminal = false;
    emit(
      state.copyWith(
        phase: DocumentImportPhase.uploading,
        uploadProgress: 0,
        chunks: const [],
        doneChunks: 0,
        totalChunks: 0,
        reconnectAttempt: 0,
        clearError: true,
        clearDraftId: true,
        errorIsBusy: false,
        fileName: file?.name ?? 'Ảnh (${state.images.length})',
      ),
    );

    try {
      // Gọi quota ngay trước khi tải: nếu token hết hạn thì được làm mới ở request nhẹ này,
      // tránh phải gửi lại FormData (chỉ dùng được một lần) sau khi refresh.
      try {
        final quota = await repository.getQuota();
        emit(state.copyWith(quota: quota));
        final problem2 = validateBeforeStart();
        if (problem2 != null) {
          emit(
            state.copyWith(
              phase: DocumentImportPhase.setup,
              notice: problem2,
              noticeId: state.noticeId + 1,
            ),
          );
          return;
        }
      } on Failure {
        // Không lấy được quota thì vẫn thử tải; BE sẽ từ chối nếu hết lượt.
      }

      final generation = ++_generation;
      final stream = await repository.upload(
        files: _uploadFiles(),
        fileType: file?.extension ?? 'image',
        options: state.options,
        onSendProgress: (sent, total) {
          if (total > 0 && !isClosed && !emit.isDone && generation == _generation) {
            // Cập nhật tiến độ tải lên qua emit trực tiếp (không đi qua event để khỏi nghẽn hàng đợi).
            if (state.phase == DocumentImportPhase.uploading) {
              emit(state.copyWith(uploadProgress: sent / total));
            }
          }
        },
      );
      _listen(stream, generation);
    } on Failure catch (f) {
      if (f.errorCode == AppErrorCodes.coinInsufficient) {
        await _backToSetupForCoins(emit, f);
        return;
      }
      await _fail(
        emit,
        _messageOf(f, 'Không thể tải tệp lên. Kiểm tra kết nối và thử lại.'),
        busy: false,
        failure: f,
      );
    } catch (e) {
      await _fail(
        emit,
        _messageOf(e, 'Không thể tải tệp lên. Kiểm tra kết nối và thử lại.'),
        busy: false,
        failure: e,
      );
    }
  }

  /// Thiếu xu (402): giữ nguyên tệp đã chọn, về màn chọn và tải lại hạn mức để hiện nút xem video.
  Future<void> _backToSetupForCoins(Emitter<DocumentImportState> emit, Failure f) async {
    emit(
      state.copyWith(
        phase: DocumentImportPhase.setup,
        clearDraftId: true,
        notice: DocumentImportErrorMessages.of(f),
        noticeId: state.noticeId + 1,
      ),
    );
    try {
      emit(state.copyWith(quota: await repository.getQuota()));
    } catch (_) {
      // Giữ hạn mức cũ.
    }
  }

  Future<void> _onResume(
    DocumentImportResumeRequested event,
    Emitter<DocumentImportState> emit,
  ) async {
    _terminal = false;
    emit(
      state.copyWith(
        phase: DocumentImportPhase.processing,
        draftId: event.draftId,
        chunks: const [],
        doneChunks: 0,
        totalChunks: 0,
        reconnectAttempt: 0,
        clearError: true,
        errorIsBusy: false,
      ),
    );
    await _openResume(emit, event.draftId);
  }

  Future<void> _onReconnectDue(
    DocumentImportReconnectDue event,
    Emitter<DocumentImportState> emit,
  ) async {
    final id = state.draftId;
    if (id == null || _terminal) return;
    await _openResume(emit, id);
  }

  Future<void> _openResume(Emitter<DocumentImportState> emit, String draftId) async {
    try {
      final generation = ++_generation;
      final stream = await repository.resume(draftId);
      _listen(stream, generation);
    } on Failure catch (f) {
      if (f is NetworkFailure) {
        await _scheduleReconnect(emit);
      } else {
        await _clearActive();
        await _fail(emit, DocumentImportErrorMessages.of(f), busy: false, failure: f);
      }
    } catch (_) {
      await _scheduleReconnect(emit);
    }
  }

  void _listen(Stream<DocumentImportStreamEvent> stream, int generation) {
    _sub?.cancel();
    _sub = stream.listen(
      (e) => add(DocumentImportStreamArrived(e, generation)),
      onError: (Object err) => add(DocumentImportStreamClosed(err, generation)),
      onDone: () => add(DocumentImportStreamClosed(null, generation)),
      cancelOnError: true,
    );
  }

  Future<void> _onArrived(
    DocumentImportStreamArrived event,
    Emitter<DocumentImportState> emit,
  ) async {
    if (event.generation != _generation || _terminal) return;
    final e = event.event;
    switch (e.type) {
      case DocumentImportEventType.started:
        final id = e.draftId;
        if (id != null) await _saveActive(id);
        emit(
          state.copyWith(
            phase: DocumentImportPhase.processing,
            draftId: id,
            fileName: e.fileName ?? state.fileName,
            fileType: e.fileType ?? state.fileType,
            usesAi: e.usesAi,
            totalChunks: e.totalChunks,
            reconnectAttempt: 0,
            clearError: true,
          ),
        );
        break;
      case DocumentImportEventType.progress:
        emit(
          state.copyWith(
            doneChunks: e.done,
            totalChunks: e.total > 0 ? e.total : null,
            reconnectAttempt: 0,
          ),
        );
        break;
      case DocumentImportEventType.chunk:
        emit(
          state.copyWith(
            chunks: _merge(DraftChunk(index: e.index, section: e.section, cards: e.cards)),
          ),
        );
        break;
      case DocumentImportEventType.chunkFailed:
        emit(
          state.copyWith(
            chunks: _merge(DraftChunk(index: e.index, failed: true, errorCode: e.errorCode)),
          ),
        );
        break;
      case DocumentImportEventType.done:
        _terminal = true;
        await _sub?.cancel();
        await _clearActive();
        var draft = e.draft;
        if (draft == null && state.draftId != null) {
          try {
            draft = await repository.getDraft(state.draftId!);
          } catch (_) {}
        }
        if (draft == null) {
          await _fail(emit, 'Không đọc được kết quả. Mở lại từ "Bản nháp của tôi".', busy: false);
        } else {
          emit(state.copyWith(phase: DocumentImportPhase.done, completedDraft: draft));
        }
        break;
      case DocumentImportEventType.error:
        _terminal = true;
        await _sub?.cancel();
        await _clearActive();
        await _fail(
          emit,
          DocumentImportErrorMessages.ofCode(e.errorCode, e.message),
          busy: DocumentImportErrorMessages.isBusy(e.errorCode),
        );
        break;
      case DocumentImportEventType.ping:
      case DocumentImportEventType.unknown:
        break;
    }
  }

  List<DraftChunk> _merge(DraftChunk incoming) {
    // Ghép theo `index`: nhận lại đoạn đã có thì ghi đè, không thêm trùng.
    final list = state.chunks.where((c) => c.index != incoming.index).toList()..add(incoming);
    list.sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  Future<void> _onClosed(
    DocumentImportStreamClosed event,
    Emitter<DocumentImportState> emit,
  ) async {
    if (event.generation != _generation || _terminal) return;
    if (state.phase != DocumentImportPhase.uploading &&
        state.phase != DocumentImportPhase.processing)
      return;

    if (state.draftId == null) {
      // Đứt trước khi nhận `started`: chưa có gì để nối lại.
      await _fail(emit, 'Mất kết nối khi đang tải tệp lên. Hãy thử lại.', busy: false);
      return;
    }
    // Luồng đóng mà chưa có `done`/`error` (mất mạng, im lặng quá 30 giây...): nối lại.
    await _scheduleReconnect(emit);
  }

  Future<void> _scheduleReconnect(Emitter<DocumentImportState> emit) async {
    final attempt = state.reconnectAttempt;
    final id = state.draftId;
    if (id == null) return;
    if (attempt >= reconnectDelays.length) {
      await _fail(
        emit,
        'Mất kết nối. Lượt xử lý vẫn chạy trên máy chủ, bạn có thể mở lại từ "Bản nháp của tôi".',
        busy: false,
      );
      return;
    }
    emit(state.copyWith(phase: DocumentImportPhase.processing, reconnectAttempt: attempt + 1));
    _reconnectTimer?.cancel();
    final generation = ++_generation; // vô hiệu hóa sự kiện muộn của luồng cũ
    _reconnectTimer = Timer(reconnectDelays[attempt], () {
      if (isClosed || generation != _generation || _terminal) return;
      add(const DocumentImportReconnectDue());
    });
  }

  Future<void> _onCancelled(
    DocumentImportCancelled event,
    Emitter<DocumentImportState> emit,
  ) async {
    final id = state.draftId;
    _terminal = true;
    _generation++;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _clearActive();
    if (id != null) {
      try {
        await repository.delete(id);
      } catch (_) {
        // Hủy lỗi mạng: BE sẽ tự dọn; lượt vẫn tính vào số lần thử.
      }
    }
    emit(
      state.copyWith(
        phase: DocumentImportPhase.setup,
        clearDraftId: true,
        chunks: const [],
        doneChunks: 0,
        totalChunks: 0,
        reconnectAttempt: 0,
        clearPending: true,
        notice: 'Đã hủy lượt xử lý.',
        noticeId: state.noticeId + 1,
      ),
    );
    add(const DocumentImportQuotaRequested());
  }

  void _onReset(DocumentImportReset event, Emitter<DocumentImportState> emit) {
    emit(
      state.copyWith(
        phase: DocumentImportPhase.setup,
        clearError: true,
        errorIsBusy: false,
        clearDraftId: true,
        chunks: const [],
        doneChunks: 0,
        totalChunks: 0,
        reconnectAttempt: 0,
      ),
    );
    add(const DocumentImportQuotaRequested());
  }

  Future<void> _fail(
    Emitter<DocumentImportState> emit,
    String message, {
    required bool busy,
    Object? failure,
  }) async {
    _terminal = true;
    _generation++;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    emit(
      state.copyWith(
        phase: DocumentImportPhase.failed,
        errorMessage: message,
        errorIsBusy:
            busy || (failure is Failure && DocumentImportErrorMessages.isBusy(failure.errorCode)),
      ),
    );
  }

  @override
  Future<void> close() async {
    _generation++;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
