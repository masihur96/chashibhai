import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetMyBidsUseCase {
  final BuyerRepository repository;

  GetMyBidsUseCase(this.repository);

  Future<List<Bid>> call({String? token}) async {
    return await repository.getMyBids(token: token);
  }
}
