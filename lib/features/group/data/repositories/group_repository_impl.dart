import '../../../../core/models/models.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_data_source.dart';
import '../models/create_group_request_model.dart';
import '../models/join_group_request_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource _remoteDataSource;

  GroupRepositoryImpl({GroupRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GroupRemoteDataSourceImpl();

  @override
  Future<BuyingGroup> createGroup({
    required CreateGroupRequestModel request,
    String? token,
  }) {
    return _remoteDataSource.createGroup(request: request, token: token);
  }

  @override
  Future<List<BuyingGroup>> getMyGroups({String? token}) {
    return _remoteDataSource.getMyGroups(token: token);
  }

  @override
  Future<List<BuyingGroup>> getGroups({
    String? category,
    String? status,
    String? token,
  }) {
    return _remoteDataSource.getGroups(
      category: category,
      status: status,
      token: token,
    );
  }

  @override
  Future<BuyingGroup> getGroupById({
    required String groupId,
    String? token,
  }) {
    return _remoteDataSource.getGroupById(groupId: groupId, token: token);
  }

  @override
  Future<BuyingGroup> joinGroup({
    required String groupId,
    required JoinGroupRequestModel request,
    String? token,
  }) {
    return _remoteDataSource.joinGroup(
      groupId: groupId,
      request: request,
      token: token,
    );
  }

  @override
  Future<bool> leaveGroup({
    required String groupId,
    String? token,
  }) {
    return _remoteDataSource.leaveGroup(groupId: groupId, token: token);
  }
}
