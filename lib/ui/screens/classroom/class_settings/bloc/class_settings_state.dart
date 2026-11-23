import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_settings_model.dart';

enum ClassSettingsStatus { initial, loading, success, failure }

class ClassSettingsState extends Equatable {
  final ClassSettingsStatus status;
  final String? errorMessage;

  final ClassSettings settings;
  final MyNotifySettings mySettings;

  /// Đã đổi cài đặt (màn hub cần tải lại `permissions`).
  final bool hasChanges;

  /// Thông báo lỗi một lần cho các công tắc; `noticeId` tăng mỗi lần.
  final String? notice;
  final int noticeId;

  const ClassSettingsState({
    this.status = ClassSettingsStatus.initial,
    this.errorMessage,
    this.settings = const ClassSettings(),
    this.mySettings = const MyNotifySettings(),
    this.hasChanges = false,
    this.notice,
    this.noticeId = 0,
  });

  ClassSettingsState copyWith({
    ClassSettingsStatus? status,
    String? errorMessage,
    ClassSettings? settings,
    MyNotifySettings? mySettings,
    bool? hasChanges,
    String? notice,
  }) {
    return ClassSettingsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      settings: settings ?? this.settings,
      mySettings: mySettings ?? this.mySettings,
      hasChanges: hasChanges ?? this.hasChanges,
      notice: notice,
      noticeId: notice != null ? noticeId + 1 : noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    settings,
    mySettings,
    hasChanges,
    notice,
    noticeId,
  ];
}
