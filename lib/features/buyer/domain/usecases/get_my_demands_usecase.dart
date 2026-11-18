import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetMyDemandsUseCase {
  final BuyerRepository repository;

  GetMyDemandsUseCase(this.repository);

  Future<List<DemandPost>> call({
    int page = 1,
    int limit = 10,
    String? search,
    String? productName,
    double? minPrice,
    double? maxPrice,
    String? tradeType,
    String? status,
    String? token,
  }) async {
    return await repository.getMyDemands(
      page: page,
      limit: limit,
      search: search,
      productName: productName,
      minPrice: minPrice,
      maxPrice: maxPrice,
      tradeType: tradeType,
      status: status,
      token: token,
    );
  }
}
