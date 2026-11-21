import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetDemandOffersUseCase {
  final BuyerRepository repository;

  GetDemandOffersUseCase(this.repository);

  Future<List<DemandOffer>> call({
    required String demandId,
    String? token,
  }) async {
    return await repository.getDemandOffers(
      demandId: demandId,
      token: token,
    );
  }
}
