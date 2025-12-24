import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  StreamSubscription? _notificationsSubscription;

  NotificationBloc(this._notificationRepository)
      : super(NotificationInitial()) {
    on<NotificationsLoadRequested>(_onNotificationsLoadRequested);
    on<NotificationMarkAsReadRequested>(_onNotificationMarkAsReadRequested);
    on<NotificationsMarkAllAsReadRequested>(
        _onNotificationsMarkAllAsReadRequested);
    on<NotificationDeleteRequested>(_onNotificationDeleteRequested);
    on<NotificationsClearAllRequested>(_onNotificationsClearAllRequested);
    on<NotificationReceived>(_onNotificationReceived);
  }

  Future<void> _onNotificationsLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    await _notificationsSubscription?.cancel();
    _notificationsSubscription =
        _notificationRepository.getUserNotifications(event.userId).listen(
      (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      },
      onError: (error) => emit(NotificationError(error.toString())),
    );
  }

  Future<void> _onNotificationMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(event.notificationId);
      emit(NotificationMarkedAsRead());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onNotificationsMarkAllAsReadRequested(
    NotificationsMarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllAsRead(event.userId);
      emit(NotificationsMarkedAllAsRead());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onNotificationDeleteRequested(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteNotification(event.notificationId);
      emit(NotificationDeleted());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onNotificationsClearAllRequested(
    NotificationsClearAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.clearAllNotifications(event.userId);
      emit(NotificationsCleared());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    // Handle incoming notification if needed
    // For now, the stream listener handles updates
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}
