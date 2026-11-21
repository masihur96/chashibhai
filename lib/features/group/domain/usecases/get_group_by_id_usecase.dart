import '../../../../core/models/models.dart';
import '../repositories/group_repository.dart';

class GetGroupByIdUseCase {
  final GroupRepository repository;

  GetGroupByIdUseCase(this.repository);

  Future<BuyingGroup> call(String groupId, {String? token}) {
    return repository.getGroupById(groupId: groupId, token: token);
  }
}
