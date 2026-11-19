import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/create_product_request_model.dart';

abstract class FarmerRepository {
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  });

  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  });

  Future<List<Product>> getMyProducts({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? tradeType,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  });

  Future<Product> getProductById({
    required String id,
    String? token,
  });
}
