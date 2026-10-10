import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../data/services/database_service.dart';
import '../../data/services/auth_service.dart';
import 'review_dialog.dart';

class ReviewsListWidget extends StatelessWidget {
  final String targetId;
  final String targetType;
  final String targetName;

  const ReviewsListWidget({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Reviews',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                FutureBuilder<double>(
                  future: DatabaseService.instance.getAverageRating(targetId, targetType),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data! > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              snapshot.data!.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            if (targetType == 'user')
              FutureBuilder<bool>(
                future: DatabaseService.instance.hasSuccessfulTransaction(
                  AuthService.instance.currentUser?.uid ?? '',
                  targetId,
                ),
                builder: (context, snapshot) {
                  final hasTransaction = snapshot.data ?? false;
                  if (!hasTransaction) return const SizedBox.shrink();

                  return _buildReviewButton(context);
                },
              )
            else
              _buildReviewButton(context),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Review>>(
          stream: DatabaseService.instance.getReviewsForTargetStream(targetId, targetType),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error loading reviews: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No reviews yet. Be the first to leave one!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(review.comment),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => ReviewDialog(
            targetId: targetId,
            targetType: targetType,
            targetName: targetName,
          ),
        );
      },
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text('Leave a Review'),
    );
  }
}
