import '../../../../core/models/models.dart';
import '../repositories/group_repository.dart';

class GetGroupMessagesUseCase {
  final GroupRepository repository;

  GetGroupMessagesUseCase(this.repository);

  Future<List<GroupMessage>> call({
    required String groupId,
    int page = 1,
    int limit = 50,
    String? token,
  }) {
    return repository.getGroupMessages(
      groupId: groupId,
      page: page,
      limit: limit,
      token: token,
    );
  }
}
