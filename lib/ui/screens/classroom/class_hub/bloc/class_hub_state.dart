import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_model.dart';

enum ClassHubStatus { initial, loading, success, failure }

/// Lý do màn hub cần đóng lại (người dùng không còn ở trong lớp nữa).
enum ClassHubExit { left, deleted, declined, gone }

class ClassHubState extends Equatable {
  final ClassHubStatus status;
  final ClassModel? classModel;
  final String? errorMessage;

  // Custom metrics for Hub
  final int pendingCount;

  /// Đang thực hiện một thao tác (rời lớp / xóa lớp / tham gia / phản hồi lời mời).
  final bool isBusy;

  /// Khác null = màn hub phải đóng (rời / xóa / từ chối / lớp không còn truy cập được).
  final ClassHubExit? exit;

  /// Thông báo một lần; `noticeId` tăng mỗi lần để listener bắt được cả khi nội dung trùng.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  const ClassHubState({
    this.status = ClassHubStatus.initial,
    this.classModel,
    this.errorMessage,
    this.pendingCount = 0,
    this.isBusy = false,
    this.exit,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  ClassHubState copyWith({
    ClassHubStatus? status,
    ClassModel? classModel,
    String? errorMessage,
    int? pendingCount,
    bool? isBusy,
    ClassHubExit? exit,
    String? notice,
    bool noticeIsError = false,
  }) {
    return ClassHubState(
      status: status ?? this.status,
      classModel: classModel ?? this.classModel,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingCount: pendingCount ?? this.pendingCount,
      isBusy: isBusy ?? this.isBusy,
      exit: exit ?? this.exit,
      notice: notice,
      noticeIsError: noticeIsError,
      noticeId: notice != null ? noticeId + 1 : noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    classModel,
    errorMessage,
    pendingCount,
    isBusy,
    exit,
    notice,
    noticeIsError,
    noticeId,
  ];
}
