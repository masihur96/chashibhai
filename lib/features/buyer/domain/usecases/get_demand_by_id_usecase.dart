import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetDemandByIdUseCase {
  final BuyerRepository repository;

  GetDemandByIdUseCase(this.repository);

  Future<DemandPost> call({
    required String demandId,
    String? token,
  }) async {
    return await repository.getDemandById(
      demandId: demandId,
      token: token,
    );
  }
}
