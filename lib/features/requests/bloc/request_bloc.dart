import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/request_model.dart';
import '../data/repositories/request_repository.dart';
import 'request_event.dart';
import 'request_state.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  RequestBloc({required RequestRepository requestRepository})
      : _requestRepository = requestRepository,
        super(const RequestInitial()) {
    on<RequestsLoadRequested>(_onRequestsLoadRequested);
    on<MyRequestsLoadRequested>(_onMyRequestsLoadRequested);
    on<RequestDetailsRequested>(_onRequestDetailsRequested);
    on<RequestCreateRequested>(_onRequestCreateRequested);
    on<RequestUpdateRequested>(_onRequestUpdateRequested);
    on<RequestCancelRequested>(_onRequestCancelRequested);

    on<_RequestsStreamUpdated>(_onRequestsStreamUpdated);
    on<_RequestDetailsStreamUpdated>(_onRequestDetailsStreamUpdated);
    on<_UploadProgressUpdated>(_onUploadProgressUpdated);
    on<_RequestsStreamFailed>(_onRequestsStreamFailed);
  }

  final RequestRepository _requestRepository;

  StreamSubscription<List<RequestModel>>? _requestsSub;
  StreamSubscription<List<RequestModel>>? _myRequestsSub;
  StreamSubscription<RequestModel?>? _detailsSub;
  StreamSubscription<double>? _uploadProgressSub;

  Future<void> _onRequestsLoadRequested(
    RequestsLoadRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestLoading());

    await _myRequestsSub?.cancel();
    _myRequestsSub = null;

    await _detailsSub?.cancel();
    _detailsSub = null;

    await _requestsSub?.cancel();
    _requestsSub = _requestRepository
        .getActiveRequests(
          deliveryCity: event.deliveryCity,
          category: event.category,
        )
        .listen(
          (requests) => add(_RequestsStreamUpdated(requests)),
          onError: (e) => add(_RequestsStreamFailed(e.toString())),
        );
  }

  Future<void> _onMyRequestsLoadRequested(
    MyRequestsLoadRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestLoading());

    await _requestsSub?.cancel();
    _requestsSub = null;

    await _detailsSub?.cancel();
    _detailsSub = null;

    await _myRequestsSub?.cancel();
    _myRequestsSub =
        _requestRepository.getRequestsByRequester(event.requesterId).listen(
              (requests) => add(_RequestsStreamUpdated(requests)),
              onError: (e) => add(_RequestsStreamFailed(e.toString())),
            );
  }

  Future<void> _onRequestDetailsRequested(
    RequestDetailsRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestLoading());

    await _requestsSub?.cancel();
    _requestsSub = null;

    await _myRequestsSub?.cancel();
    _myRequestsSub = null;

    await _detailsSub?.cancel();
    _detailsSub = _requestRepository.getRequestById(event.requestId).listen(
          (request) => add(_RequestDetailsStreamUpdated(request)),
          onError: (e) => add(_RequestsStreamFailed(e.toString())),
        );
  }

  Future<void> _onRequestCreateRequested(
    RequestCreateRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestCreating(uploadProgress: 0));

    await _uploadProgressSub?.cancel();
    _uploadProgressSub = _requestRepository.uploadProgressStream.listen(
      (p) => add(_UploadProgressUpdated(p)),
      onError: (_) {},
    );

    try {
      final id =
          await _requestRepository.createRequest(event.request, event.images);
      await _uploadProgressSub?.cancel();
      _uploadProgressSub = null;
      emit(RequestCreated(id));
    } catch (e) {
      await _uploadProgressSub?.cancel();
      _uploadProgressSub = null;
      emit(RequestError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRequestUpdateRequested(
    RequestUpdateRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestCreating());
    try {
      await _requestRepository.updateRequest(event.request);
      emit(const RequestUpdated());
    } catch (e) {
      emit(RequestError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRequestCancelRequested(
    RequestCancelRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(const RequestCreating());
    try {
      await _requestRepository.cancelRequest(event.requestId);
      emit(const RequestCancelled());
    } catch (e) {
      emit(RequestError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onRequestsStreamUpdated(
      _RequestsStreamUpdated event, Emitter<RequestState> emit) {
    emit(RequestsLoaded(event.requests));
  }

  void _onRequestDetailsStreamUpdated(
    _RequestDetailsStreamUpdated event,
    Emitter<RequestState> emit,
  ) {
    final request = event.request;
    if (request == null) {
      emit(const RequestError('Request not found'));
      return;
    }
    emit(RequestDetailsLoaded(request));
  }

  void _onUploadProgressUpdated(
      _UploadProgressUpdated event, Emitter<RequestState> emit) {
    if (state is RequestCreating) {
      emit(RequestCreating(uploadProgress: event.progress));
    }
  }

  void _onRequestsStreamFailed(
      _RequestsStreamFailed event, Emitter<RequestState> emit) {
    emit(RequestError(event.message.replaceFirst('Exception: ', '')));
  }

  @override
  Future<void> close() async {
    await _requestsSub?.cancel();
    await _myRequestsSub?.cancel();
    await _detailsSub?.cancel();
    await _uploadProgressSub?.cancel();
    return super.close();
  }
}

class _RequestsStreamUpdated extends RequestEvent {
  const _RequestsStreamUpdated(this.requests);

  final List<RequestModel> requests;

  @override
  List<Object?> get props => <Object?>[requests];
}

class _RequestDetailsStreamUpdated extends RequestEvent {
  const _RequestDetailsStreamUpdated(this.request);

  final RequestModel? request;

  @override
  List<Object?> get props => <Object?>[request];
}

class _UploadProgressUpdated extends RequestEvent {
  const _UploadProgressUpdated(this.progress);

  final double progress;

  @override
  List<Object?> get props => <Object?>[progress];
}

class _RequestsStreamFailed extends RequestEvent {
  const _RequestsStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
