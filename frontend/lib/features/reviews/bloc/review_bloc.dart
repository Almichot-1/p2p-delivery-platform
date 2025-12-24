import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/review_repository.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;
  StreamSubscription? _reviewsSubscription;

  ReviewBloc(this._reviewRepository) : super(ReviewInitial()) {
    on<ReviewsLoadRequested>(_onReviewsLoadRequested);
    on<ReviewCreateRequested>(_onReviewCreateRequested);
    on<ReviewCheckRequested>(_onReviewCheckRequested);
  }

  Future<void> _onReviewsLoadRequested(
    ReviewsLoadRequested event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    await _reviewsSubscription?.cancel();
    _reviewsSubscription =
        _reviewRepository.getUserReviews(event.userId).listen(
              (reviews) => emit(ReviewsLoaded(reviews)),
              onError: (error) => emit(ReviewError(error.toString())),
            );
  }

  Future<void> _onReviewCreateRequested(
    ReviewCreateRequested event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    try {
      await _reviewRepository.createReview(event.review);
      emit(ReviewCreated());
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onReviewCheckRequested(
    ReviewCheckRequested event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      final hasReviewed = await _reviewRepository.hasReviewed(
        event.matchId,
        event.reviewerId,
      );
      emit(ReviewCheckResult(hasReviewed));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _reviewsSubscription?.cancel();
    return super.close();
  }
}
