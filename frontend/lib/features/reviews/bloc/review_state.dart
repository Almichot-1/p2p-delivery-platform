import 'package:equatable/equatable.dart';
import '../data/models/review_model.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;

  const ReviewsLoaded(this.reviews);

  @override
  List<Object> get props => [reviews];
}

class ReviewCreated extends ReviewState {}

class ReviewCheckResult extends ReviewState {
  final bool hasReviewed;

  const ReviewCheckResult(this.hasReviewed);

  @override
  List<Object> get props => [hasReviewed];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object> get props => [message];
}
