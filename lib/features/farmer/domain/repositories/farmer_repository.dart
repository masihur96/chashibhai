import '../../../../core/models/models.dart';
import '../../data/models/create_product_request_model.dart';

abstract class FarmerRepository {
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  });
}
