import '../../../../core/models/models.dart';
import '../../data/models/create_bid_request_model.dart';
import '../repositories/buyer_repository.dart';

class CreateBidUseCase {
  final BuyerRepository repository;

  CreateBidUseCase(this.repository);

  Future<Bid> call({
    required CreateBidRequestModel request,
    String? token,
  }) async {
    return await repository.createBid(
      request: request,
      token: token,
    );
  }
}
