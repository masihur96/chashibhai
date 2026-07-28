import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../../features/account/presentation/state/review_provider.dart';

class ReviewsListSheet extends StatelessWidget {
  final String userId;

  const ReviewsListSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>().getReviewsForUser(userId);
    final averageRating = context.watch<ReviewProvider>().getAverageRating(userId);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${reviews.length})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  // Ideally, you would fetch the reviewer's name using their ID.
                  // Since we don't have a users list provider easily accessible here, we'll mock it for now.
                  String reviewerName = review.reviewerId == 'u1' ? 'Masihur Rahman' : 
                                        review.reviewerId == 'f1' ? 'Farmer Abdul' : 'User ${review.reviewerId.substring(0, 4)}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  reviewerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Text(
                              DateFormat.yMMMd().format(review.createdAt),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < review.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: starIndex < review.rating ? Colors.amber : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        if (review.comment != null && review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review.comment!,
                            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
