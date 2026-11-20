import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetDemandsUseCase {
  final BuyerRepository _repository;

  GetDemandsUseCase(this._repository);

  Future<List<DemandPost>> call({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  }) async {
    return await _repository.getDemands(
      page: page,
      limit: limit,
      tradeType: tradeType,
      status: status,
      search: search,
      token: token,
    );
  }
}
