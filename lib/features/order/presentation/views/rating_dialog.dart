import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/widgets/custom_buttons.dart';
import '../../../account/presentation/state/review_provider.dart';

class RatingDialog extends StatefulWidget {
  final String orderId;
  final String reviewerId;
  final String revieweeId;

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Rate your Experience', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'How was your experience with this order?',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: index < _rating ? Colors.amber : Colors.grey.shade400,
                  size: 40,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a review (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Submit Review',
              onPressed: _rating > 0
                  ? () {
                      context.read<ReviewProvider>().addReview(
                        reviewerId: widget.reviewerId,
                        revieweeId: widget.revieweeId,
                        orderId: widget.orderId,
                        rating: _rating.toDouble(),
                        comment: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                      Navigator.pop(context);
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a star rating.')));
                    },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
