import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';

class ReviewProvider with ChangeNotifier {
  final List<Review> _reviews = List.from(MockData.demoReviews);

  List<Review> get reviews => _reviews;

  List<Review> getReviewsForUser(String userId) {
    return _reviews.where((r) => r.revieweeId == userId).toList();
  }

  double getAverageRating(String userId) {
    final userReviews = getReviewsForUser(userId);
    if (userReviews.isEmpty) return 0.0;
    
    double total = 0.0;
    for (var r in userReviews) {
      total += r.rating;
    }
    return total / userReviews.length;
  }

  bool hasReviewedOrder(String orderId, String reviewerId) {
    return _reviews.any((r) => r.orderId == orderId && r.reviewerId == reviewerId);
  }

  void addReview({
    required String reviewerId,
    required String revieweeId,
    required String orderId,
    required double rating,
    String? comment,
  }) {
    final newReview = Review(
      id: const Uuid().v4(),
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      orderId: orderId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    _reviews.add(newReview);
    notifyListeners();
  }
}
