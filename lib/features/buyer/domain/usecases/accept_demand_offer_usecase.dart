import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class AcceptDemandOfferUseCase {
  final BuyerRepository repository;

  AcceptDemandOfferUseCase(this.repository);

  Future<AcceptDemandOfferResult> call({
    required String demandId,
    required String offerId,
    String? token,
  }) async {
    return await repository.acceptDemandOffer(
      demandId: demandId,
      offerId: offerId,
      token: token,
    );
  }
}
