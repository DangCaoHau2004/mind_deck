import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';
import 'notification_list_event.dart';
import 'notification_list_state.dart';

class NotificationListBloc extends Bloc<NotificationListEvent, NotificationListState> {
  final NotificationRepository notificationRepository;

  NotificationListBloc({required this.notificationRepository}) : super(NotificationListInitial()) {
    on<NotificationListLoadStarted>(_onLoadStarted);
    on<NotificationListLoadMore>(_onLoadMore);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onLoadStarted(
    NotificationListLoadStarted event,
    Emitter<NotificationListState> emit,
  ) async {
    emit(NotificationListLoading());
    try {
      final response = await notificationRepository.getNotifications(page: 1, limit: 20);
      if (response.success) {
        emit(
          NotificationListSuccess(
            notifications: response.data,
            hasReachedMax:
                (response.meta?['totalPages'] as int? ?? 1) == 1 || (response.data.length < 20),
            currentPage: 1,
          ),
        );
      } else {
        emit(NotificationListFailure(error: response.message));
      }
    } catch (e) {
      emit(NotificationListFailure(error: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    NotificationListLoadMore event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationListSuccess && !currentState.hasReachedMax) {
      try {
        final nextPage = currentState.currentPage + 1;
        final response = await notificationRepository.getNotifications(page: nextPage, limit: 20);
        if (response.success) {
          final isMax =
              (response.meta?['totalPages'] as int? ?? nextPage) == nextPage ||
              response.data.isEmpty;
          emit(
            currentState.copyWith(
              notifications: List.of(currentState.notifications)..addAll(response.data),
              hasReachedMax: isMax,
              currentPage: nextPage,
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationListSuccess) {
      try {
        // Optimistic UI update
        final updatedList = currentState.notifications.map((n) {
          if (n.id == event.notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        emit(currentState.copyWith(notifications: updatedList));

        await notificationRepository.markAsRead(event.notificationId);
      } catch (_) {}
    }
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationListSuccess) {
      try {
        // Optimistic UI update
        final updatedList = currentState.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();

        emit(currentState.copyWith(notifications: updatedList));

        await notificationRepository.markAllAsRead();
      } catch (_) {}
    }
  }
}
