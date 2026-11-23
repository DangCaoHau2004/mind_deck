import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_settings_model.dart';

abstract class ClassSettingsEvent extends Equatable {
  const ClassSettingsEvent();

  @override
  List<Object?> get props => [];
}

class UpdateClassRequested extends ClassSettingsEvent {
  final String classId;
  final String name;
  final String? description;
  final bool isPublic;
  final bool requireApproval;

  const UpdateClassRequested({
    required this.classId,
    required this.name,
    this.description,
    required this.isPublic,
    required this.requireApproval,
  });

  @override
  List<Object?> get props => [classId, name, description, isPublic, requireApproval];
}

/// Nạp cài đặt hiện tại (lấy từ `GET /classes/:id`).
class ClassSettingsInitialized extends ClassSettingsEvent {
  final ClassSettings settings;
  final MyNotifySettings mySettings;

  const ClassSettingsInitialized({required this.settings, required this.mySettings});

  @override
  List<Object?> get props => [settings, mySettings];
}

/// Khóa của 4 công tắc quyền cấp lớp (chỉ owner/admin).
enum ClassSettingKey { allowMemberAdd, allowMemberClone, showLeaderboard, showMemberEmails }

class ClassSettingToggled extends ClassSettingsEvent {
  final String classId;
  final ClassSettingKey key;
  final bool value;

  const ClassSettingToggled({required this.classId, required this.key, required this.value});

  @override
  List<Object?> get props => [classId, key, value];
}

/// Công tắc CẤP LỚP cho một loại thông báo (owner/admin cho phép loại nào được gửi).
class ClassNotifyToggled extends ClassSettingsEvent {
  final String classId;
  final String type;
  final bool value;

  const ClassNotifyToggled({required this.classId, required this.type, required this.value});

  @override
  List<Object?> get props => [classId, type, value];
}

/// Công tắc thông báo CỦA TÔI trong lớp. `type == null` là công tắc tổng `muted`.
class MyNotifyToggled extends ClassSettingsEvent {
  final String classId;
  final String? type;
  final bool value;

  const MyNotifyToggled({required this.classId, this.type, required this.value});

  @override
  List<Object?> get props => [classId, type, value];
}
