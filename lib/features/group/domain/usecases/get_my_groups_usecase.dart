import '../../../../core/models/models.dart';
import '../repositories/group_repository.dart';

class GetMyGroupsUseCase {
  final GroupRepository repository;

  GetMyGroupsUseCase(this.repository);

  Future<List<BuyingGroup>> call({String? token}) {
    return repository.getMyGroups(token: token);
  }
}
