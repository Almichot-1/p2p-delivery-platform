import 'package:equatable/equatable.dart';
import '../data/models/trip_model.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class TripsLoadRequested extends TripEvent {
  final String? destinationCity;
  final DateTime? afterDate;

  const TripsLoadRequested({this.destinationCity, this.afterDate});

  @override
  List<Object?> get props => [destinationCity, afterDate];
}

class MyTripsLoadRequested extends TripEvent {}

class TripDetailsRequested extends TripEvent {
  final String tripId;

  const TripDetailsRequested(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class TripCreateRequested extends TripEvent {
  final TripModel trip;

  const TripCreateRequested(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripUpdateRequested extends TripEvent {
  final TripModel trip;

  const TripUpdateRequested(this.trip);

  @override
  List<Object> get props => [trip];
}

class TripCancelRequested extends TripEvent {
  final String tripId;

  const TripCancelRequested(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class TripSearchRequested extends TripEvent {
  final String destinationCity;
  final DateTime? departureDate;
  final double? minCapacity;

  const TripSearchRequested({
    required this.destinationCity,
    this.departureDate,
    this.minCapacity,
  });

  @override
  List<Object?> get props => [destinationCity, departureDate, minCapacity];
}
