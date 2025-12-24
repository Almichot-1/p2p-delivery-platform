import 'dart:io';
import 'package:equatable/equatable.dart';
import '../data/models/request_model.dart';

abstract class RequestEvent extends Equatable {
  const RequestEvent();

  @override
  List<Object?> get props => [];
}

class RequestsLoadRequested extends RequestEvent {
  final String? deliveryCity;
  final ItemCategory? category;

  const RequestsLoadRequested({this.deliveryCity, this.category});

  @override
  List<Object?> get props => [deliveryCity, category];
}

class MyRequestsLoadRequested extends RequestEvent {}

class RequestDetailsRequested extends RequestEvent {
  final String requestId;

  const RequestDetailsRequested(this.requestId);

  @override
  List<Object> get props => [requestId];
}

class RequestCreateRequested extends RequestEvent {
  final RequestModel request;
  final List<File>? images;

  const RequestCreateRequested(this.request, {this.images});

  @override
  List<Object?> get props => [request, images];
}

class RequestUpdateRequested extends RequestEvent {
  final RequestModel request;

  const RequestUpdateRequested(this.request);

  @override
  List<Object> get props => [request];
}

class RequestCancelRequested extends RequestEvent {
  final String requestId;

  const RequestCancelRequested(this.requestId);

  @override
  List<Object> get props => [requestId];
}

class RequestSearchRequested extends RequestEvent {
  final String deliveryCity;
  final double? maxWeight;
  final ItemCategory? category;

  const RequestSearchRequested({
    required this.deliveryCity,
    this.maxWeight,
    this.category,
  });

  @override
  List<Object?> get props => [deliveryCity, maxWeight, category];
}
