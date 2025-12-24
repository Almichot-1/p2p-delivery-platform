import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {
  final String userId;

  const NotificationsLoadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  final String notificationId;

  const NotificationMarkAsReadRequested(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationsMarkAllAsReadRequested extends NotificationEvent {
  final String userId;

  const NotificationsMarkAllAsReadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class NotificationDeleteRequested extends NotificationEvent {
  final String notificationId;

  const NotificationDeleteRequested(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationsClearAllRequested extends NotificationEvent {
  final String userId;

  const NotificationsClearAllRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class NotificationReceived extends NotificationEvent {
  final Map<String, dynamic> data;

  const NotificationReceived(this.data);

  @override
  List<Object> get props => [data];
}
