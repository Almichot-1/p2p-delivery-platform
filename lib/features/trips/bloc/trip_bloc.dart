import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/trip_model.dart';
import '../data/repositories/trip_repository.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(const TripInitial()) {
    on<TripsLoadRequested>(_onTripsLoadRequested);
    on<MyTripsLoadRequested>(_onMyTripsLoadRequested);
    on<TripDetailsRequested>(_onTripDetailsRequested);
    on<TripCreateRequested>(_onTripCreateRequested);
    on<TripUpdateRequested>(_onTripUpdateRequested);
    on<TripCancelRequested>(_onTripCancelRequested);

    on<_TripsStreamUpdated>(_onTripsStreamUpdated);
    on<_TripDetailsStreamUpdated>(_onTripDetailsStreamUpdated);
    on<_TripsStreamFailed>(_onTripsStreamFailed);
  }

  final TripRepository _tripRepository;

  StreamSubscription<List<TripModel>>? _tripsSub;
  StreamSubscription<List<TripModel>>? _myTripsSub;
  StreamSubscription<TripModel?>? _detailsSub;

  Future<void> _onTripsLoadRequested(
    TripsLoadRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    await _myTripsSub?.cancel();
    _myTripsSub = null;

    await _detailsSub?.cancel();
    _detailsSub = null;

    await _tripsSub?.cancel();
    _tripsSub = _tripRepository
        .getActiveTrips(
          destinationCountry: event.destinationCountry,
          afterDate: event.afterDate,
        )
        .listen(
      (trips) => add(_TripsStreamUpdated(trips)),
      onError: (e) => add(_TripsStreamFailed(e.toString())),
    );
  }

  Future<void> _onMyTripsLoadRequested(
    MyTripsLoadRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    await _tripsSub?.cancel();
    _tripsSub = null;

    await _detailsSub?.cancel();
    _detailsSub = null;

    await _myTripsSub?.cancel();
    _myTripsSub = _tripRepository.getTripsByTraveler(event.travelerId).listen(
      (trips) => add(_TripsStreamUpdated(trips)),
      onError: (e) => add(_TripsStreamFailed(e.toString())),
    );
  }

  Future<void> _onTripDetailsRequested(
    TripDetailsRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    await _tripsSub?.cancel();
    _tripsSub = null;

    await _myTripsSub?.cancel();
    _myTripsSub = null;

    await _detailsSub?.cancel();
    _detailsSub = _tripRepository.getTripById(event.tripId).listen(
      (trip) => add(_TripDetailsStreamUpdated(trip)),
      onError: (e) => add(_TripsStreamFailed(e.toString())),
    );
  }

  Future<void> _onTripCreateRequested(
    TripCreateRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripCreating());
    try {
      final id = await _tripRepository.createTrip(event.trip);
      emit(TripCreated(id));
    } catch (e) {
      emit(TripError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onTripUpdateRequested(
    TripUpdateRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripCreating());
    try {
      await _tripRepository.updateTrip(event.trip);
      emit(const TripUpdated());
    } catch (e) {
      emit(TripError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onTripCancelRequested(
    TripCancelRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripCreating());
    try {
      await _tripRepository.cancelTrip(event.tripId);
      emit(const TripCancelled());
    } catch (e) {
      emit(TripError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onTripsStreamUpdated(_TripsStreamUpdated event, Emitter<TripState> emit) {
    emit(TripsLoaded(event.trips));
  }

  void _onTripDetailsStreamUpdated(
    _TripDetailsStreamUpdated event,
    Emitter<TripState> emit,
  ) {
    final trip = event.trip;
    if (trip == null) {
      emit(const TripError('Trip not found'));
      return;
    }
    emit(TripDetailsLoaded(trip));
  }

  void _onTripsStreamFailed(_TripsStreamFailed event, Emitter<TripState> emit) {
    emit(TripError(event.message.replaceFirst('Exception: ', '')));
  }

  @override
  Future<void> close() async {
    await _tripsSub?.cancel();
    await _myTripsSub?.cancel();
    await _detailsSub?.cancel();
    return super.close();
  }
}

class _TripsStreamUpdated extends TripEvent {
  const _TripsStreamUpdated(this.trips);

  final List<TripModel> trips;

  @override
  List<Object?> get props => <Object?>[trips];
}

class _TripDetailsStreamUpdated extends TripEvent {
  const _TripDetailsStreamUpdated(this.trip);

  final TripModel? trip;

  @override
  List<Object?> get props => <Object?>[trip];
}

class _TripsStreamFailed extends TripEvent {
  const _TripsStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
