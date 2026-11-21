import '../../../../core/models/models.dart';
import '../../data/models/create_group_request_model.dart';
import '../../data/models/join_group_request_model.dart';

abstract class GroupRepository {
  Future<BuyingGroup> createGroup({
    required CreateGroupRequestModel request,
    String? token,
  });

  Future<List<BuyingGroup>> getMyGroups({
    String? token,
  });

  Future<List<BuyingGroup>> getGroups({
    String? category,
    String? status,
    String? token,
  });

  Future<BuyingGroup> getGroupById({
    required String groupId,
    String? token,
  });

  Future<BuyingGroup> joinGroup({
    required String groupId,
    required JoinGroupRequestModel request,
    String? token,
  });

  Future<bool> leaveGroup({
    required String groupId,
    String? token,
  });
}
