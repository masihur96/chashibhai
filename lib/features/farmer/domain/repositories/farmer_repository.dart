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
}
