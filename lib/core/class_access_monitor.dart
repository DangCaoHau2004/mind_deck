import 'dart:async';

/// Một request tới API của lớp bị từ chối vì người dùng không còn trong lớp
/// (bị đuổi, đã rời, lớp bị xóa).
class ClassAccessLost {
  final String classId;
  final String errorCode;
  final String? message;

  const ClassAccessLost({required this.classId, required this.errorCode, this.message});
}

/// Phát sự kiện "mất quyền vào lớp" cho toàn app, để màn lớp đang mở (hub và mọi màn con)
/// cùng thoát về danh sách thay vì mỗi màn tự báo lỗi riêng.
class ClassAccessMonitor {
  ClassAccessMonitor._();

  static final ClassAccessMonitor instance = ClassAccessMonitor._();

  final StreamController<ClassAccessLost> _controller = StreamController.broadcast();

  Stream<ClassAccessLost> get stream => _controller.stream;

  Stream<ClassAccessLost> forClass(String classId) =>
      _controller.stream.where((e) => e.classId == classId);

  void notify(ClassAccessLost event) => _controller.add(event);
}
