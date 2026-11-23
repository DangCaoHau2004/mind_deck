enum ReportType {
  contentViolation('content_violation'),
  bugUi('bug_ui'),
  paymentIssue('payment_issue'),
  accountSupport('account_support'),
  other('other');

  final String value;
  const ReportType(this.value);

  static ReportType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'content_violation':
        return ReportType.contentViolation;
      case 'bug_ui':
        return ReportType.bugUi;
      case 'payment_issue':
        return ReportType.paymentIssue;
      case 'account_support':
        return ReportType.accountSupport;
      case 'other':
      default:
        return ReportType.other;
    }
  }

  String toJson() => value;
}

enum ReportTargetType {
  deck('deck'),
  folder('folder'),
  user('user'),
  classroom('class'),
  system('system');

  final String value;
  const ReportTargetType(this.value);

  static ReportTargetType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'deck':
        return ReportTargetType.deck;
      case 'folder':
        return ReportTargetType.folder;
      case 'user':
        return ReportTargetType.user;
      case 'class':
        return ReportTargetType.classroom;
      case 'system':
      default:
        return ReportTargetType.system;
    }
  }

  String toJson() => value;
}

/// Người tạo báo cáo: `user` tự gửi, `admin` là thông báo vi phạm do quản trị viên hệ thống ghi.
enum ReportSource {
  user,
  admin;

  static ReportSource fromString(String? val) =>
      val?.toLowerCase() == 'admin' ? ReportSource.admin : ReportSource.user;

  String toJson() => name;
}

enum ReportStatus {
  pending,
  processing,
  resolved,
  dismissed;

  static ReportStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'processing':
        return ReportStatus.processing;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      case 'pending':
      default:
        return ReportStatus.pending;
    }
  }

  String toJson() => name;
}

class ReportModel {
  final String id;
  final String reporterId;
  final ReportType type;
  final ReportTargetType targetType;
  final String? targetId;

  /// Báo cáo `admin` luôn ở trạng thái đã giải quyết, `description`/`resolutionNote` là lý do admin ghi.
  final ReportSource source;

  /// Tên đối tượng bị báo cáo (null với báo cáo hệ thống hoặc đối tượng đã bị xóa).
  final String? targetName;
  final String description;

  /// Chỉ có trong danh sách (BE cắt 50 ký tự); chi tiết dùng `description`.
  final String? descriptionPreview;

  /// Admin đã phản hồi (chỉ có trong danh sách).
  final bool hasResponse;
  final List<String> attachments;
  final ReportStatus status;
  final String? resolvedBy;
  final String? resolutionNote;
  final DateTime createdAt;

  /// null khi báo cáo chưa được cập nhật lần nào hoặc API danh sách không trả.
  final DateTime? updatedAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.targetType,
    this.targetId,
    this.source = ReportSource.user,
    this.targetName,
    required this.description,
    this.descriptionPreview,
    this.hasResponse = false,
    required this.attachments,
    this.status = ReportStatus.pending,
    this.resolvedBy,
    this.resolutionNote,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isFromAdmin => source == ReportSource.admin;

  /// Nội dung để hiển thị: bản đầy đủ nếu có, không thì bản xem trước của danh sách.
  String get displayDescription =>
      description.isNotEmpty ? description : (descriptionPreview ?? '');

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? json['reporter_id'] as String? ?? '',
      type: ReportType.fromString(json['type'] as String?),
      targetType: ReportTargetType.fromString(
        json['targetType'] as String? ?? json['target_type'] as String?,
      ),
      targetId: json['targetId'] as String? ?? json['target_id'] as String?,
      source: ReportSource.fromString(json['source'] as String?),
      targetName: json['targetName'] as String? ?? json['target_name'] as String?,
      description: json['description'] as String? ?? '',
      descriptionPreview: json['descriptionPreview'] as String?,
      hasResponse: json['hasResponse'] as bool? ?? false,
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: ReportStatus.fromString(json['status'] as String?),
      resolvedBy: json['resolvedBy'] as String? ?? json['resolved_by'] as String?,
      resolutionNote: json['resolutionNote'] as String? ?? json['resolution_note'] as String?,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
        json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'type': type.toJson(),
      'targetType': targetType.toJson(),
      if (targetId != null) 'targetId': targetId,
      'source': source.toJson(),
      if (targetName != null) 'targetName': targetName,
      'description': description,
      if (descriptionPreview != null) 'descriptionPreview': descriptionPreview,
      'hasResponse': hasResponse,
      'attachments': attachments,
      'status': status.toJson(),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    ReportType? type,
    ReportTargetType? targetType,
    String? targetId,
    ReportSource? source,
    String? targetName,
    String? description,
    String? descriptionPreview,
    bool? hasResponse,
    List<String>? attachments,
    ReportStatus? status,
    String? resolvedBy,
    String? resolutionNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      source: source ?? this.source,
      targetName: targetName ?? this.targetName,
      description: description ?? this.description,
      descriptionPreview: descriptionPreview ?? this.descriptionPreview,
      hasResponse: hasResponse ?? this.hasResponse,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
