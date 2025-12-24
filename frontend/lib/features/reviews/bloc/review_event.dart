import 'package:equatable/equatable.dart';
import '../data/models/review_model.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class ReviewsLoadRequested extends ReviewEvent {
  final String userId;

  const ReviewsLoadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class ReviewCreateRequested extends ReviewEvent {
  final ReviewModel review;

  const ReviewCreateRequested(this.review);

  @override
  List<Object> get props => [review];
}

class ReviewCheckRequested extends ReviewEvent {
  final String matchId;
  final String reviewerId;

  const ReviewCheckRequested(this.matchId, this.reviewerId);

  @override
  List<Object> get props => [matchId, reviewerId];
}
