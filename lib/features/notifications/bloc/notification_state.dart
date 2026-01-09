import 'package:equatable/equatable.dart';

import '../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationsLoaded extends NotificationState {
  const NotificationsLoaded(this.notifications);

  final List<NotificationModel> notifications;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  const NotificationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
