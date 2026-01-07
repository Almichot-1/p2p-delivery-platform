import 'package:equatable/equatable.dart';

import '../data/models/request_model.dart';

abstract class RequestState extends Equatable {
  const RequestState();

  @override
  List<Object?> get props => const <Object?>[];
}

class RequestInitial extends RequestState {
  const RequestInitial();
}

class RequestLoading extends RequestState {
  const RequestLoading();
}

class RequestsLoaded extends RequestState {
  const RequestsLoaded(this.requests);

  final List<RequestModel> requests;

  @override
  List<Object?> get props => <Object?>[requests];
}

class RequestDetailsLoaded extends RequestState {
  const RequestDetailsLoaded(this.request);

  final RequestModel request;

  @override
  List<Object?> get props => <Object?>[request];
}

class RequestCreating extends RequestState {
  const RequestCreating({this.uploadProgress});

  final double? uploadProgress;

  @override
  List<Object?> get props => <Object?>[uploadProgress];
}

class RequestCreated extends RequestState {
  const RequestCreated(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}

class RequestUpdated extends RequestState {
  const RequestUpdated();
}

class RequestCancelled extends RequestState {
  const RequestCancelled();
}

class RequestError extends RequestState {
  const RequestError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
