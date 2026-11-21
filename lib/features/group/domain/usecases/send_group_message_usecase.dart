import '../../../../core/models/models.dart';
import '../repositories/group_repository.dart';

class SendGroupMessageUseCase {
  final GroupRepository repository;

  SendGroupMessageUseCase(this.repository);

  Future<GroupMessage> call({
    required String groupId,
    required String message,
    String? token,
  }) {
    return repository.sendGroupMessage(
      groupId: groupId,
      message: message,
      token: token,
    );
  }
}
