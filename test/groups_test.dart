import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/group/data/models/create_group_request_model.dart';
import 'package:chashibhai/features/group/data/models/join_group_request_model.dart';
import 'package:chashibhai/features/group/domain/repositories/group_repository.dart';
import 'package:chashibhai/features/group/domain/usecases/create_group_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/get_group_by_id_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/get_group_messages_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/get_groups_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/get_my_groups_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/join_group_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/leave_group_usecase.dart';
import 'package:chashibhai/features/group/domain/usecases/send_group_message_usecase.dart';
import 'package:chashibhai/features/group/presentation/state/group_provider.dart';
import 'package:chashibhai/features/group/presentation/views/group_detail_screen.dart';
import 'package:chashibhai/features/group/presentation/views/groups_list_screen.dart';

class MockGroupRepository implements GroupRepository {
  List<BuyingGroup> openGroups = [];
  List<BuyingGroup> myGroups = [];
  CreateGroupRequestModel? lastCreateRequest;
  JoinGroupRequestModel? lastJoinRequest;
  String? lastJoinedGroupId;
  String? lastLeftGroupId;
  String? lastFetchedDetailsGroupId;

  @override
  Future<BuyingGroup> createGroup({
    required CreateGroupRequestModel request,
    String? token,
  }) async {
    lastCreateRequest = request;
    final created = BuyingGroup(
      id: 'group_test_123',
      name: request.name,
      productName: request.productName,
      category: request.category,
      targetQuantity: request.targetQuantity,
      filledQuantity: request.initialContribution,
      pricePerKg: request.pricePerKg,
      deliveryLocation: request.deliveryLocation,
      createdBy: 'u_tester',
      members: [
        GroupMember(
          userId: 'u_tester',
          name: 'Tester',
          contributionQuantity: request.initialContribution,
        ),
      ],
      messages: [],
      expiryDate: request.expiryDate,
      initialContribution: request.initialContribution,
    );
    myGroups.insert(0, created);
    openGroups.insert(0, created);
    return created;
  }

  @override
  Future<List<BuyingGroup>> getMyGroups({String? token}) async {
    return List.from(myGroups);
  }

  @override
  Future<List<BuyingGroup>> getGroups({
    String? category,
    String? status,
    String? token,
  }) async {
    return List.from(openGroups);
  }

  @override
  Future<BuyingGroup> getGroupById({
    required String groupId,
    String? token,
  }) async {
    lastFetchedDetailsGroupId = groupId;
    return openGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => myGroups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => BuyingGroup(
          id: groupId,
          name: 'Dynamic Group',
          productName: 'Dynamic Potato',
          category: 'vegetables',
          targetQuantity: 1000,
          filledQuantity: 100,
          pricePerKg: 25,
          deliveryLocation: 'Mirpur-10, Dhaka',
          createdBy: 'creator_1',
          members: [
            GroupMember(userId: 'creator_1', name: 'Creator', contributionQuantity: 100),
          ],
          messages: [],
          expiryDate: DateTime.now().add(const Duration(days: 10)),
        ),
      ),
    );
  }

  @override
  Future<BuyingGroup> joinGroup({
    required String groupId,
    required JoinGroupRequestModel request,
    String? token,
  }) async {
    lastJoinedGroupId = groupId;
    lastJoinRequest = request;
    final grp = await getGroupById(groupId: groupId);
    final updated = grp.copyWith(
      filledQuantity: grp.filledQuantity + request.quantity,
      members: [
        ...grp.members,
        GroupMember(
          userId: 'u_current',
          name: 'Current Buyer',
          contributionQuantity: request.quantity,
        ),
      ],
    );
    final idx = openGroups.indexWhere((g) => g.id == groupId);
    if (idx >= 0) openGroups[idx] = updated;
    final myIdx = myGroups.indexWhere((g) => g.id == groupId);
    if (myIdx >= 0) {
      myGroups[myIdx] = updated;
    } else {
      myGroups.add(updated);
    }
    return updated;
  }

  @override
  Future<bool> leaveGroup({
    required String groupId,
    String? token,
  }) async {
    lastLeftGroupId = groupId;
    myGroups.removeWhere((g) => g.id == groupId);
    return true;
  }

  Map<String, List<GroupMessage>> groupMessagesMap = {};
  String? lastFetchedMessagesGroupId;
  int? lastFetchedMessagesPage;
  int? lastFetchedMessagesLimit;
  String? lastSentMessageGroupId;
  String? lastSentMessageText;

  @override
  Future<List<GroupMessage>> getGroupMessages({
    required String groupId,
    int page = 1,
    int limit = 50,
    String? token,
  }) async {
    lastFetchedMessagesGroupId = groupId;
    lastFetchedMessagesPage = page;
    lastFetchedMessagesLimit = limit;
    return List.from(groupMessagesMap[groupId] ?? []);
  }

  @override
  Future<GroupMessage> sendGroupMessage({
    required String groupId,
    required String message,
    String? token,
  }) async {
    lastSentMessageGroupId = groupId;
    lastSentMessageText = message;
    final newMsg = GroupMessage(
      id: 'msg_test_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      senderId: 'u_tester',
      senderName: 'Tester',
      message: message,
      createdAt: DateTime.now(),
    );
    groupMessagesMap[groupId] = [...(groupMessagesMap[groupId] ?? []), newMsg];
    return newMsg;
  }
}

