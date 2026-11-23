import 'enums.dart';

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  /// Lớp gắn với thông báo; null nếu không gắn lớp.
  final String? classId;

  /// null: không gắn lớp; true: còn vào được; false: lớp đã xóa hoặc user đã rời/bị đuổi.
  final bool? classAvailable;

  /// `{path, classId?}`; `path` là deep link `minddeck://minddeck.com/...`.
  final Map<String, dynamic>? actionData;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.classId,
    this.classAvailable,
    this.actionData,
  });

  /// Thông báo gắn với lớp mà user không còn vào được.
  bool get isClassUnavailable => classAvailable == false;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      classId: json['classId'] as String?,
      classAvailable: json['classAvailable'] as bool?,
      actionData: _parseActionData(json['actionData'] ?? json['action_data']),
    );
  }

  static Map<String, dynamic>? _parseActionData(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Đường dẫn nội bộ của go_router suy từ deep link (`/classroom/<id>`,
  /// `/profile/classrooms`...); null nếu thông báo không có đích.
  String? get targetRoute {
    if (isClassUnavailable) return null;
    final raw = actionData?['path']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final path = Uri.tryParse(raw)?.path;
    if (path != null && path.isNotEmpty) return path;
    final classId = actionData?['classId']?.toString();
    return classId != null && classId.isNotEmpty ? '/classroom/$classId' : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toJson(),
      'title': title,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'classId': classId,
      'classAvailable': classAvailable,
      'actionData': actionData,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    String? classId,
    bool? classAvailable,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      classId: classId ?? this.classId,
      classAvailable: classAvailable ?? this.classAvailable,
      actionData: actionData ?? this.actionData,
    );
  }
}
