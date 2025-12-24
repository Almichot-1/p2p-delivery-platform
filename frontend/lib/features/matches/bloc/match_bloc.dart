import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/match_repository.dart';
import 'match_event.dart';
import 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchRepository _matchRepository;
  StreamSubscription? _matchesSubscription;

  MatchBloc(this._matchRepository) : super(MatchInitial()) {
    on<MatchesLoadRequested>(_onMatchesLoadRequested);
    on<MatchDetailsRequested>(_onMatchDetailsRequested);
    on<MatchAcceptRequested>(_onMatchAcceptRequested);
    on<MatchRejectRequested>(_onMatchRejectRequested);
    on<MatchConfirmRequested>(_onMatchConfirmRequested);
    on<MatchStatusUpdateRequested>(_onMatchStatusUpdateRequested);
    on<MatchCancelRequested>(_onMatchCancelRequested);
  }

  Future<void> _onMatchesLoadRequested(
    MatchesLoadRequested event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    await _matchesSubscription?.cancel();
    _matchesSubscription = _matchRepository.getUserMatches(event.userId).listen(
          (matches) => emit(MatchesLoaded(matches)),
          onError: (error) => emit(MatchError(error.toString())),
        );
  }

  Future<void> _onMatchDetailsRequested(
    MatchDetailsRequested event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    await _matchesSubscription?.cancel();
    _matchesSubscription = _matchRepository.getMatchById(event.matchId).listen(
      (match) {
        if (match != null) {
          emit(MatchDetailsLoaded(match));
        } else {
          emit(const MatchError('Match not found'));
        }
      },
      onError: (error) => emit(MatchError(error.toString())),
    );
  }

  Future<void> _onMatchAcceptRequested(
    MatchAcceptRequested event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchRepository.acceptMatch(event.matchId);
      emit(const MatchActionSuccess('Match accepted'));
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> _onMatchRejectRequested(
    MatchRejectRequested event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchRepository.rejectMatch(event.matchId);
      emit(const MatchActionSuccess('Match rejected'));
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> _onMatchConfirmRequested(
    MatchConfirmRequested event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchRepository.confirmMatch(event.matchId);
      emit(const MatchActionSuccess('Match confirmed'));
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> _onMatchStatusUpdateRequested(
    MatchStatusUpdateRequested event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchRepository.updateMatchStatus(event.matchId, event.status);
      emit(const MatchActionSuccess('Status updated'));
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> _onMatchCancelRequested(
    MatchCancelRequested event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchRepository.cancelMatch(event.matchId);
      emit(const MatchActionSuccess('Match cancelled'));
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _matchesSubscription?.cancel();
    return super.close();
  }
}
