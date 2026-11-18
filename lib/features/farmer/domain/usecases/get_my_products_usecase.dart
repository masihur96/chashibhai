import '../../../../core/models/models.dart';
import '../../data/repositories/farmer_repository_impl.dart';
import '../repositories/farmer_repository.dart';

class GetMyProductsUseCase {
  final FarmerRepository repository;

  GetMyProductsUseCase([FarmerRepository? repository])
      : repository = repository ?? FarmerRepositoryImpl();

  Future<List<Product>> call({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? tradeType,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  }) async {
    return await repository.getMyProducts(
      page: page,
      limit: limit,
      status: status,
      category: category,
      tradeType: tradeType,
      minPrice: minPrice,
      maxPrice: maxPrice,
      search: search,
      token: token,
    );
  }
}
