import 'package:equatable/equatable.dart';

import '../data/models/trip_model.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class TripsLoadRequested extends TripEvent {
  const TripsLoadRequested({this.destinationCountry, this.afterDate});

  final String? destinationCountry;
  final DateTime? afterDate;

  @override
  List<Object?> get props => <Object?>[destinationCountry, afterDate];
}

class MyTripsLoadRequested extends TripEvent {
  const MyTripsLoadRequested(this.travelerId);

  final String travelerId;

  @override
  List<Object?> get props => <Object?>[travelerId];
}

class TripDetailsRequested extends TripEvent {
  const TripDetailsRequested(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => <Object?>[tripId];
}

class TripCreateRequested extends TripEvent {
  const TripCreateRequested(this.trip);

  final TripModel trip;

  @override
  List<Object?> get props => <Object?>[trip];
}

class TripUpdateRequested extends TripEvent {
  const TripUpdateRequested(this.trip);

  final TripModel trip;

  @override
  List<Object?> get props => <Object?>[trip];
}

class TripCancelRequested extends TripEvent {
  const TripCancelRequested(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => <Object?>[tripId];
}
