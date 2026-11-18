import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../datasources/farmer_remote_data_source.dart';
import '../models/create_product_request_model.dart';

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
}
