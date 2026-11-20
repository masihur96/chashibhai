import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../datasources/buyer_remote_data_source.dart';
import '../models/create_demand_request_model.dart';
import '../models/create_bid_request_model.dart';

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

  @override
  Future<List<DemandPost>> getMyDemands({
    int page = 1,
    int limit = 10,
    String? search,
    String? productName,
    double? minPrice,
    double? maxPrice,
    String? tradeType,
    String? status,
    String? token,
  }) async {
    return await remoteDataSource.getMyDemands(
      page: page,
      limit: limit,
      search: search,
      productName: productName,
      minPrice: minPrice,
      maxPrice: maxPrice,
      tradeType: tradeType,
      status: status,
      token: token,
    );
  }

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async {
    return await remoteDataSource.createBid(
      request: request,
      token: token,
    );
  }

  @override
  Future<List<Product>> getAvailableProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  }) async {
    return await remoteDataSource.getAvailableProducts(
      page: page,
      limit: limit,
      category: category,
      search: search,
      token: token,
    );
  }

  @override
  Future<Product?> getProductById({
    required String id,
    String? token,
  }) async {
    return await remoteDataSource.getProductById(
      id: id,
      token: token,
    );
  }

  @override
  Future<List<Bid>> getBidsByProductId({
    required String productId,
    String? token,
  }) async {
    return await remoteDataSource.getBidsByProductId(
      productId: productId,
      token: token,
    );
  }
}
