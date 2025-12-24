import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/request_repository.dart';
import 'request_event.dart';
import 'request_state.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestRepository _requestRepository;
  StreamSubscription? _requestsSubscription;

  RequestBloc(this._requestRepository) : super(RequestInitial()) {
    on<RequestsLoadRequested>(_onRequestsLoadRequested);
    on<MyRequestsLoadRequested>(_onMyRequestsLoadRequested);
    on<RequestDetailsRequested>(_onRequestDetailsRequested);
    on<RequestCreateRequested>(_onRequestCreateRequested);
    on<RequestUpdateRequested>(_onRequestUpdateRequested);
    on<RequestCancelRequested>(_onRequestCancelRequested);
    on<RequestSearchRequested>(_onRequestSearchRequested);
  }

  Future<void> _onRequestsLoadRequested(
    RequestsLoadRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());

    await _requestsSubscription?.cancel();
    _requestsSubscription = _requestRepository
        .getActiveRequests(
          deliveryCity: event.deliveryCity,
          category: event.category,
        )
        .listen(
          (requests) => emit(RequestsLoaded(requests)),
          onError: (error) => emit(RequestError(error.toString())),
        );
  }

  Future<void> _onMyRequestsLoadRequested(
    MyRequestsLoadRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());
    // Implementation similar to trips
  }

  Future<void> _onRequestDetailsRequested(
    RequestDetailsRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());

    await _requestsSubscription?.cancel();
    _requestsSubscription =
        _requestRepository.getRequestById(event.requestId).listen(
      (request) {
        if (request != null) {
          emit(RequestDetailsLoaded(request));
        } else {
          emit(const RequestError('Request not found'));
        }
      },
      onError: (error) => emit(RequestError(error.toString())),
    );
  }

  Future<void> _onRequestCreateRequested(
    RequestCreateRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());

    try {
      final requestId = await _requestRepository.createRequest(
        event.request,
        images: event.images,
      );
      emit(RequestCreated(requestId));
    } catch (e) {
      emit(RequestError(e.toString()));
    }
  }

  Future<void> _onRequestUpdateRequested(
    RequestUpdateRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());

    try {
      await _requestRepository.updateRequest(event.request);
      emit(RequestUpdated());
    } catch (e) {
      emit(RequestError(e.toString()));
    }
  }

  Future<void> _onRequestCancelRequested(
    RequestCancelRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());

    try {
      await _requestRepository.cancelRequest(event.requestId);
      emit(RequestCancelled());
    } catch (e) {
      emit(RequestError(e.toString()));
    }
  }

  Future<void> _onRequestSearchRequested(
    RequestSearchRequested event,
    Emitter<RequestState> emit,
  ) async {
    emit(RequestLoading());

    try {
      final requests = await _requestRepository.searchRequests(
        deliveryCity: event.deliveryCity,
        maxWeight: event.maxWeight,
        category: event.category,
      );
      emit(RequestSearchResults(requests));
    } catch (e) {
      emit(RequestError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _requestsSubscription?.cancel();
    return super.close();
  }
}
