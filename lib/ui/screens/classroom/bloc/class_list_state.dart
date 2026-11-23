import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/models/class/class_model.dart';

enum ClassListStatus { initial, loading, success, failure }

class ClassListState extends Equatable {
  final ClassListStatus status;
  final List<ClassModel> classes;
  final String? errorMessage;

  /// Lời mời vào lớp đang chờ tôi trả lời (mới nhất trước, không hết hạn).
  final List<ClassInvitationModel> invitations;

  // Trạng thái xử lý tham gia / tạo lớp / phản hồi lời mời
  final bool isProcessing;
  final String? processErrorMessage;
  final bool processSuccess;

  /// Kết quả tham gia / chấp nhận lời mời (`approved` hoặc `pending`); null khi từ chối.
  final JoinResult? joinResult;

  /// Lớp đang được phản hồi lời mời (để khóa nút của đúng thẻ).
  final String? respondingClassId;

  /// Thông báo một lần cho danh sách lời mời; `noticeId` tăng mỗi lần.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  const ClassListState({
    this.status = ClassListStatus.initial,
    this.classes = const [],
    this.errorMessage,
    this.invitations = const [],
    this.isProcessing = false,
    this.processErrorMessage,
    this.processSuccess = false,
    this.joinResult,
    this.respondingClassId,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  ClassListState copyWith({
    ClassListStatus? status,
    List<ClassModel>? classes,
    String? errorMessage,
    List<ClassInvitationModel>? invitations,
    bool? isProcessing,
    String? processErrorMessage,
    bool? processSuccess,
    JoinResult? joinResult,
    String? respondingClassId,
    String? notice,
    bool noticeIsError = false,
  }) {
    return ClassListState(
      status: status ?? this.status,
      classes: classes ?? this.classes,
      errorMessage: errorMessage ?? this.errorMessage,
      invitations: invitations ?? this.invitations,
      isProcessing: isProcessing ?? this.isProcessing,
      processErrorMessage: processErrorMessage,
      processSuccess: processSuccess ?? false,
      joinResult: joinResult,
      respondingClassId: respondingClassId,
      notice: notice,
      noticeIsError: noticeIsError,
      noticeId: notice != null ? noticeId + 1 : noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    classes,
    errorMessage,
    invitations,
    isProcessing,
    processErrorMessage,
    processSuccess,
    joinResult,
    respondingClassId,
    notice,
    noticeIsError,
    noticeId,
  ];
}
