import '../repositories/group_repository.dart';

class PostDemandFromGroupUseCase {
  final GroupRepository repository;

  PostDemandFromGroupUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String groupId,
    String? token,
  }) {
    return repository.postDemandFromGroup(
      groupId: groupId,
      token: token,
    );
  }
}
