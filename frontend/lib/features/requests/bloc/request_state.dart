import 'package:equatable/equatable.dart';
import '../data/models/request_model.dart';

abstract class RequestState extends Equatable {
  const RequestState();

  @override
  List<Object?> get props => [];
}

class RequestInitial extends RequestState {}

class RequestLoading extends RequestState {}

class RequestsLoaded extends RequestState {
  final List<RequestModel> requests;

  const RequestsLoaded(this.requests);

  @override
  List<Object> get props => [requests];
}

class RequestDetailsLoaded extends RequestState {
  final RequestModel request;

  const RequestDetailsLoaded(this.request);

  @override
  List<Object> get props => [request];
}

class RequestCreated extends RequestState {
  final String requestId;

  const RequestCreated(this.requestId);

  @override
  List<Object> get props => [requestId];
}

class RequestUpdated extends RequestState {}

class RequestCancelled extends RequestState {}

class RequestSearchResults extends RequestState {
  final List<RequestModel> requests;

  const RequestSearchResults(this.requests);

  @override
  List<Object> get props => [requests];
}

class RequestError extends RequestState {
  final String message;

  const RequestError(this.message);

  @override
  List<Object> get props => [message];
}
