import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetMyNegotiationsUseCase {
  final BuyerRepository repository;

  GetMyNegotiationsUseCase(this.repository);

  Future<List<Negotiation>> call({
    String? token,
  }) async {
    return await repository.getMyNegotiations(
      token: token,
    );
  }
}
