import '../../../../core/models/models.dart';
import '../../data/models/create_product_request_model.dart';
import '../../data/repositories/farmer_repository_impl.dart';
import '../repositories/farmer_repository.dart';

class AddProductUseCase {
  final FarmerRepository repository;

  AddProductUseCase([FarmerRepository? repository])
      : repository = repository ?? FarmerRepositoryImpl();

  Future<Product> call({
    required CreateProductRequestModel request,
    String? token,
  }) async {
    return await repository.addProduct(
      request: request,
      token: token,
    );
  }
}
