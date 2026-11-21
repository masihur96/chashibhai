import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/create_group_request_model.dart';
import '../../data/models/join_group_request_model.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/get_group_by_id_usecase.dart';
import '../../domain/usecases/get_group_messages_usecase.dart';
import '../../domain/usecases/get_groups_usecase.dart';
import '../../domain/usecases/get_my_groups_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';
import '../../domain/usecases/leave_group_usecase.dart';
import '../../domain/usecases/send_group_message_usecase.dart';

class GroupProvider extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final CreateGroupUseCase _createGroupUseCase;
  final GetMyGroupsUseCase _getMyGroupsUseCase;
  final GetGroupsUseCase _getGroupsUseCase;
  final GetGroupByIdUseCase _getGroupByIdUseCase;
  final JoinGroupUseCase _joinGroupUseCase;
  final LeaveGroupUseCase _leaveGroupUseCase;
  final GetGroupMessagesUseCase _getGroupMessagesUseCase;
  final SendGroupMessageUseCase _sendGroupMessageUseCase;

  /// Default cURL bearer token for group operations
  static const String defaultGroupCurlToken =
      GroupRemoteDataSourceImpl.defaultFallbackToken;

  List<BuyingGroup> _groups = [];
  List<BuyingGroup> _myGroups = [];
  BuyingGroup? _currentGroupDetails;
  final Map<String, List<GroupMessage>> _groupMessages = {};

  bool _isCreatingGroup = false;
  String? _createGroupError;

  bool _isLoadingMyGroups = false;
  String? _myGroupsError;

  bool _isLoadingGroups = false;
  String? _groupsError;

  bool _isLoadingGroupDetails = false;
  String? _groupDetailsError;

  bool _isJoiningGroup = false;
  String? _joinGroupError;

  bool _isLeavingGroup = false;
  String? _leaveGroupError;

  bool _isLoadingMessages = false;
  String? _messagesError;

  bool _isSendingMessage = false;
  String? _sendMessageError;

  GroupProvider({
    GroupRepository? groupRepository,
    CreateGroupUseCase? createGroupUseCase,
    GetMyGroupsUseCase? getMyGroupsUseCase,
    GetGroupsUseCase? getGroupsUseCase,
    GetGroupByIdUseCase? getGroupByIdUseCase,
    JoinGroupUseCase? joinGroupUseCase,
    LeaveGroupUseCase? leaveGroupUseCase,
    GetGroupMessagesUseCase? getGroupMessagesUseCase,
    SendGroupMessageUseCase? sendGroupMessageUseCase,
  })  : _groupRepository = groupRepository ?? GroupRepositoryImpl(),
        _createGroupUseCase = createGroupUseCase ??
            CreateGroupUseCase(groupRepository ?? GroupRepositoryImpl()),
        _getMyGroupsUseCase = getMyGroupsUseCase ??
            GetMyGroupsUseCase(groupRepository ?? GroupRepositoryImpl()),
        _getGroupsUseCase = getGroupsUseCase ??
            GetGroupsUseCase(groupRepository ?? GroupRepositoryImpl()),
        _getGroupByIdUseCase = getGroupByIdUseCase ??
            GetGroupByIdUseCase(groupRepository ?? GroupRepositoryImpl()),
        _joinGroupUseCase = joinGroupUseCase ??
            JoinGroupUseCase(groupRepository ?? GroupRepositoryImpl()),
        _leaveGroupUseCase = leaveGroupUseCase ??
            LeaveGroupUseCase(groupRepository ?? GroupRepositoryImpl()),
        _getGroupMessagesUseCase = getGroupMessagesUseCase ??
            GetGroupMessagesUseCase(groupRepository ?? GroupRepositoryImpl()),
        _sendGroupMessageUseCase = sendGroupMessageUseCase ??
            SendGroupMessageUseCase(groupRepository ?? GroupRepositoryImpl());

  // Getters
  GroupRepository get groupRepository => _groupRepository;
  List<BuyingGroup> get groups => _groups;
  List<BuyingGroup> get myGroups => _myGroups;
  BuyingGroup? get currentGroupDetails => _currentGroupDetails;

  bool get isCreatingGroup => _isCreatingGroup;
  String? get createGroupError => _createGroupError;

  bool get isLoadingMyGroups => _isLoadingMyGroups;
  String? get myGroupsError => _myGroupsError;

  bool get isLoadingGroups => _isLoadingGroups;
  String? get groupsError => _groupsError;

  bool get isLoadingGroupDetails => _isLoadingGroupDetails;
  String? get groupDetailsError => _groupDetailsError;

  bool get isJoiningGroup => _isJoiningGroup;
  String? get joinGroupError => _joinGroupError;

  bool get isLeavingGroup => _isLeavingGroup;
  String? get leaveGroupError => _leaveGroupError;

  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;

  bool get isSendingMessage => _isSendingMessage;
  String? get sendMessageError => _sendMessageError;

  List<GroupMessage> getMessagesForGroup(String groupId) {
    if (_groupMessages.containsKey(groupId)) {
      return _groupMessages[groupId]!;
    }
    return getGroupById(groupId)?.messages ?? [];
  }

  void setGroups(List<BuyingGroup> groups) {
    _groups = groups;
    notifyListeners();
  }

  BuyingGroup? getGroupById(String id) {
    if (_currentGroupDetails != null && _currentGroupDetails!.id == id) {
      return _currentGroupDetails;
    }
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      try {
        return _myGroups.firstWhere((g) => g.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  List<BuyingGroup> getMyGroups(String? currentUserId) {
    if (_myGroups.isNotEmpty) {
      return _myGroups;
    }
    if (currentUserId == null || currentUserId.isEmpty) return [];
    return _groups.where((g) {
      final isCreator = g.createdBy == currentUserId;
      final isMember = g.members.any((m) => m.userId == currentUserId);
      return isCreator || isMember;
    }).toList();
  }

  /// Creates a group using POST /api/v1/groups and immediately fetches user's groups via GET /api/v1/groups/my
  Future<BuyingGroup> createGroup(
    CreateGroupRequestModel request, {
    String? token,
  }) async {
    _isCreatingGroup = true;
    _createGroupError = null;
    notifyListeners();

    try {
      final newGroup = await _createGroupUseCase(
        request,
        token: token ?? defaultGroupCurlToken,
      );

      // Add to local state immediately
      _myGroups = [
        newGroup,
        ..._myGroups.where((g) => g.id != newGroup.id),
      ];
      _groups = [
        newGroup,
        ..._groups.where((g) => g.id != newGroup.id),
      ];
      notifyListeners();

      // Immediately fetch user's groups via GET /api/v1/groups/my as requested
      try {
        await fetchMyGroups(token: token ?? defaultGroupCurlToken);
      } catch (e) {
        debugPrint('⚠️ [GROUP_PROVIDER] fetchMyGroups after create warning: $e');
      }

      return newGroup;
    } catch (e) {
      _createGroupError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      _isCreatingGroup = false;
      notifyListeners();
    }
  }

  /// Fetches my groups using GET /api/v1/groups/my
  Future<List<BuyingGroup>> fetchMyGroups({String? token}) async {
    _isLoadingMyGroups = true;
    _myGroupsError = null;
    notifyListeners();

    try {
      final list = await _getMyGroupsUseCase(
        token: token ?? defaultGroupCurlToken,
      );
      _myGroups = list;

      // Merge into _groups so any reference to getGroupById finds them
      for (final mg in list) {
        final idx = _groups.indexWhere((g) => g.id == mg.id);
        if (idx >= 0) {
          _groups[idx] = mg;
        } else {
          _groups.add(mg);
        }
      }
      return _myGroups;
    } catch (e) {
      _myGroupsError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('⚠️ [GROUP_PROVIDER] fetchMyGroups error: $e');
      return _myGroups;
    } finally {
      _isLoadingMyGroups = false;
      notifyListeners();
    }
  }

  /// Fetches open buying groups using GET /api/v1/groups
  Future<List<BuyingGroup>> fetchGroups({
    String? category,
    String? status,
    String? token,
  }) async {
    _isLoadingGroups = true;
    _groupsError = null;
    notifyListeners();

    try {
      final list = await _getGroupsUseCase(
        category: category,
        status: status,
        token: token ?? defaultGroupCurlToken,
      );
      _groups = list;
      return _groups;
    } catch (e) {
      _groupsError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('⚠️ [GROUP_PROVIDER] fetchGroups error: $e');
      return _groups;
    } finally {
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  /// Fetches group details using GET /api/v1/groups/:id
  Future<BuyingGroup> fetchGroupDetails(
    String groupId, {
    String? token,
  }) async {
    _isLoadingGroupDetails = true;
    _groupDetailsError = null;
    notifyListeners();

    try {
      final group = await _getGroupByIdUseCase(
        groupId,
        token: token ?? defaultGroupCurlToken,
      );
      _currentGroupDetails = group;

      // Update in _groups
      final groupIdx = _groups.indexWhere((g) => g.id == groupId);
      if (groupIdx >= 0) {
        _groups[groupIdx] = group;
      } else {
        _groups.add(group);
      }

      // Update in _myGroups if present
      final myGroupIdx = _myGroups.indexWhere((g) => g.id == groupId);
      if (myGroupIdx >= 0) {
        _myGroups[myGroupIdx] = group;
      }

      return group;
    } catch (e) {
      _groupDetailsError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoadingGroupDetails = false;
      notifyListeners();
    }
  }

  /// Joins a group using POST /api/v1/groups/:id/join
  Future<BuyingGroup> joinGroup(
    String groupId,
    JoinGroupRequestModel request, {
    String? token,
  }) async {
    _isJoiningGroup = true;
    _joinGroupError = null;
    notifyListeners();

    try {
      final updatedGroup = await _joinGroupUseCase(
        groupId: groupId,
        request: request,
        token: token ?? defaultGroupCurlToken,
      );

      _currentGroupDetails = updatedGroup;

      final gIdx = _groups.indexWhere((g) => g.id == groupId);
      if (gIdx >= 0) {
        _groups[gIdx] = updatedGroup;
      } else {
        _groups.add(updatedGroup);
      }

      final mgIdx = _myGroups.indexWhere((g) => g.id == groupId);
      if (mgIdx >= 0) {
        _myGroups[mgIdx] = updatedGroup;
      } else {
        _myGroups.add(updatedGroup);
      }

      // Refresh my groups list
      try {
        await fetchMyGroups(token: token ?? defaultGroupCurlToken);
      } catch (_) {}

      return updatedGroup;
    } catch (e) {
      _joinGroupError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isJoiningGroup = false;
      notifyListeners();
    }
  }

  /// Leaves a group using DELETE /api/v1/groups/:id/leave
  Future<bool> leaveGroup(
    String groupId, {
    String? token,
  }) async {
    _isLeavingGroup = true;
    _leaveGroupError = null;
    notifyListeners();

    try {
      final success = await _leaveGroupUseCase(
        groupId,
        token: token ?? defaultGroupCurlToken,
      );

      _myGroups.removeWhere((g) => g.id == groupId);

      // Refresh details to get latest membership status
      try {
        await fetchGroupDetails(groupId, token: token ?? defaultGroupCurlToken);
      } catch (_) {}

      try {
        await fetchMyGroups(token: token ?? defaultGroupCurlToken);
      } catch (_) {}

      return success;
    } catch (e) {
      _leaveGroupError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLeavingGroup = false;
      notifyListeners();
    }
  }

  /// Fetches group chat messages using GET /api/v1/groups/:id/messages?page=1&limit=50
  Future<List<GroupMessage>> fetchGroupMessages(
    String groupId, {
    int page = 1,
    int limit = 50,
    String? token,
  }) async {
    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();

    try {
      final msgs = await _getGroupMessagesUseCase(
        groupId: groupId,
        page: page,
        limit: limit,
        token: token ?? defaultGroupCurlToken,
      );

      _groupMessages[groupId] = msgs;

      // Update in BuyingGroup
      final grp = getGroupById(groupId);
      if (grp != null) {
        final updatedGrp = grp.copyWith(messages: msgs);
        final gIdx = _groups.indexWhere((g) => g.id == groupId);
        if (gIdx >= 0) _groups[gIdx] = updatedGrp;
        final mgIdx = _myGroups.indexWhere((g) => g.id == groupId);
        if (mgIdx >= 0) _myGroups[mgIdx] = updatedGrp;
        if (_currentGroupDetails?.id == groupId) _currentGroupDetails = updatedGrp;
      }

      return msgs;
    } catch (e) {
      _messagesError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('⚠️ [GROUP_PROVIDER] fetchGroupMessages error: $e');
      return _groupMessages[groupId] ?? [];
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Sends a group chat message using POST /api/v1/groups/:id/messages
  Future<GroupMessage> sendGroupMessage(
    String groupId,
    String message, {
    String? token,
  }) async {
    _isSendingMessage = true;
    _sendMessageError = null;
    notifyListeners();

    try {
      final newMsg = await _sendGroupMessageUseCase(
        groupId: groupId,
        message: message,
        token: token ?? defaultGroupCurlToken,
      );

      // Append locally
      final currentList = _groupMessages[groupId] ?? getGroupById(groupId)?.messages ?? [];
      _groupMessages[groupId] = [...currentList, newMsg];

      // Update in BuyingGroup
      final grp = getGroupById(groupId);
      if (grp != null) {
        final updatedGrp = grp.copyWith(messages: _groupMessages[groupId]!);
        final gIdx = _groups.indexWhere((g) => g.id == groupId);
        if (gIdx >= 0) _groups[gIdx] = updatedGrp;
        final mgIdx = _myGroups.indexWhere((g) => g.id == groupId);
        if (mgIdx >= 0) _myGroups[mgIdx] = updatedGrp;
        if (_currentGroupDetails?.id == groupId) _currentGroupDetails = updatedGrp;
      }
      notifyListeners();

      // Silently refresh to ensure server timestamp and sender details sync
      try {
        await fetchGroupMessages(groupId, page: 1, limit: 50, token: token ?? defaultGroupCurlToken);
      } catch (_) {}

      return newMsg;
    } catch (e) {
      _sendMessageError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }
}
