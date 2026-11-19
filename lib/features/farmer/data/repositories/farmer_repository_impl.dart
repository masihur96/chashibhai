import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../datasources/farmer_remote_data_source.dart';
import '../models/create_product_request_model.dart';
import '../models/update_product_request_model.dart';

class FarmerRepositoryImpl implements FarmerRepository {
  final FarmerRemoteDataSource remoteDataSource;

  FarmerRepositoryImpl({FarmerRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? FarmerRemoteDataSourceImpl();

  @override
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  }) async {
    return await remoteDataSource.addProduct(
      request: request,
      token: token,
    );
  }

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return await remoteDataSource.uploadImages(
      files: files,
      token: token,
    );
  }

  @override
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
  }) async {
    return await remoteDataSource.getMyProducts(
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

  @override
  Future<Product> getProductById({
    required String id,
    String? token,
  }) async {
    return await remoteDataSource.getProductById(
      id: id,
      token: token,
    );
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductRequestModel request,
    String? token,
  }) async {
    return await remoteDataSource.updateProduct(
      id: id,
      request: request,
      token: token,
    );
  }

  @override
  Future<bool> deleteProduct({
    required String id,
    String? token,
  }) async {
    return await remoteDataSource.deleteProduct(
      id: id,
      token: token,
    );
  }
}
