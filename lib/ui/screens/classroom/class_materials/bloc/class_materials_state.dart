import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';

enum ClassMaterialsStatus { initial, loading, success, failure }

/// Yêu cầu thêm bị BE chặn (409) vì có học liệu trùng; chờ người dùng chọn cách xử lý.
class PendingMaterialAdd extends Equatable {
  final String classId;
  final List<String> deckIds;
  final List<String> folderIds;
  final List<DuplicateInfo> duplicates;

  const PendingMaterialAdd({
    required this.classId,
    required this.deckIds,
    required this.folderIds,
    required this.duplicates,
  });

  /// `merge` chỉ có tác dụng khi lớp đang có deck lẻ là bản sao của deck con trong folder đang thêm.
  bool get canMerge => duplicates.any((d) => d.canMerge);

  @override
  List<Object?> get props => [classId, deckIds, folderIds, duplicates];
}

class ClassMaterialsState extends Equatable {
  final ClassMaterialsStatus status;

  /// Folder + deck lẻ (deck nằm trong folder chỉ thấy khi mở folder).
  final List<ClassMaterialItem> items;
  final String? errorMessage;

  /// Lớp không còn truy cập được (xóa / bị đuổi): màn hình nên đóng lại.
  final bool isGone;

  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;

  final bool isProcessing;
  final bool isRefreshing;

  final bool isSelectionMode;
  final Set<String> selectedIds;

  final PendingMaterialAdd? pendingAdd;

  /// Thông báo một lần; `noticeId` tăng mỗi lần để listener bắt được cả khi nội dung trùng.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  const ClassMaterialsState({
    this.status = ClassMaterialsStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.isGone = false,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.isProcessing = false,
    this.isRefreshing = false,
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.pendingAdd,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  /// Các mục đang chọn (giữ thứ tự hiển thị).
  List<ClassMaterialItem> get selectedItems => [
    for (final i in items)
      if (selectedIds.contains(i.id)) i,
  ];

  ClassMaterialsState copyWith({
    ClassMaterialsStatus? status,
    List<ClassMaterialItem>? items,
    String? errorMessage,
    bool? isGone,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    bool? isProcessing,
    bool? isRefreshing,
    bool? isSelectionMode,
    Set<String>? selectedIds,
    PendingMaterialAdd? pendingAdd,
    bool clearPendingAdd = false,
    String? notice,
    bool noticeIsError = false,
  }) {
    return ClassMaterialsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      isGone: isGone ?? this.isGone,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isProcessing: isProcessing ?? this.isProcessing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      pendingAdd: clearPendingAdd ? null : (pendingAdd ?? this.pendingAdd),
      notice: notice,
      noticeIsError: noticeIsError,
      noticeId: notice != null ? noticeId + 1 : noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    errorMessage,
    isGone,
    currentPage,
    hasMore,
    isLoadingMore,
    searchQuery,
    isProcessing,
    isRefreshing,
    isSelectionMode,
    selectedIds,
    pendingAdd,
    notice,
    noticeIsError,
    noticeId,
  ];
}
