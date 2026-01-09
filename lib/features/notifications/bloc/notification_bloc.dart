import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._repository) : super(const NotificationInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkAsReadRequested>(_onMarkAsRead);
    on<NotificationMarkAllAsReadRequested>(_onMarkAllAsRead);
    on<NotificationDeleteRequested>(_onDelete);
    on<NotificationDeleteAllRequested>(_onDeleteAll);
  }

  final NotificationRepository _repository;
  StreamSubscription<List<NotificationModel>>? _subscription;

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    await _subscription?.cancel();

    await emit.forEach(
      _repository.getNotifications(event.userId),
      onData: (notifications) => NotificationsLoaded(notifications),
      onError: (error, _) => NotificationError(error.toString()),
    );
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notificationId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead(event.userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onDelete(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.notificationId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onDeleteAll(
    NotificationDeleteAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.deleteAllNotifications(event.userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
