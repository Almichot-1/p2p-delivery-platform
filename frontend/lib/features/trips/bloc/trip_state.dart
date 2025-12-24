import 'package:equatable/equatable.dart';
import '../data/models/trip_model.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripsLoaded extends TripState {
  final List<TripModel> trips;

  const TripsLoaded(this.trips);

  @override
  List<Object> get props => [trips];
}

class TripDetailsLoaded extends TripState {
  final TripModel trip;

  const TripDetailsLoaded(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripCreated extends TripState {
  final String tripId;

  const TripCreated(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class TripUpdated extends TripState {}

class TripCancelled extends TripState {}

class TripSearchResults extends TripState {
  final List<TripModel> trips;

  const TripSearchResults(this.trips);

  @override
  List<Object> get props => [trips];
}

class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object> get props => [message];
}
