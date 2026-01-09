import 'package:equatable/equatable.dart';

import '../data/models/match_model.dart';

sealed class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object?> get props => const <Object?>[];
}

class MatchInitial extends MatchState {
  const MatchInitial();
}

class MatchLoading extends MatchState {
  const MatchLoading();
}

class MatchesLoaded extends MatchState {
  const MatchesLoaded(this.matches);

  final List<MatchModel> matches;

  @override
  List<Object?> get props => <Object?>[matches];
}

class MatchDetailsLoaded extends MatchState {
  const MatchDetailsLoaded(this.match);

  final MatchModel match;

  @override
  List<Object?> get props => <Object?>[match];
}

class MatchActionSuccess extends MatchState {
  const MatchActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class MatchCreating extends MatchState {
  const MatchCreating();
}

class MatchCreated extends MatchState {
  const MatchCreated(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => <Object?>[matchId];
}

class MatchError extends MatchState {
  const MatchError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
