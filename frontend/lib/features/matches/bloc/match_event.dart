import 'package:equatable/equatable.dart';
import '../data/models/match_model.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => [];
}

class MatchesLoadRequested extends MatchEvent {
  final String userId;

  const MatchesLoadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class MatchDetailsRequested extends MatchEvent {
  final String matchId;

  const MatchDetailsRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchAcceptRequested extends MatchEvent {
  final String matchId;

  const MatchAcceptRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchRejectRequested extends MatchEvent {
  final String matchId;

  const MatchRejectRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchConfirmRequested extends MatchEvent {
  final String matchId;

  const MatchConfirmRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchStatusUpdateRequested extends MatchEvent {
  final String matchId;
  final MatchStatus status;

  const MatchStatusUpdateRequested(this.matchId, this.status);

  @override
  List<Object> get props => [matchId, status];
}

class MatchCancelRequested extends MatchEvent {
  final String matchId;

  const MatchCancelRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}
