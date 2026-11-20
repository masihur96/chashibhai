import '../../../../core/models/models.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';
import '../models/create_review_request_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;

  ReviewRepositoryImpl({ReviewRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ReviewRemoteDataSourceImpl();

  @override
  Future<Review> createReview({
    required CreateReviewRequestModel request,
    String? token,
  }) {
    return _remoteDataSource.createReview(request: request, token: token);
  }

  @override
  Future<List<Review>> getReviewsByUser({
    required String userId,
    String? token,
  }) {
    return _remoteDataSource.getReviewsByUser(userId: userId, token: token);
  }

  @override
  Future<List<Review>> getReviewsByOrder({
    required String orderId,
    String? token,
  }) {
    return _remoteDataSource.getReviewsByOrder(orderId: orderId, token: token);
  }
}
