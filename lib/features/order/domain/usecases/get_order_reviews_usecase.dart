import '../../../../core/models/models.dart';
import '../repositories/review_repository.dart';

class GetOrderReviewsUseCase {
  final ReviewRepository _repository;

  GetOrderReviewsUseCase(this._repository);

  Future<List<Review>> call({
    required String orderId,
    String? token,
  }) {
    return _repository.getReviewsByOrder(orderId: orderId, token: token);
  }
}
