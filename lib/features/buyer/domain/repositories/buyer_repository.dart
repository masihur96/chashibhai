import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/create_demand_request_model.dart';
import '../../data/models/create_bid_request_model.dart';

abstract class BuyerRepository {
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  });

  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  });

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
  });

  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  });

  Future<List<Product>> getAvailableProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  });

  Future<Product?> getProductById({
    required String id,
    String? token,
  });
}
