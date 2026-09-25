import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/folder_model.dart';

enum FolderDetailStatus { initial, loading, success, failure, deleted }

class FolderDetailState extends Equatable {
  final FolderDetailStatus status;
  final bool isRefreshing;
  final FolderModel? folder;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? toastTriggerTime;
  final bool isSelectionMode;
  final List<String> selectedDeckIds;
  final String? clonedFolderId;

  const FolderDetailState({
    this.status = FolderDetailStatus.initial,
    this.isRefreshing = false,
    this.folder,
    this.errorMessage,
    this.successMessage,
    this.toastTriggerTime,
    this.isSelectionMode = false,
    this.selectedDeckIds = const [],
    this.clonedFolderId,
  });

  FolderDetailState copyWith({
    FolderDetailStatus? status,
    bool? isRefreshing,
    FolderModel? folder,
    String? errorMessage,
    String? successMessage,
    DateTime? toastTriggerTime,
    bool? isSelectionMode,
    List<String>? selectedDeckIds,
    String? clonedFolderId,
  }) {
    return FolderDetailState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      folder: folder ?? this.folder,
      errorMessage: errorMessage,
      successMessage: successMessage,
      toastTriggerTime: toastTriggerTime,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedDeckIds: selectedDeckIds ?? this.selectedDeckIds,
      clonedFolderId: clonedFolderId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isRefreshing,
    folder,
    errorMessage,
    successMessage,
    toastTriggerTime,
    isSelectionMode,
    selectedDeckIds,
    clonedFolderId,
  ];
}
