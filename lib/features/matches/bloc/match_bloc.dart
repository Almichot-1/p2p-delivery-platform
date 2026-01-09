import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../chat/data/repositories/chat_repository.dart';
import '../../notifications/data/repositories/notification_repository.dart';
import '../data/models/match_model.dart';
import '../data/repositories/match_repository.dart';
import 'match_event.dart';
import 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  MatchBloc({
    required MatchRepository matchRepository,
    ChatRepository? chatRepository,
    NotificationRepository? notificationRepository,
  })  : _matchRepository = matchRepository,
        _chatRepository = chatRepository,
        _notificationRepository = notificationRepository,
        super(const MatchInitial()) {
    on<MatchesLoadRequested>(_onMatchesLoadRequested);
    on<MatchDetailsRequested>(_onMatchDetailsRequested);

    on<MatchAcceptRequested>(_onMatchAcceptRequested);
    on<MatchRejectRequested>(_onMatchRejectRequested);
    on<MatchConfirmRequested>(_onMatchConfirmRequested);
    on<MatchStatusUpdateRequested>(_onMatchStatusUpdateRequested);
    on<MatchCancelRequested>(_onMatchCancelRequested);
    on<MatchAgreedPriceUpdateRequested>(_onMatchAgreedPriceUpdateRequested);
    on<MatchCreateRequested>(_onMatchCreateRequested);

    on<_MatchesStreamUpdated>(_onMatchesStreamUpdated);
    on<_MatchDetailsStreamUpdated>(_onMatchDetailsStreamUpdated);
    on<_MatchStreamFailed>(_onMatchStreamFailed);
  }

  final MatchRepository _matchRepository;
  final ChatRepository? _chatRepository;
  final NotificationRepository? _notificationRepository;

  StreamSubscription<List<MatchModel>>? _matchesSub;
  StreamSubscription<MatchModel?>? _detailsSub;

  List<MatchModel> _lastMatches = const <MatchModel>[];
  MatchModel? _lastMatch;

  Future<void> _onMatchesLoadRequested(
    MatchesLoadRequested event,
    Emitter<MatchState> emit,
  ) async {
    debugPrint('###MATCH_DEBUG### _onMatchesLoadRequested: userId=${event.userId}');
    emit(const MatchLoading());

    await _detailsSub?.cancel();
    _detailsSub = null;

    await _matchesSub?.cancel();
    _matchesSub = _matchRepository.getUserMatches(event.userId).listen(
          (matches) => add(_MatchesStreamUpdated(matches)),
          onError: (e) {
            debugPrint('###MATCH_DEBUG### Stream error: $e');
            add(_MatchStreamFailed(e.toString()));
          },
        );
  }

  Future<void> _onMatchDetailsRequested(
    MatchDetailsRequested event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());

    await _matchesSub?.cancel();
    _matchesSub = null;

    await _detailsSub?.cancel();
    _detailsSub = _matchRepository.getMatchById(event.matchId).listen(
          (match) => add(_MatchDetailsStreamUpdated(match)),
          onError: (e) => add(_MatchStreamFailed(e.toString())),
        );
  }

  Future<void> _onMatchAcceptRequested(
    MatchAcceptRequested event,
    Emitter<MatchState> emit,
  ) async {
    await _action(
      emit,
      () => _matchRepository.acceptMatch(event.matchId),
      successMessage: 'Match accepted',
      matchId: event.matchId,
      systemMessage: 'Match has been accepted by the traveler',
      onSuccess: () async {
        // Notify requester that their match was accepted
        final match = _lastMatch;
        if (match != null && _notificationRepository != null) {
          await _notificationRepository!.notifyMatchAccepted(
            recipientId: match.requesterId,
            matchId: match.id,
            accepterName: match.travelerName,
            accepterPhoto: match.travelerPhoto,
          );
        }
      },
    );
  }

  Future<void> _onMatchRejectRequested(
    MatchRejectRequested event,
    Emitter<MatchState> emit,
  ) async {
    // Get match before rejection to access requester info
    final matchBefore = _lastMatch;
    
    await _action(
      emit,
      () => _matchRepository.rejectMatch(event.matchId),
      successMessage: 'Match rejected',
      onSuccess: () async {
        // Notify requester that their match was rejected
        if (matchBefore != null && _notificationRepository != null) {
          await _notificationRepository!.notifyMatchRejected(
            recipientId: matchBefore.requesterId,
            matchId: matchBefore.id,
            rejecterName: matchBefore.travelerName,
          );
        }
      },
    );
  }

  Future<void> _onMatchConfirmRequested(
    MatchConfirmRequested event,
    Emitter<MatchState> emit,
  ) async {
    await _action(
      emit,
      () => _matchRepository.confirmMatch(event.matchId),
      successMessage: 'Match confirmed',
      matchId: event.matchId,
      systemMessage: 'Match has been confirmed. You can now chat!',
    );
  }

  Future<void> _onMatchStatusUpdateRequested(
    MatchStatusUpdateRequested event,
    Emitter<MatchState> emit,
  ) async {
    final statusMessages = <MatchStatus, String>{
      MatchStatus.pickedUp: 'Item has been picked up by the traveler',
      MatchStatus.inTransit: 'Item is now in transit',
      MatchStatus.delivered: 'Item has been delivered',
      MatchStatus.completed: 'Delivery completed successfully!',
    };

    await _action(
      emit,
      () => _matchRepository.updateMatchStatus(event.matchId, event.status),
      successMessage: 'Status updated',
      matchId: event.matchId,
      systemMessage: statusMessages[event.status],
      onSuccess: () async {
        // Notify both participants about status update
        final match = _lastMatch;
        if (match != null && _notificationRepository != null) {
          // Notify requester
          await _notificationRepository!.notifyStatusUpdate(
            recipientId: match.requesterId,
            matchId: match.id,
            status: event.status.name,
            itemTitle: match.itemTitle,
          );
          // Notify traveler (if status changed by requester)
          await _notificationRepository!.notifyStatusUpdate(
            recipientId: match.travelerId,
            matchId: match.id,
            status: event.status.name,
            itemTitle: match.itemTitle,
          );
        }
      },
    );
  }

  Future<void> _onMatchCancelRequested(
    MatchCancelRequested event,
    Emitter<MatchState> emit,
  ) async {
    await _action(
      emit,
      () => _matchRepository.cancelMatch(event.matchId),
      successMessage: 'Match cancelled',
      matchId: event.matchId,
      systemMessage: 'Match has been cancelled',
    );
  }

  Future<void> _onMatchAgreedPriceUpdateRequested(
    MatchAgreedPriceUpdateRequested event,
    Emitter<MatchState> emit,
  ) async {
    await _action(
      emit,
      () => _matchRepository.updateAgreedPrice(event.matchId, event.price),
      successMessage: 'Agreed price updated',
    );
  }

  Future<void> _onMatchCreateRequested(
    MatchCreateRequested event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchCreating());

    try {
      final exists = await _matchRepository.matchExists(
        event.tripId,
        event.requestId,
      );
      if (exists) {
        emit(const MatchError('A match already exists for this trip and request'));
        return;
      }

      final id = await _matchRepository.createMatch(
        tripId: event.tripId,
        requestId: event.requestId,
        travelerId: event.travelerId,
        travelerName: event.travelerName,
        travelerPhoto: event.travelerPhoto,
        requesterId: event.requesterId,
        requesterName: event.requesterName,
        requesterPhoto: event.requesterPhoto,
        itemTitle: event.itemTitle,
        route: event.route,
        tripDate: event.tripDate,
      );

      // Send notification to the traveler about the new match request
      if (_notificationRepository != null) {
        try {
          await _notificationRepository!.notifyMatchRequest(
            recipientId: event.travelerId,
            matchId: id,
            senderName: event.requesterName,
            senderPhoto: event.requesterPhoto,
            itemTitle: event.itemTitle,
            isForTraveler: true,
          );
        } catch (_) {
          // Don't fail match creation if notification fails
        }
      }

      emit(MatchCreated(id));
    } catch (e) {
      emit(MatchError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onMatchesStreamUpdated(
    _MatchesStreamUpdated event,
    Emitter<MatchState> emit,
  ) {
    debugPrint('###MATCH_DEBUG### _onMatchesStreamUpdated: received ${event.matches.length} matches');
    _lastMatches = event.matches;
    emit(MatchesLoaded(event.matches));
  }

  void _onMatchDetailsStreamUpdated(
    _MatchDetailsStreamUpdated event,
    Emitter<MatchState> emit,
  ) {
    final match = event.match;
    if (match == null) {
      emit(const MatchError('Match not found'));
      return;
    }
    _lastMatch = match;
    emit(MatchDetailsLoaded(match));
  }

  void _onMatchStreamFailed(
    _MatchStreamFailed event,
    Emitter<MatchState> emit,
  ) {
    emit(MatchError(event.message.replaceFirst('Exception: ', '')));
  }

  Future<void> _action(
    Emitter<MatchState> emit,
    Future<void> Function() fn, {
    required String successMessage,
    String? matchId,
    String? systemMessage,
    Future<void> Function()? onSuccess,
  }) async {
    try {
      await fn();

      // Send system message if provided and chat repository is available
      if (matchId != null && systemMessage != null && _chatRepository != null) {
        try {
          await _chatRepository!.sendSystemMessage(
            matchId: matchId,
            content: systemMessage,
          );
        } catch (_) {
          // Ignore system message errors - don't fail the main action
        }
      }

      // Execute onSuccess callback for notifications
      if (onSuccess != null) {
        try {
          await onSuccess();
        } catch (_) {
          // Don't fail the main action if notification fails
        }
      }

      emit(MatchActionSuccess(successMessage));

      final details = _lastMatch;
      if (details != null) {
        emit(MatchDetailsLoaded(details));
        return;
      }

      emit(MatchesLoaded(_lastMatches));
    } catch (e) {
      emit(MatchError(e.toString().replaceFirst('Exception: ', '')));

      final details = _lastMatch;
      if (details != null) {
        emit(MatchDetailsLoaded(details));
        return;
      }

      emit(MatchesLoaded(_lastMatches));
    }
  }

  @override
  Future<void> close() async {
    await _matchesSub?.cancel();
    await _detailsSub?.cancel();
    return super.close();
  }
}

class _MatchesStreamUpdated extends MatchEvent {
  const _MatchesStreamUpdated(this.matches);

  final List<MatchModel> matches;

  @override
  List<Object?> get props => <Object?>[matches];
}

class _MatchDetailsStreamUpdated extends MatchEvent {
  const _MatchDetailsStreamUpdated(this.match);

  final MatchModel? match;

  @override
  List<Object?> get props => <Object?>[match];
}

class _MatchStreamFailed extends MatchEvent {
  const _MatchStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
