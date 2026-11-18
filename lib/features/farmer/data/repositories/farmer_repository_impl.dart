import '../../../../core/models/models.dart';
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
}
