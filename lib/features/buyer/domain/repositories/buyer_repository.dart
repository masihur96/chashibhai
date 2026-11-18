import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/create_demand_request_model.dart';

abstract class BuyerRepository {
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  });

  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  });
}
