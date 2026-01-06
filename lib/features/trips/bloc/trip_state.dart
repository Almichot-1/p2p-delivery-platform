import 'package:equatable/equatable.dart';

import '../data/models/trip_model.dart';

sealed class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => const <Object?>[];
}

class TripInitial extends TripState {
  const TripInitial();
}

class TripLoading extends TripState {
  const TripLoading();
}

class TripsLoaded extends TripState {
  const TripsLoaded(this.trips);

  final List<TripModel> trips;

  @override
  List<Object?> get props => <Object?>[trips];
}

class TripDetailsLoaded extends TripState {
  const TripDetailsLoaded(this.trip);

  final TripModel trip;

  @override
  List<Object?> get props => <Object?>[trip];
}

class TripCreating extends TripState {
  const TripCreating();
}

class TripCreated extends TripState {
  const TripCreated(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => <Object?>[tripId];
}

class TripUpdated extends TripState {
  const TripUpdated();
}

class TripCancelled extends TripState {
  const TripCancelled();
}

class TripError extends TripState {
  const TripError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
