import 'dart:io';

import 'package:equatable/equatable.dart';

import '../data/models/request_model.dart';

abstract class RequestEvent extends Equatable {
  const RequestEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class RequestsLoadRequested extends RequestEvent {
  const RequestsLoadRequested({this.deliveryCity, this.category});

  final String? deliveryCity;
  final RequestCategory? category;

  @override
  List<Object?> get props => <Object?>[deliveryCity, category];
}

class MyRequestsLoadRequested extends RequestEvent {
  const MyRequestsLoadRequested(this.requesterId);

  final String requesterId;

  @override
  List<Object?> get props => <Object?>[requesterId];
}

class RequestDetailsRequested extends RequestEvent {
  const RequestDetailsRequested(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}

class RequestCreateRequested extends RequestEvent {
  const RequestCreateRequested(this.request, this.images);

  final RequestModel request;
  final List<File> images;

  @override
  List<Object?> get props => <Object?>[request, images];
}

class RequestUpdateRequested extends RequestEvent {
  const RequestUpdateRequested(this.request);

  final RequestModel request;

  @override
  List<Object?> get props => <Object?>[request];
}

class RequestCancelRequested extends RequestEvent {
  const RequestCancelRequested(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}
