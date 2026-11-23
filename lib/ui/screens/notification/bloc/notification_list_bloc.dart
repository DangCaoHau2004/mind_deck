import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';
import 'notification_list_event.dart';
import 'notification_list_state.dart';

class NotificationListBloc extends Bloc<NotificationListEvent, NotificationListState> {
  static const int _pageSize = 20;

  final NotificationRepository notificationRepository;
  bool _loadingMore = false;

  NotificationListBloc({required this.notificationRepository}) : super(NotificationListInitial()) {
    on<NotificationListLoadStarted>(_onLoadStarted);
    on<NotificationListLoadMore>(_onLoadMore);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDeleted>(_onDeleted);
    on<NotificationDeleteAllRead>(_onDeleteAllRead);
  }

  String _messageOf(Object e, String fallback) {
    if (e is Failure && e.message.isNotEmpty) return e.message;
    return fallback;
  }

  Future<void> _onLoadStarted(
    NotificationListLoadStarted event,
    Emitter<NotificationListState> emit,
  ) async {
    emit(NotificationListLoading());
    try {
      final response = await notificationRepository.getNotifications(offset: 0, limit: _pageSize);
      if (response.success) {
        final total = (response.meta?['total'] as num?)?.toInt() ?? response.data.length;
        emit(
          NotificationListSuccess(
            notifications: response.data,
            hasReachedMax: response.data.length >= total || response.data.length < _pageSize,
            total: total,
            unreadCount: (response.meta?['unreadCount'] as num?)?.toInt() ?? 0,
          ),
        );
      } else {
        emit(NotificationListFailure(error: response.message));
      }
    } catch (e) {
      emit(NotificationListFailure(error: _messageOf(e, 'Không thể tải thông báo')));
    }
  }

  Future<void> _onLoadMore(
    NotificationListLoadMore event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationListSuccess || currentState.hasReachedMax || _loadingMore) {
      return;
    }
    _loadingMore = true;
    try {
      final response = await notificationRepository.getNotifications(
        offset: currentState.notifications.length,
        limit: _pageSize,
      );
      if (response.success) {
        final merged = List.of(currentState.notifications);
        final known = merged.map((n) => n.id).toSet();
        merged.addAll(response.data.where((n) => !known.contains(n.id)));
        final total = (response.meta?['total'] as num?)?.toInt() ?? currentState.total;
        emit(
          currentState.copyWith(
            notifications: merged,
            total: total,
            hasReachedMax: response.data.isEmpty || merged.length >= total,
          ),
        );
      }
    } catch (_) {
      // Lỗi tải thêm: giữ nguyên danh sách, lần cuộn sau sẽ thử lại.
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationListSuccess) return;
    final target = currentState.notifications.where((n) => n.id == event.notificationId);
    if (target.isEmpty || target.first.isRead) return;

    // Cập nhật giao diện ngay, lỗi mạng bỏ qua (lần tải sau sẽ đồng bộ).
    emit(
      currentState.copyWith(
        notifications: currentState.notifications
            .map((n) => n.id == event.notificationId ? n.copyWith(isRead: true) : n)
            .toList(),
        unreadCount: currentState.unreadCount > 0 ? currentState.unreadCount - 1 : 0,
      ),
    );
    try {
      await notificationRepository.markAsRead(event.notificationId);
    } catch (_) {}
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationListSuccess) return;
    emit(
      currentState.copyWith(
        notifications: currentState.notifications.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      ),
    );
    try {
      await notificationRepository.markAllAsRead();
    } catch (_) {}
  }

  Future<void> _onDeleted(NotificationDeleted event, Emitter<NotificationListState> emit) async {
    final currentState = state;
    if (currentState is! NotificationListSuccess) return;
    final target = currentState.notifications.where((n) => n.id == event.notificationId);
    if (target.isEmpty) return;
    final removed = target.first;

    emit(
      currentState.copyWith(
        notifications: currentState.notifications
            .where((n) => n.id != event.notificationId)
            .toList(),
        total: currentState.total > 0 ? currentState.total - 1 : 0,
        unreadCount: !removed.isRead && currentState.unreadCount > 0
            ? currentState.unreadCount - 1
            : null,
      ),
    );
    try {
      await notificationRepository.deleteNotification(event.notificationId);
    } on Failure catch (f) {
      // 404: đã bị xóa ở nơi khác nên coi như thành công; lỗi khác thì hoàn tác.
      if (f.errorCode == 'NOTIFICATION_NOT_FOUND') return;
      emit(
        currentState.copyWith(
          notice: _messageOf(f, 'Không thể xóa thông báo'),
          noticeId: currentState.noticeId + 1,
        ),
      );
    } catch (_) {
      emit(
        currentState.copyWith(
          notice: 'Không thể xóa thông báo',
          noticeId: currentState.noticeId + 1,
        ),
      );
    }
  }

  Future<void> _onDeleteAllRead(
    NotificationDeleteAllRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationListSuccess) return;
    try {
      final deleted = await notificationRepository.deleteAllRead();
      // Tải lại để danh sách, tổng và số chưa đọc khớp server.
      final response = await notificationRepository.getNotifications(offset: 0, limit: _pageSize);
      final total = (response.meta?['total'] as num?)?.toInt() ?? response.data.length;
      emit(
        NotificationListSuccess(
          notifications: response.data,
          hasReachedMax: response.data.length >= total || response.data.length < _pageSize,
          total: total,
          unreadCount: (response.meta?['unreadCount'] as num?)?.toInt() ?? 0,
          notice: deleted > 0
              ? 'Đã xóa $deleted thông báo đã đọc'
              : 'Không có thông báo đã đọc để xóa',
          noticeId: currentState.noticeId + 1,
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          notice: _messageOf(e, 'Không thể xóa thông báo đã đọc'),
          noticeId: currentState.noticeId + 1,
        ),
      );
    }
  }
}
