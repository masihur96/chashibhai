import '../../../../core/models/models.dart';
import '../../data/models/create_group_request_model.dart';
import '../repositories/group_repository.dart';

class CreateGroupUseCase {
  final GroupRepository repository;

  CreateGroupUseCase(this.repository);

  Future<BuyingGroup> call(CreateGroupRequestModel request, {String? token}) {
    return repository.createGroup(request: request, token: token);
  }
}
