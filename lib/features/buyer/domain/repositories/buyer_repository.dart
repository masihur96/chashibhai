import '../../../../core/models/models.dart';
import '../../data/models/create_demand_request_model.dart';

abstract class BuyerRepository {
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  });
}
