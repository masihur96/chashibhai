import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../datasources/buyer_remote_data_source.dart';
import '../models/create_demand_request_model.dart';

class BuyerRepositoryImpl implements BuyerRepository {
  final BuyerRemoteDataSource remoteDataSource;

  BuyerRepositoryImpl({BuyerRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? BuyerRemoteDataSourceImpl();

  @override
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    return await remoteDataSource.createDemand(
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
