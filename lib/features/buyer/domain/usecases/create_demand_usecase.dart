import '../../../../core/models/models.dart';
import '../../data/models/create_demand_request_model.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../repositories/buyer_repository.dart';

class CreateDemandUseCase {
  final BuyerRepository repository;

  CreateDemandUseCase([BuyerRepository? repository])
      : repository = repository ?? BuyerRepositoryImpl();

  Future<DemandPost> call({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    return await repository.createDemand(
      request: request,
      token: token,
    );
  }
}
