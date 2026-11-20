import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/account/presentation/state/review_provider.dart';
import '../../../features/auth/presentation/state/auth_provider.dart';

class ReviewsListSheet extends StatefulWidget {
  final String? userId;
  final String? orderId;

  const ReviewsListSheet({
    super.key,
    this.userId,
    this.orderId,
  });

  @override
  State<ReviewsListSheet> createState() => _ReviewsListSheetState();
}

class _ReviewsListSheetState extends State<ReviewsListSheet> {
  String get effectiveOrderId => widget.orderId ?? ' rfs dfsd';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReviews();
    });
  }

  Future<void> _fetchReviews() async {
    final token = context.read<AuthProvider>().token;
    // Fetch review(s) for the specified order using GET /api/v1/reviews/order/{orderId}
    await context.read<ReviewProvider>().fetchReviewsForOrder(
          orderId: effectiveOrderId,
          token: token,
        );

    if (!mounted) return;

    // If a userId was also provided, fetch their reviews in parallel
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      await context.read<ReviewProvider>().fetchReviewsForUser(
            widget.userId!,
            token: token,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReviewProvider>();
    final isLoading = rp.isLoadingOrderReviews;
    final error = rp.orderReviewsError;

    // Order reviews fetched from GET /api/v1/reviews/order/{orderId}
    final orderReviews = rp.orderReviews;
    final userReviews = widget.userId != null
        ? rp.getReviewsForUser(widget.userId!)
        : <Review>[];

    // Priority: order reviews from the API, else user reviews, else local reviews for this order
    final reviews = orderReviews.isNotEmpty
        ? orderReviews
        : (userReviews.isNotEmpty
            ? userReviews
            : rp.getReviewsForOrder(effectiveOrderId));

    final averageRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : (widget.userId != null ? rp.getAverageRating(widget.userId!) : 0.0);

    return Container(
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.orderId != null || widget.userId == null
                          ? 'Order Reviews'
                          : 'Reviews',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order: $effectiveOrderId',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (reviews.isNotEmpty) ...[
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' (${reviews.length})',
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton(
                    tooltip: 'Refresh Reviews',
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded,
                            color: AppColors.primary),
                    onPressed: isLoading ? null : _fetchReviews,
                  ),
                ],
              ),
            ],
          ),

          // cURL Endpoint Pill / Query Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GET',
                    style: GoogleFonts.firaCode(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '/api/v1/reviews/order/${Uri.encodeComponent(effectiveOrderId)}',
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Server error / notice banner
          if (error != null && orderReviews.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFEA580C), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Notice',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC2410C),
                          ),
                        ),
                        Text(
                          error,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF9A3412),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchReviews,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 1),
          const SizedBox(height: 8),

          // Content body
          if (isLoading && reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Fetching review from server...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 44, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      'No reviews found for this order',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #$effectiveOrderId has not received reviews yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _fetchReviews,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Try Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: reviews.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 18),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  String reviewerName = review.reviewerId == 'u1'
                      ? 'Masihur Rahman (Buyer)'
                      : review.reviewerId == 'f1'
                          ? 'Farmer Abdul'
                          : review.reviewerId.length >= 6
                              ? 'User ${review.reviewerId.substring(0, 6)}'
                              : 'User ${review.reviewerId}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
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
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reviewerName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (review.orderId != null &&
                                        review.orderId!.isNotEmpty)
                                      Text(
                                        'Order #${review.orderId}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              DateFormat.yMMMd().format(review.createdAt),
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              starIndex < review.rating.floor()
                                  ? Icons.star_rounded
                                  : (starIndex < review.rating
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                              size: 18,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        if (review.comment != null &&
                            review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              review.comment!,
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
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
