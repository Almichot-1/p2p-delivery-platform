import 'package:equatable/equatable.dart';
import '../data/models/match_model.dart';

abstract class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object?> get props => [];
}

class MatchInitial extends MatchState {}

class MatchLoading extends MatchState {}

class MatchesLoaded extends MatchState {
  final List<MatchModel> matches;

  const MatchesLoaded(this.matches);

  @override
  List<Object> get props => [matches];
}

class MatchDetailsLoaded extends MatchState {
  final MatchModel match;

  const MatchDetailsLoaded(this.match);

  @override
  List<Object> get props => [match];
}

class MatchActionSuccess extends MatchState {
  final String message;

  const MatchActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MatchError extends MatchState {
  final String message;

  const MatchError(this.message);

  @override
  List<Object> get props => [message];
}
