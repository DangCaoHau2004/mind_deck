import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/failures.dart';

// TODO: [i18n] Tạm thời để tiếng Việt cứng tại MỘT chỗ (xem plan: chưa thêm vào vi.json
// cho đến khi chuỗi được chốt). Khi chốt xong, chuyển cả map này sang vi.json (`error_<code>`).
class ClassErrorMessages {
  ClassErrorMessages._();

  static const Map<String, String> _messages = {
    AppErrorCodes.rateLimitExceeded: 'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.',
    AppErrorCodes.systemInvalidInputFormat: 'Dữ liệu gửi lên không hợp lệ.',

    // Deck / Folder / Study
    AppErrorCodes.deckNotFound: 'Không tìm thấy bộ thẻ hoặc bạn không còn quyền truy cập.',
    AppErrorCodes.folderNotFound: 'Không tìm thấy thư mục hoặc bạn không còn quyền truy cập.',
    AppErrorCodes.deckAccessDenied: 'Bạn không có quyền với bộ thẻ này.',
    AppErrorCodes.folderAccessDenied: 'Bạn không có quyền với thư mục này.',
    AppErrorCodes.shareCannotCopyDeck: 'Bạn không thể sao chép bộ thẻ này.',
    AppErrorCodes.shareCannotCopyFolder: 'Bạn không thể sao chép thư mục này.',
    AppErrorCodes.shareDeckNotFound: 'Không tìm thấy bộ thẻ.',
    AppErrorCodes.shareFolderNotFound: 'Không tìm thấy thư mục.',
    AppErrorCodes.studyNoCardsFound: 'Không có thẻ nào có thể học.',
    AppErrorCodes.studyNoActiveSession: 'Phiên học không còn tồn tại.',

    // Lớp học - chung / thành viên
    AppErrorCodes.classNotFound: 'Lớp học không tồn tại hoặc đã bị xóa.',
    AppErrorCodes.classNotAMember: 'Bạn không còn là thành viên của lớp này.',
    AppErrorCodes.classClassIdRequired: 'Thiếu mã lớp học.',
    AppErrorCodes.classNameEmpty: 'Tên lớp không được để trống.',
    AppErrorCodes.classNewOwnerInvalid:
        'Không chuyển quyền được cho người này. Họ phải là thành viên đã được duyệt của lớp.',
    AppErrorCodes.classSettingsInvalid: 'Cài đặt lớp không hợp lệ.',
    AppErrorCodes.classNotifySettingsInvalid: 'Cài đặt thông báo không hợp lệ.',
    AppErrorCodes.classJoinCodeOrIdRequired: 'Vui lòng nhập mã lớp.',
    AppErrorCodes.classJoinCodeInvalid: 'Mã lớp không đúng.',
    AppErrorCodes.classPrivateClassRequiresCode: 'Lớp riêng tư cần mã lớp để tham gia.',
    AppErrorCodes.classAlreadyJoinedOrPending: 'Bạn đã tham gia hoặc đang chờ duyệt lớp này.',
    AppErrorCodes.classCannotApproveSelf: 'Bạn không thể tự duyệt chính mình.',
    AppErrorCodes.classRequestNotFound: 'Không tìm thấy yêu cầu tham gia.',
    AppErrorCodes.classUserNotPending:
        'Người này chưa ở trạng thái chờ duyệt (có thể đang chờ chấp nhận lời mời).',
    AppErrorCodes.classUserNotFound: 'Không tìm thấy người dùng trong lớp.',
    AppErrorCodes.classCannotKickOwner: 'Không thể xóa chủ lớp.',
    AppErrorCodes.classCannotKickSelf: 'Bạn không thể tự xóa chính mình khỏi lớp.',
    AppErrorCodes.classCannotManageHigherRole:
        'Bạn không thể thao tác với người có vai trò cao hơn hoặc ngang bạn.',
    AppErrorCodes.classMemberStatusInvalid: 'Trạng thái thành viên không hợp lệ.',
    AppErrorCodes.classRoleInvalid: 'Vai trò không hợp lệ.',
    AppErrorCodes.classMemberNotFound: 'Không tìm thấy thành viên.',
    AppErrorCodes.classOwnerCannotLeave:
        'Chủ lớp không thể rời lớp. Hãy xóa lớp nếu không còn dùng.',

    // Lời mời
    AppErrorCodes.classInviteEmailsRequired: 'Vui lòng nhập ít nhất một email.',
    AppErrorCodes.classInviteNotAllowed: 'Lớp này không cho phép học viên mời thành viên.',
    AppErrorCodes.classInviteNotFound: 'Lời mời không tồn tại hoặc đã được xử lý.',

    // Học liệu / clone
    AppErrorCodes.classMaterialSourceNotAccessible:
        'Không thể thêm học liệu đang là bản sao của lớp. Hãy sao chép về thư viện cá nhân trước.',
    AppErrorCodes.classMaterialDuplicate: 'Có học liệu đã tồn tại trong lớp.',
    AppErrorCodes.classMaterialsEmpty: 'Vui lòng chọn ít nhất một học liệu.',
    AppErrorCodes.classMaterialDuplicatePolicyInvalid: 'Cách xử lý học liệu trùng không hợp lệ.',
    AppErrorCodes.classFolderNotInClass: 'Thư mục không thuộc lớp này.',
    AppErrorCodes.classMaterialNotInClass: 'Học liệu không thuộc lớp này.',
    AppErrorCodes.classMaterialInUse:
        'Học liệu đang là nguồn của một bài giao. Hãy xóa hoặc đổi bài giao trước.',
    AppErrorCodes.classCloneTargetInvalid: 'Đối tượng cần sao chép không hợp lệ.',
    AppErrorCodes.classCloneNotAllowed: 'Lớp này không cho phép học viên sao chép học liệu.',

    // Bài giao / xếp hạng
    AppErrorCodes.classAssignmentMissingRequiredFields: 'Vui lòng nhập đủ thông tin bài giao.',
    AppErrorCodes.classAssignmentTypeInvalid: 'Loại bài giao không hợp lệ.',
    AppErrorCodes.classAssignmentTimeInvalid: 'Thời gian bài giao không hợp lệ.',
    AppErrorCodes.classAssignmentModeInvalid: 'Chế độ hoặc khối lượng bài học không hợp lệ.',
    AppErrorCodes.classAssignmentSourcesInvalid: 'Nguồn học liệu của bài giao không hợp lệ.',
    AppErrorCodes.classAssignmentTestInvalid: 'Đề kiểm tra không hợp lệ hoặc không thuộc lớp.',
    AppErrorCodes.classAssignmentTestMismatch: 'Bài giao không khớp với đề kiểm tra.',
    AppErrorCodes.classAssignmentNotFound: 'Bài giao không tồn tại hoặc đã bị xóa.',
    AppErrorCodes.classAssignmentLocked:
        'Bài giao đã có hoạt động nên không thể đổi nội dung hoặc giờ bắt đầu.',
    AppErrorCodes.classLeaderboardDisabled: 'Lớp này đã tắt bảng xếp hạng.',

    // Bài kiểm tra
    AppErrorCodes.testClassRequired: 'Thiếu thông tin lớp học.',
    AppErrorCodes.testKindInvalid: 'Loại đề không hợp lệ.',
    AppErrorCodes.testPersonalAutoOnly: 'Đề cá nhân chỉ hỗ trợ tạo tự động.',
    AppErrorCodes.testSettingsInvalid: 'Cài đặt đề không hợp lệ.',
    AppErrorCodes.testQuestionsInvalid: 'Danh sách câu hỏi không hợp lệ.',
    AppErrorCodes.testCardIdsEmpty: 'Vui lòng chọn ít nhất một thẻ.',
    AppErrorCodes.testTooManyCards: 'Số thẻ vượt quá giới hạn cho phép.',
    AppErrorCodes.testQuestionTypesEmpty: 'Vui lòng chọn ít nhất một dạng câu hỏi.',
    AppErrorCodes.testAssignmentRequired: 'Bài kiểm tra này cần được làm thông qua bài giao.',
    AppErrorCodes.testAnswersEmpty: 'Chưa có câu trả lời nào để nộp.',
    AppErrorCodes.testSubmitDataInvalid: 'Dữ liệu bài làm không hợp lệ.',
    AppErrorCodes.testSourceRequired: 'Vui lòng chọn nguồn thẻ.',
    AppErrorCodes.testTeacherOnly: 'Chỉ giảng viên mới thực hiện được thao tác này.',
    AppErrorCodes.testEditLocked: 'Đề đã có người làm nên không thể sửa nội dung.',
    AppErrorCodes.testNotInClass: 'Bạn không thuộc diện được giao bài kiểm tra này.',
    AppErrorCodes.testNotStarted: 'Bài kiểm tra chưa đến giờ bắt đầu.',
    AppErrorCodes.testEnded: 'Bài kiểm tra đã kết thúc.',
    AppErrorCodes.testAttemptsExhausted: 'Bạn đã hết lượt làm bài.',
    AppErrorCodes.testSessionExpired: 'Phiên làm bài đã hết hạn.',
    AppErrorCodes.testNotFound: 'Không tìm thấy bài kiểm tra.',
    AppErrorCodes.testNoQuestions: 'Bài kiểm tra chưa có câu hỏi.',
    AppErrorCodes.testNoCardsFound: 'Không tìm thấy thẻ hợp lệ để tạo đề.',
    AppErrorCodes.testSessionNotFound:
        'Phiên làm bài không còn tồn tại (chưa bắt đầu hoặc đã nộp).',
    AppErrorCodes.testAttemptNotFound: 'Không tìm thấy lượt làm bài.',

    // Thống kê
    AppErrorCodes.analyticsStudentIdRequiredForTeacher: 'Vui lòng chọn một học viên để xem.',
    AppErrorCodes.analyticsTimezoneInvalid: 'Múi giờ không hợp lệ.',
    AppErrorCodes.analyticsStatusInvalid: 'Trạng thái lọc không hợp lệ.',
    AppErrorCodes.analyticsNotATest: 'Chỉ bài kiểm tra mới có dữ liệu này.',
    AppErrorCodes.analyticsLeaderboardMonthInvalid: 'Tháng xếp hạng không hợp lệ.',
  };

  /// Thông báo cho người dùng theo `errorCode`; thiếu thì dùng `message` của BE.
  static String of(Failure failure) {
    switch (failure.errorCode) {
      case AppErrorCodes.classNameTooLong:
        return 'Tên lớp tối đa ${failure.params?['max'] ?? 255} ký tự.';
      case AppErrorCodes.classInviteTooMany:
        final max = failure.params?['max'];
        return 'Mỗi lần chỉ mời tối đa ${max ?? 50} email.';
      case AppErrorCodes.classInsufficientPermissions:
        final required = failure.params?['required'];
        return required == null
            ? 'Bạn không đủ quyền để thực hiện thao tác này.'
            : 'Chỉ $required mới thực hiện được thao tác này.';
    }
    return _messages[failure.errorCode] ?? failure.message;
  }

  /// Mã lỗi nghĩa là người dùng không còn truy cập được lớp (nên thoát về danh sách lớp).
  static bool isClassGone(Failure failure) =>
      failure.errorCode == AppErrorCodes.classNotFound ||
      failure.errorCode == AppErrorCodes.classNotAMember;
}
