import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/user_notification_settings_model.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationSettingsLoadStarted extends NotificationSettingsEvent {
  const NotificationSettingsLoadStarted();
}

/// Đổi một phần cấu hình: `changes` là body PUT (chỉ các trường đổi), `optimistic` là cấu hình hiển thị ngay.
class NotificationSettingsChanged extends NotificationSettingsEvent {
  final Map<String, dynamic> changes;
  final UserNotificationSettingsModel optimistic;

  const NotificationSettingsChanged({required this.changes, required this.optimistic});

  @override
  List<Object?> get props => [changes];
}

abstract class NotificationSettingsState extends Equatable {
  const NotificationSettingsState();

  @override
  List<Object?> get props => [];
}

class NotificationSettingsInitial extends NotificationSettingsState {}

class NotificationSettingsLoading extends NotificationSettingsState {}

class NotificationSettingsLoaded extends NotificationSettingsState {
  final UserNotificationSettingsModel settings;

  /// Thông báo một lần dùng (toast); phân biệt các lần bằng `noticeId`.
  final String? notice;
  final int noticeId;

  const NotificationSettingsLoaded({required this.settings, this.notice, this.noticeId = 0});

  @override
  List<Object?> get props => [settings.toJson().toString(), notice, noticeId];
}

class NotificationSettingsFailure extends NotificationSettingsState {
  final String error;

  const NotificationSettingsFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class NotificationSettingsBloc extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final NotificationRepository notificationRepository;
  int _noticeId = 0;

  NotificationSettingsBloc({required this.notificationRepository})
    : super(NotificationSettingsInitial()) {
    on<NotificationSettingsLoadStarted>(_onLoad);
    // Tuần tự để hai lần đổi liên tiếp không ghi đè nhau.
    on<NotificationSettingsChanged>(_onChanged, transformer: sequential());
  }

  String _messageOf(Object e, String fallback) {
    if (e is Failure && e.message.isNotEmpty) return e.message;
    return fallback;
  }

  Future<void> _onLoad(
    NotificationSettingsLoadStarted event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(NotificationSettingsLoading());
    try {
      final response = await notificationRepository.getNotificationSettings();
      final data = response.data;
      if (response.success && data != null) {
        emit(NotificationSettingsLoaded(settings: data));
      } else {
        emit(NotificationSettingsFailure(response.message ?? 'Không thể tải cài đặt thông báo'));
      }
    } catch (e) {
      emit(NotificationSettingsFailure(_messageOf(e, 'Không thể tải cài đặt thông báo')));
    }
  }

  Future<void> _onChanged(
    NotificationSettingsChanged event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationSettingsLoaded) return;
    final previous = current.settings;

    emit(NotificationSettingsLoaded(settings: event.optimistic, noticeId: current.noticeId));
    try {
      final response = await notificationRepository.updateNotificationSettings(event.changes);
      final data = response.data;
      if (response.success && data != null) {
        emit(NotificationSettingsLoaded(settings: data, noticeId: current.noticeId));
      } else {
        _rollback(emit, previous, response.message ?? 'Không thể lưu cài đặt');
      }
    } catch (e) {
      _rollback(emit, previous, _messageOf(e, 'Không thể lưu cài đặt'));
    }
  }

  void _rollback(
    Emitter<NotificationSettingsState> emit,
    UserNotificationSettingsModel previous,
    String message,
  ) {
    emit(NotificationSettingsLoaded(settings: previous, notice: message, noticeId: ++_noticeId));
  }
}
