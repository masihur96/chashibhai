import '../../../../core/models/models.dart';
import '../../data/models/join_group_request_model.dart';
import '../repositories/group_repository.dart';

class JoinGroupUseCase {
  final GroupRepository repository;

  JoinGroupUseCase(this.repository);

  Future<BuyingGroup> call({
    required String groupId,
    required JoinGroupRequestModel request,
    String? token,
  }) {
    return repository.joinGroup(groupId: groupId, request: request, token: token);
  }
}
