import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';

abstract class ClassMaterialsEvent extends Equatable {
  const ClassMaterialsEvent();

  @override
  List<Object?> get props => [];
}

class ClassMaterialsLoaded extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsLoaded(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassMaterialsLoadMore extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsLoadMore(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassMaterialsSearchChanged extends ClassMaterialsEvent {
  final String classId;
  final String query;

  const ClassMaterialsSearchChanged(this.classId, this.query);

  @override
  List<Object?> get props => [classId, query];
}

class ClassMaterialsRefreshed extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsRefreshed(this.classId);

  @override
  List<Object?> get props => [classId];
}

/// Thêm học liệu từ thư viện cá nhân. `deckIds`/`folderIds` là id NGUỒN.
/// Có học liệu trùng mà chưa gửi `duplicatePolicy` -> BE trả 409, bloc phát `pendingAdd`
/// để màn hình hỏi người dùng rồi gửi lại cùng body kèm `duplicatePolicy`.
class ClassMaterialAdded extends ClassMaterialsEvent {
  final String classId;
  final List<String> folderIds;
  final List<String> deckIds;

  /// skip | add_anyway | merge
  final String? duplicatePolicy;

  const ClassMaterialAdded({
    required this.classId,
    required this.folderIds,
    required this.deckIds,
    this.duplicatePolicy,
  });

  @override
  List<Object?> get props => [classId, folderIds, deckIds, duplicatePolicy];
}

/// Người dùng đóng hộp thoại hỏi xử lý trùng mà không chọn gì.
class ClassMaterialDuplicateDismissed extends ClassMaterialsEvent {}

/// Sao chép một học liệu của lớp (id BẢN SAO) về thư viện cá nhân.
class ClassMaterialCloned extends ClassMaterialsEvent {
  final String classId;
  final ClassMaterialItem item;

  const ClassMaterialCloned({required this.classId, required this.item});

  @override
  List<Object?> get props => [classId, item];
}

class ClassMaterialsSelectionModeToggled extends ClassMaterialsEvent {
  final bool? isSelectionMode;
  const ClassMaterialsSelectionModeToggled([this.isSelectionMode]);
  @override
  List<Object?> get props => [isSelectionMode];
}

class ClassMaterialSelectionToggled extends ClassMaterialsEvent {
  final String id;
  const ClassMaterialSelectionToggled(this.id);
  @override
  List<Object?> get props => [id];
}

class ClassMaterialsSelectionCleared extends ClassMaterialsEvent {}

/// Gỡ các mục đang chọn khỏi lớp (xóa mềm, gỡ folder = gỡ luôn mọi deck con).
class ClassMaterialsDeleted extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsDeleted(this.classId);

  @override
  List<Object?> get props => [classId];
}
