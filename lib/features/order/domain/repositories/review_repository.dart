import '../../../../core/models/models.dart';
import '../../data/models/create_review_request_model.dart';

abstract class ReviewRepository {
  Future<Review> createReview({
    required CreateReviewRequestModel request,
    String? token,
  });

  Future<List<Review>> getReviewsByUser({
    required String userId,
    String? token,
  });

  Future<List<Review>> getReviewsByOrder({
    required String orderId,
    String? token,
  });
}
