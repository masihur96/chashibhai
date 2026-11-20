import '../../../../core/models/models.dart';
import '../../data/models/create_demand_offer_request_model.dart';
import '../repositories/buyer_repository.dart';

class SubmitDemandOfferUseCase {
  final BuyerRepository _repository;

  SubmitDemandOfferUseCase(this._repository);

  Future<DemandOffer> call({
    required String demandId,
    required CreateDemandOfferRequestModel request,
    String? token,
  }) {
    return _repository.submitDemandOffer(
      demandId: demandId,
      request: request,
      token: token,
    );
  }
}
