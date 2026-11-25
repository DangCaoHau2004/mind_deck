import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
import 'package:mind_deck/data/models/page_info.dart';

enum ClassAssignmentsStatus { initial, loading, success, failure }

class ClassAssignmentsState extends Equatable {
  final ClassAssignmentsStatus status;
  final bool isTeacher;

  /// BE `tab=active`: giảng viên = chưa kết thúc (kể cả chưa bắt đầu); học viên = đang diễn ra mà chưa xong.
  final List<ClassAssignmentModel> active;

  /// BE `tab=history`. Lưu ý học viên đã nộp 1 lượt nhưng còn lượt vẫn nằm ở đây (hiện nút "Làm lại").
  final List<ClassAssignmentModel> history;

  /// `GET /assignments/overdue` (chỉ học viên; giảng viên luôn rỗng).
  final List<ClassAssignmentSubmissionModel> overdue;

  /// Tiến độ tải thêm của từng danh sách (cuộn để tải thêm).
  final PageInfo activePage;
  final PageInfo historyPage;
  final PageInfo overduePage;
  final String? errorMessage;

  final bool isProcessing;

  /// Thông báo một lần cho màn danh sách; `noticeId` tăng mỗi lần.
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  /// Lỗi khi tạo / sửa — hiện ở màn form (không lẫn với toast của danh sách).
  final String? formError;
  final int formErrorId;

  /// Tăng mỗi khi tạo / sửa thành công để form tự đóng.
  final int savedId;

  const ClassAssignmentsState({
    this.status = ClassAssignmentsStatus.initial,
    this.isTeacher = false,
    this.active = const [],
    this.history = const [],
    this.overdue = const [],
    this.activePage = const PageInfo(),
    this.historyPage = const PageInfo(),
    this.overduePage = const PageInfo(),
    this.errorMessage,
    this.isProcessing = false,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
    this.formError,
    this.formErrorId = 0,
    this.savedId = 0,
  });

  /// Học viên: bài đã làm xong hoặc đã làm ít nhất một lượt (kể cả còn lượt làm lại).
  List<ClassAssignmentModel> get studentDone => [
    for (final a in history)
      if (a.my != null && (a.my!.status == AssignmentStatus.completed || a.my!.attemptsCount > 0))
        a,
  ];

  ClassAssignmentsState copyWith({
    ClassAssignmentsStatus? status,
    bool? isTeacher,
    List<ClassAssignmentModel>? active,
    List<ClassAssignmentModel>? history,
    List<ClassAssignmentSubmissionModel>? overdue,
    PageInfo? activePage,
    PageInfo? historyPage,
    PageInfo? overduePage,
    String? errorMessage,
    bool? isProcessing,
    String? notice,
    bool noticeIsError = false,
    String? formError,
    bool saved = false,
  }) {
    return ClassAssignmentsState(
      status: status ?? this.status,
      isTeacher: isTeacher ?? this.isTeacher,
      active: active ?? this.active,
      history: history ?? this.history,
      overdue: overdue ?? this.overdue,
      activePage: activePage ?? this.activePage,
      historyPage: historyPage ?? this.historyPage,
      overduePage: overduePage ?? this.overduePage,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      notice: notice,
      noticeIsError: noticeIsError,
      noticeId: notice != null ? noticeId + 1 : noticeId,
      formError: formError,
      formErrorId: formError != null ? formErrorId + 1 : formErrorId,
      savedId: saved ? savedId + 1 : savedId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isTeacher,
    active,
    history,
    overdue,
    activePage,
    historyPage,
    overduePage,
    errorMessage,
    isProcessing,
    notice,
    noticeIsError,
    noticeId,
    formError,
    formErrorId,
    savedId,
  ];
}
