import 'package:equatable/equatable.dart';

import '../data/models/match_model.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class MatchesLoadRequested extends MatchEvent {
  const MatchesLoadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => <Object?>[userId];
}

class MatchDetailsRequested extends MatchEvent {
  const MatchDetailsRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => <Object?>[matchId];
}

class MatchAcceptRequested extends MatchEvent {
  const MatchAcceptRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => <Object?>[matchId];
}

class MatchRejectRequested extends MatchEvent {
  const MatchRejectRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => <Object?>[matchId];
}

class MatchConfirmRequested extends MatchEvent {
  const MatchConfirmRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => <Object?>[matchId];
}

class MatchStatusUpdateRequested extends MatchEvent {
  const MatchStatusUpdateRequested(this.matchId, this.status);

  final String matchId;
  final MatchStatus status;

  @override
  List<Object?> get props => <Object?>[matchId, status];
}

class MatchCancelRequested extends MatchEvent {
  const MatchCancelRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => <Object?>[matchId];
}

class MatchAgreedPriceUpdateRequested extends MatchEvent {
  const MatchAgreedPriceUpdateRequested(this.matchId, this.price);

  final String matchId;
  final double price;

  @override
  List<Object?> get props => <Object?>[matchId, price];
}

class MatchCreateRequested extends MatchEvent {
  const MatchCreateRequested({
    required this.tripId,
    required this.requestId,
    required this.travelerId,
    required this.travelerName,
    required this.travelerPhoto,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhoto,
    required this.itemTitle,
    required this.route,
    required this.tripDate,
  });

  final String tripId;
  final String requestId;

  final String travelerId;
  final String travelerName;
  final String? travelerPhoto;

  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;

  final String itemTitle;
  final String route;
  final DateTime tripDate;

  @override
  List<Object?> get props => <Object?>[
        tripId,
        requestId,
        travelerId,
        travelerName,
        travelerPhoto,
        requesterId,
        requesterName,
        requesterPhoto,
        itemTitle,
        route,
        tripDate,
      ];
}
