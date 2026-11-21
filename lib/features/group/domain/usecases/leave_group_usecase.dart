import '../repositories/group_repository.dart';

class LeaveGroupUseCase {
  final GroupRepository repository;

  LeaveGroupUseCase(this.repository);

  Future<bool> call(String groupId, {String? token}) {
    return repository.leaveGroup(groupId: groupId, token: token);
  }
}