void main() {
  group('Buying Groups Request Models & JSON Verification', () {
    test('CreateGroupRequestModel outputs exact keys matching cURL specification', () {
      final expiry = DateTime.utc(2026, 12, 1, 18, 0, 0);
      final model = CreateGroupRequestModel(
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        expiryDate: expiry,
        initialContribution: 100,
      );

      final json = model.toJson();

      expect(json['name'], 'Dhaka Potato Bulk Buy');
      expect(json['productName'], 'Potatoes (Diamant)');
      expect(json['product_name'], 'Potatoes (Diamant)');
      expect(json['category'], 'vegetables');
      expect(json['targetQuantity'], 1000);
      expect(json['target_quantity'], 1000);
      expect(json['pricePerKg'], 25);
      expect(json['price_per_kg'], 25);
      expect(json['deliveryLocation'], 'Mirpur-10, Dhaka');
      expect(json['delivery_location'], 'Mirpur-10, Dhaka');
      expect(json['expiryDate'], '2026-12-01T18:00:00.000Z');
      expect(json['expiry_date'], '2026-12-01T18:00:00.000Z');
      expect(json['initialContribution'], 100);
      expect(json['initial_contribution'], 100);
    });

    test('JoinGroupRequestModel outputs exact keys matching join cURL specification', () {
      const model = JoinGroupRequestModel(quantity: 150);
      final json = model.toJson();

      expect(json['quantity'], 150);
      expect(json['contributionQuantity'], 150);
      expect(json['contribution_quantity'], 150);
    });

    test('BuyingGroup.fromJson correctly parses nested backend payload', () {
      final json = {
        'id': '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        'name': 'Dhaka Potato Bulk Buy',
        'product_name': 'Potatoes (Diamant)',
        'category': 'vegetables',
        'target_quantity': 1000,
        'filled_quantity': 100,
        'price_per_kg': 25,
        'delivery_location': 'Mirpur-10, Dhaka',
        'created_by': '395e2439-099f-41da-a739-019f5a08e504',
        'status': 'open',
        'expiry_date': '2026-12-01T18:00:00.000Z',
        'initial_contribution': 100,
        'members': [
          {
            'user_id': '395e2439-099f-41da-a739-019f5a08e504',
            'name': 'Buyer One',
            'contribution_quantity': 100,
            'is_paid': true,
          }
        ]
      };

      final group = BuyingGroup.fromJson(json);

      expect(group.id, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(group.name, 'Dhaka Potato Bulk Buy');
      expect(group.productName, 'Potatoes (Diamant)');
      expect(group.targetQuantity, 1000.0);
      expect(group.filledQuantity, 100.0);
      expect(group.pricePerKg, 25.0);
      expect(group.status, GroupBuyStatus.open);
      expect(group.members.length, 1);
      expect(group.members.first.name, 'Buyer One');
      expect(group.members.first.contributionQuantity, 100.0);
      expect(group.members.first.isPaid, true);
    });
  });

  group('GroupProvider State & Actions Tests', () {
    late MockGroupRepository mockRepo;
    late GroupProvider provider;

    setUp(() {
      mockRepo = MockGroupRepository();
      provider = GroupProvider(
        groupRepository: mockRepo,
        createGroupUseCase: CreateGroupUseCase(mockRepo),
        getMyGroupsUseCase: GetMyGroupsUseCase(mockRepo),
        getGroupsUseCase: GetGroupsUseCase(mockRepo),
        getGroupByIdUseCase: GetGroupByIdUseCase(mockRepo),
        joinGroupUseCase: JoinGroupUseCase(mockRepo),
        leaveGroupUseCase: LeaveGroupUseCase(mockRepo),
        getGroupMessagesUseCase: GetGroupMessagesUseCase(mockRepo),
        sendGroupMessageUseCase: SendGroupMessageUseCase(mockRepo),
      );
    });

    test('fetchGroupMessages calls repository with exact page and limit', () async {
      final sampleMessage = GroupMessage(
        id: 'msg_1',
        groupId: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        senderId: 'u1',
        senderName: 'John',
        message: 'Hello everyone! When are we finalizing our bulk order?',
        createdAt: DateTime.now(),
      );
      mockRepo.groupMessagesMap['66d1f893-cf97-4e66-97fa-54d2bcc69fac'] = [sampleMessage];

      final messages = await provider.fetchGroupMessages(
        '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        page: 1,
        limit: 50,
      );

      expect(mockRepo.lastFetchedMessagesGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(mockRepo.lastFetchedMessagesPage, 1);
      expect(mockRepo.lastFetchedMessagesLimit, 50);
      expect(messages.length, 1);
      expect(messages.first.message, 'Hello everyone! When are we finalizing our bulk order?');
    });

    test('sendGroupMessage calls repository with group id and message', () async {
      const msgText = 'Hello everyone! When are we finalizing our bulk order?';
      final sent = await provider.sendGroupMessage(
        '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        msgText,
      );

      expect(mockRepo.lastSentMessageGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(mockRepo.lastSentMessageText, msgText);
      expect(sent.message, msgText);
      expect(provider.getMessagesForGroup('66d1f893-cf97-4e66-97fa-54d2bcc69fac').length, 1);
    });

    test('createGroup creates group and immediately fetches myGroups', () async {
      final request = CreateGroupRequestModel(
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        expiryDate: DateTime.utc(2026, 12, 1, 18, 0, 0),
        initialContribution: 100,
      );

      final created = await provider.createGroup(request);

      expect(created.name, 'Dhaka Potato Bulk Buy');
      expect(mockRepo.lastCreateRequest?.name, 'Dhaka Potato Bulk Buy');
      expect(provider.myGroups.length, 1);
      expect(provider.myGroups.first.name, 'Dhaka Potato Bulk Buy');
    });

    test('joinGroup calls repository and updates membership', () async {
      final initial = BuyingGroup(
        id: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        filledQuantity: 100,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        createdBy: 'creator_1',
        members: [
          GroupMember(userId: 'creator_1', name: 'Creator', contributionQuantity: 100),
        ],
        messages: [],
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );
      mockRepo.openGroups = [initial];

      const joinRequest = JoinGroupRequestModel(quantity: 150);
      final updated = await provider.joinGroup('66d1f893-cf97-4e66-97fa-54d2bcc69fac', joinRequest);

      expect(mockRepo.lastJoinedGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(mockRepo.lastJoinRequest?.quantity, 150);
      expect(updated.filledQuantity, 250);
      expect(updated.members.length, 2);
    });

    test('leaveGroup removes group from myGroups', () async {
      final initial = BuyingGroup(
        id: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        filledQuantity: 250,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        createdBy: 'creator_1',
        members: [
          GroupMember(userId: 'creator_1', name: 'Creator', contributionQuantity: 100),
          GroupMember(userId: 'u_current', name: 'Current Buyer', contributionQuantity: 150),
        ],
        messages: [],
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );
      mockRepo.myGroups = [initial];
      provider.setGroups([initial]);

      final success = await provider.leaveGroup('66d1f893-cf97-4e66-97fa-54d2bcc69fac');

      expect(success, true);
      expect(mockRepo.lastLeftGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(provider.myGroups.any((g) => g.id == '66d1f893-cf97-4e66-97fa-54d2bcc69fac'), false);
    });
  });

  group('GroupsListScreen & GroupDetailScreen Widget Tests', () {
    late MockGroupRepository mockRepo;
    late GroupProvider groupProvider;
    late AuthProvider authProvider;
    late AppStateProvider appStateProvider;

    setUp(() {
      mockRepo = MockGroupRepository();
      groupProvider = GroupProvider(
        groupRepository: mockRepo,
        createGroupUseCase: CreateGroupUseCase(mockRepo),
        getMyGroupsUseCase: GetMyGroupsUseCase(mockRepo),
        getGroupsUseCase: GetGroupsUseCase(mockRepo),
        getGroupByIdUseCase: GetGroupByIdUseCase(mockRepo),
        joinGroupUseCase: JoinGroupUseCase(mockRepo),
        leaveGroupUseCase: LeaveGroupUseCase(mockRepo),
        getGroupMessagesUseCase: GetGroupMessagesUseCase(mockRepo),
        sendGroupMessageUseCase: SendGroupMessageUseCase(mockRepo),
      );
      authProvider = AuthProvider();
      appStateProvider = AppStateProvider();
    });

    testWidgets('Renders GroupsListScreen empty state without any dummy data', (tester) async {
      mockRepo.openGroups = [];
      mockRepo.myGroups = [];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: groupProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: GroupsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buying Groups'), findsOneWidget);
      expect(find.text('cURL v1 API'), findsOneWidget);
      expect(find.text('POST /groups  •  GET /groups/my'), findsOneWidget);
      expect(find.text('No Open Groups Available'), findsOneWidget);
      expect(find.text('Create Buying Group'), findsWidgets);
    });

    testWidgets('Renders open buying group cards with stats and progress', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleGroup = BuyingGroup(
        id: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        filledQuantity: 100,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        createdBy: 'user_other',
        members: [
          GroupMember(userId: 'user_other', name: 'Originator', contributionQuantity: 100),
        ],
        messages: [],
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      mockRepo.openGroups = [sampleGroup];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: groupProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: GroupsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dhaka Potato Bulk Buy'), findsOneWidget);
      expect(find.text('Potatoes (Diamant)'), findsOneWidget);
      expect(find.text('100 / 1000 KG filled'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('৳25/KG'), findsOneWidget);
      expect(find.text('Mirpur-10, Dhaka'), findsOneWidget);
    });

    testWidgets('GroupDetailScreen shows join button, allows filling 150 KG sample preset and joins', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleGroup = BuyingGroup(
        id: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        filledQuantity: 100,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        createdBy: 'user_creator',
        members: [
          GroupMember(userId: 'user_creator', name: 'Leader', contributionQuantity: 100),
        ],
        messages: [],
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      mockRepo.openGroups = [sampleGroup];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: groupProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: '66d1f893-cf97-4e66-97fa-54d2bcc69fac'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dhaka Potato Bulk Buy'), findsOneWidget);
      expect(find.text('Join Buying Group (cURL POST)'), findsOneWidget);

      // Tap Join button
      await tester.tap(find.text('Join Buying Group (cURL POST)'));
      await tester.pumpAndSettle();

      // Verify dialog opened with preset chip
      expect(find.text('⚡ Fill 150 KG (cURL Sample)'), findsOneWidget);

      // Tap preset chip
      await tester.tap(find.text('⚡ Fill 150 KG (cURL Sample)'));
      await tester.pumpAndSettle();

      // Tap Confirm Join
      await tester.tap(find.text('Confirm Join (cURL POST)'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastJoinedGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(mockRepo.lastJoinRequest?.quantity, 150);
    });

    testWidgets('GroupDetailScreen shows leave button when user is a member', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleGroup = BuyingGroup(
        id: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        filledQuantity: 250,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        createdBy: 'user_creator',
        members: [
          GroupMember(userId: 'user_creator', name: 'Leader', contributionQuantity: 100),
          GroupMember(userId: 'u_test_user', name: 'Test User', contributionQuantity: 150),
        ],
        messages: [],
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      mockRepo.openGroups = [sampleGroup];
      mockRepo.myGroups = [sampleGroup];

      // Current user is member
      authProvider.setCurrentUser(
        AppUser(
          id: 'u_test_user',
          name: 'Test User',
          phone: '01407070311',
          role: UserRole.buyer,
          isVerified: true,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: groupProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: '66d1f893-cf97-4e66-97fa-54d2bcc69fac'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You are a pool member'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      // Tap Leave button
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(find.text('Leave Buying Group'), findsOneWidget);
      expect(find.text('Confirm Leave (cURL DELETE)'), findsOneWidget);

      // Confirm Leave
      await tester.tap(find.text('Confirm Leave (cURL DELETE)'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastLeftGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
    });

    testWidgets('GroupDetailScreen chat tab fetches messages, displays preset chip, and sends message', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleGroup = BuyingGroup(
        id: '66d1f893-cf97-4e66-97fa-54d2bcc69fac',
        name: 'Dhaka Potato Bulk Buy',
        productName: 'Potatoes (Diamant)',
        category: 'vegetables',
        targetQuantity: 1000,
        filledQuantity: 250,
        pricePerKg: 25,
        deliveryLocation: 'Mirpur-10, Dhaka',
        createdBy: 'user_creator',
        members: [
          GroupMember(userId: 'user_creator', name: 'Leader', contributionQuantity: 100),
          GroupMember(userId: 'u_test_user', name: 'Test User', contributionQuantity: 150),
        ],
        messages: [],
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      mockRepo.openGroups = [sampleGroup];
      mockRepo.myGroups = [sampleGroup];

      authProvider.setCurrentUser(
        AppUser(
          id: 'u_test_user',
          name: 'Test User',
          phone: '01407070311',
          role: UserRole.buyer,
          isVerified: true,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: groupProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: '66d1f893-cf97-4e66-97fa-54d2bcc69fac'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Chat Tab
      await tester.tap(find.textContaining('Chat'));
      await tester.pumpAndSettle();

      // Check cURL banner and preset chip
      expect(find.textContaining('/messages?page=1&limit=50'), findsOneWidget);
      expect(find.textContaining('Hello everyone! When are we finalizing our bulk order?'), findsOneWidget);

      // Tap preset chip and send
      await tester.tap(find.textContaining('Hello everyone! When are we finalizing our bulk order?'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify message was sent
      expect(mockRepo.lastSentMessageGroupId, '66d1f893-cf97-4e66-97fa-54d2bcc69fac');
      expect(mockRepo.lastSentMessageText, 'Hello everyone! When are we finalizing our bulk order?');
    });
  });
}
