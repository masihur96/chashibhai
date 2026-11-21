import '../../../../core/models/models.dart';
import '../repositories/group_repository.dart';

class GetGroupsUseCase {
  final GroupRepository repository;

  GetGroupsUseCase(this.repository);

  Future<List<BuyingGroup>> call({
    String? category,
    String? status,
    String? token,
  }) {
    return repository.getGroups(
      category: category,
      status: status,
      token: token,
    );
  }
}
