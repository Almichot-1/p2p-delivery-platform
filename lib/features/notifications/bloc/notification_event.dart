import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {
  const NotificationsLoadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  const NotificationMarkAsReadRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllAsReadRequested extends NotificationEvent {
  const NotificationMarkAllAsReadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class NotificationDeleteRequested extends NotificationEvent {
  const NotificationDeleteRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

class NotificationDeleteAllRequested extends NotificationEvent {
  const NotificationDeleteAllRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}
