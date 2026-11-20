import '../../../../core/models/models.dart';
import '../repositories/buyer_repository.dart';

class GetAvailableProductsUseCase {
  final BuyerRepository repository;

  GetAvailableProductsUseCase(this.repository);

  Future<List<Product>> call({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  }) async {
    return await repository.getAvailableProducts(
      page: page,
      limit: limit,
      category: category,
      search: search,
      token: token,
    );
  }
}
