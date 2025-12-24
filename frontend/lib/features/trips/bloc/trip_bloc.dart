import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/trip_repository.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _tripRepository;
  StreamSubscription? _tripsSubscription;

  TripBloc(this._tripRepository) : super(TripInitial()) {
    on<TripsLoadRequested>(_onTripsLoadRequested);
    on<MyTripsLoadRequested>(_onMyTripsLoadRequested);
    on<TripDetailsRequested>(_onTripDetailsRequested);
    on<TripCreateRequested>(_onTripCreateRequested);
    on<TripUpdateRequested>(_onTripUpdateRequested);
    on<TripCancelRequested>(_onTripCancelRequested);
    on<TripSearchRequested>(_onTripSearchRequested);
  }

  Future<void> _onTripsLoadRequested(
    TripsLoadRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    await _tripsSubscription?.cancel();
    _tripsSubscription = _tripRepository
        .getActiveTrips(
          destinationCity: event.destinationCity,
          afterDate: event.afterDate,
        )
        .listen(
          (trips) => emit(TripsLoaded(trips)),
          onError: (error) => emit(TripError(error.toString())),
        );
  }

  Future<void> _onMyTripsLoadRequested(
    MyTripsLoadRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    // Get current user ID from auth
    // For now, we'll assume it's passed or available
    // final userId = _authRepository.currentUserId;

    await _tripsSubscription?.cancel();
    // _tripsSubscription = _tripRepository.getTripsByTraveler(userId).listen(...)
  }

  Future<void> _onTripDetailsRequested(
    TripDetailsRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    await _tripsSubscription?.cancel();
    _tripsSubscription = _tripRepository.getTripById(event.tripId).listen(
      (trip) {
        if (trip != null) {
          emit(TripDetailsLoaded(trip));
        } else {
          emit(const TripError('Trip not found'));
        }
      },
      onError: (error) => emit(TripError(error.toString())),
    );
  }

  Future<void> _onTripCreateRequested(
    TripCreateRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    try {
      final tripId = await _tripRepository.createTrip(event.trip);
      emit(TripCreated(tripId));
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _onTripUpdateRequested(
    TripUpdateRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    try {
      await _tripRepository.updateTrip(event.trip);
      emit(TripUpdated());
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _onTripCancelRequested(
    TripCancelRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    try {
      await _tripRepository.cancelTrip(event.tripId);
      emit(TripCancelled());
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _onTripSearchRequested(
    TripSearchRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    try {
      final trips = await _tripRepository.searchTrips(
        destinationCity: event.destinationCity,
        departureDate: event.departureDate,
        minCapacity: event.minCapacity,
      );
      emit(TripSearchResults(trips));
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}
