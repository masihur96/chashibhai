import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetProductBidsUseCase {
  final BuyerRepository repository;

  GetProductBidsUseCase(this.repository);

  Future<List<Bid>> call({
    required String productId,
    String? token,
  }) async {
    return await repository.getBidsByProductId(
      productId: productId,
      token: token,
    );
  }
}
