import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/tag_model.dart';

enum DeckFormStatus { initial, loading, success, failure }

class DeckFormState extends Equatable {
  final DeckFormStatus status;
  final String? errorMessage;
  final String? successMessage;
  final List<TagModel> availableTags;
  final TagModel? recentlyAddedTag;

  /// Đang chờ danh sách tag lần đầu (chưa có bản đã nhớ): form hiện chip giữ chỗ.
  final bool isLoadingTags;

  const DeckFormState({
    this.status = DeckFormStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.availableTags = const [],
    this.recentlyAddedTag,
    this.isLoadingTags = true,
  });

  DeckFormState copyWith({
    DeckFormStatus? status,
    String? errorMessage,
    String? successMessage,
    List<TagModel>? availableTags,
    TagModel? recentlyAddedTag,
    bool? isLoadingTags,
  }) {
    return DeckFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      availableTags: availableTags ?? this.availableTags,
      isLoadingTags: isLoadingTags ?? this.isLoadingTags,
      recentlyAddedTag: recentlyAddedTag, // don't persist if not provided to clear it
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
