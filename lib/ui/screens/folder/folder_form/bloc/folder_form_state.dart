import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/tag_model.dart';

enum FolderFormStatus { initial, loading, success, failure }

class FolderFormState extends Equatable {
  final FolderFormStatus status;
  final String? errorMessage;
  final String? successMessage;
  final List<TagModel> availableTags;
  final TagModel? recentlyAddedTag;

  /// Đang chờ danh sách tag lần đầu (chưa có bản đã nhớ): form hiện chip giữ chỗ.
  final bool isLoadingTags;

  const FolderFormState({
    this.status = FolderFormStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.availableTags = const [],
    this.recentlyAddedTag,
    this.isLoadingTags = true,
  });

  FolderFormState copyWith({
    FolderFormStatus? status,
    String? errorMessage,
    String? successMessage,
    List<TagModel>? availableTags,
    TagModel? recentlyAddedTag,
    bool? isLoadingTags,
  }) {
    return FolderFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      availableTags: availableTags ?? this.availableTags,
      isLoadingTags: isLoadingTags ?? this.isLoadingTags,
      recentlyAddedTag: recentlyAddedTag,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    availableTags,
    recentlyAddedTag,
    isLoadingTags,
  ];
}
