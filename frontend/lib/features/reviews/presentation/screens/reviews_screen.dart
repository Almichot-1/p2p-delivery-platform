import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../bloc/review_bloc.dart';
import '../../bloc/review_event.dart';
import '../../bloc/review_state.dart';
import '../widgets/review_card.dart';

class ReviewsScreen extends StatelessWidget {
  final String userId;

  const ReviewsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReviewBloc>()..add(ReviewsLoadRequested(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews'),
        ),
        body: BlocBuilder<ReviewBloc, ReviewState>(
          builder: (context, state) {
            if (state is ReviewLoading) {
              return const LoadingWidget();
            }

            if (state is ReviewError) {
              return Center(child: Text(state.message));
            }

            if (state is ReviewsLoaded) {
              if (state.reviews.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.star_border,
                  title: 'No Reviews Yet',
                  subtitle: 'Reviews will appear here',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.reviews.length,
                itemBuilder: (context, index) {
                  return ReviewCard(review: state.reviews[index]);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
