/// Lời mời vào lớp của tôi (`GET /classes/invitations`). Lời mời không hết hạn.
class ClassInvitationModel {
  final String classId;
  final String className;
  final String? classDescription;
  final int memberCount;
  final DateTime? invitedAt;

  /// Có thể `null` nếu người mời đã xóa tài khoản.
  final String? invitedBy;
  final String? inviterName;

  const ClassInvitationModel({
    required this.classId,
    required this.className,
    this.classDescription,
    this.memberCount = 0,
    this.invitedAt,
    this.invitedBy,
    this.inviterName,
  });

  factory ClassInvitationModel.fromJson(Map<String, dynamic> json) {
    return ClassInvitationModel(
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      classDescription: json['classDescription'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      invitedAt: DateTime.tryParse(json['invitedAt']?.toString() ?? ''),
      invitedBy: json['invitedBy'] as String?,
      inviterName: json['inviterName'] as String?,
    );
  }
}

/// Một dòng kết quả tra cứu / gửi lời mời theo email.
class InviteLookupRow {
  /// Có tài khoản, chưa có dòng trong lớp, không bị khóa -> mời được.
  static const String ok = 'ok';
  static const String notFound = 'not_found';
  static const String alreadyMember = 'already_member';
  static const String pending = 'pending';
  static const String invited = 'invited';

  /// Tài khoản bị khóa: hiển thị trung tính, không nêu lý do.
  static const String locked = 'locked';

  final String email;
  final String status;
  final String? userId;
  final String? fullName;

  /// Người gọi là owner/admin hoặc chính người đã mời (chỉ có ở status `invited`/sau khi gửi).
  final bool canRevoke;

  /// Chỉ có sau `POST /invitations`: true nếu vừa tạo lời mời mới.
  final bool newlyInvited;

  const InviteLookupRow({
    required this.email,
    required this.status,
    this.userId,
    this.fullName,
    this.canRevoke = false,
    this.newlyInvited = false,
  });

  bool get canInvite => status == ok;

  factory InviteLookupRow.fromJson(Map<String, dynamic> json) {
    return InviteLookupRow(
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? notFound,
      userId: json['userId'] as String?,
      fullName: json['fullName'] as String?,
      canRevoke: json['canRevoke'] as bool? ?? false,
      newlyInvited: json['newlyInvited'] as bool? ?? false,
    );
  }
}

/// Kết quả `POST /classes/join` và `POST /classes/:id/invitations/accept`.
class JoinResult {
  static const String approved = 'approved';
  static const String pending = 'pending';

  final String classId;
  final String className;

  /// approved | pending (pending -> hiện "chờ giáo viên duyệt").
  final String status;
  final String message;

  const JoinResult({
    required this.classId,
    required this.className,
    required this.status,
    this.message = '',
  });

  bool get isPending => status == pending;

  factory JoinResult.fromJson(Map<String, dynamic> json) {
    return JoinResult(
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      status: json['status'] as String? ?? approved,
      message: json['message'] as String? ?? '',
    );
  }
}
