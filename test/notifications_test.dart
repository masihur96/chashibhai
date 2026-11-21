import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/notification/domain/repositories/notification_repository.dart';
import 'package:chashibhai/features/notification/domain/usecases/get_notifications_usecase.dart';
import 'package:chashibhai/features/notification/domain/usecases/mark_all_notifications_as_read_usecase.dart';
import 'package:chashibhai/features/notification/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:chashibhai/features/notification/presentation/state/notification_provider.dart';
import 'package:chashibhai/features/notification/presentation/views/notification_screen.dart';

class MockNotificationRepository implements NotificationRepository {
  List<AppNotification> notifications = [];
  int? lastFetchedPage;
  int? lastFetchedLimit;
  bool? lastFetchedIsRead;
  String? lastFetchedType;
  String? lastFetchedToken;
  String? lastMarkedReadId;
  bool didMarkAllRead = false;

  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? token,
  }) async {
    lastFetchedPage = page;
    lastFetchedLimit = limit;
    lastFetchedIsRead = isRead;
    lastFetchedType = type;
    lastFetchedToken = token;

    var filtered = List<AppNotification>.from(notifications);
    if (isRead != null) {
      filtered = filtered.where((n) => n.isRead == isRead).toList();
    }
    if (type != null && type != 'all') {
      filtered = filtered.where((n) => n.type.name == type || n.typeString == type).toList();
    }
    return filtered;
  }

  @override
  Future<bool> markAsRead({
    required String notificationId,
    String? token,
  }) async {
    lastMarkedReadId = notificationId;
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
    }
    return true;
  }

  @override
  Future<bool> markAllAsRead({String? token}) async {
    didMarkAllRead = true;
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    return true;
  }
}

void main() {
  group('AppNotification Model Parsing & JSON Tests', () {
    test('AppNotification.fromJson parses backend cURL payload correctly', () {
      final json = {
        'id': 'notif_curl_101',
        'title': 'Demand Offer Accepted',
        'message': 'Your bulk demand for Potatoes (Diamant) received 3 new farmer bids.',
        'createdAt': '2026-11-21T12:00:00.000Z',
        'type': 'demand',
        'isRead': true,
        'data': {'demandId': 'dem_123', 'offersCount': 3},
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif_curl_101');
      expect(notif.title, 'Demand Offer Accepted');
      expect(notif.message, 'Your bulk demand for Potatoes (Diamant) received 3 new farmer bids.');
      expect(notif.type, NotificationType.demand);
      expect(notif.isRead, true);
      expect(notif.typeString, 'demand');
      expect(notif.data?['demandId'], 'dem_123');
    });

    test('AppNotification.fromJson handles alternative keys and defaults', () {
      final json = {
        'id': 'notif_2',
        'body': 'Delivery of Order #ORD-456 confirmed by driver.',
        'created_at': '2026-11-21T15:30:00.000Z',
        'type': 'order',
        'is_read': false,
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif_2');
      expect(notif.message, 'Delivery of Order #ORD-456 confirmed by driver.');
      expect(notif.type, NotificationType.order);
      expect(notif.isRead, false);
    });
  });

  group('NotificationProvider State & Query Tests', () {
    late MockNotificationRepository mockRepo;
    late NotificationProvider provider;

    setUp(() {
      mockRepo = MockNotificationRepository();
      provider = NotificationProvider(
        repository: mockRepo,
        getNotificationsUseCase: GetNotificationsUseCase(mockRepo),
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase(mockRepo),
        markAllNotificationsAsReadUseCase: MarkAllNotificationsAsReadUseCase(mockRepo),
      );
    });

    test('Initial cURL query matches user curl specification', () {
      expect(provider.page, 1);
      expect(provider.limit, 20);
      expect(provider.filterIsRead, true);
      expect(provider.filterType, 'all');
      expect(
        provider.currentCurlQueryString,
        '/api/v1/notifications?page=1&limit=20&isRead=true&type=all',
      );
    });

    test('fetchNotifications calls repository with exact cURL query params', () async {
      final sample = AppNotification(
        id: 'n1',
        title: 'Wholesale Bid Received',
        message: 'Farmer Kamal bid ৳24/KG on Potato pool.',
        createdAt: DateTime.now(),
        type: NotificationType.bid,
        isRead: true,
      );
      mockRepo.notifications = [sample];

      final result = await provider.fetchNotifications();

      expect(mockRepo.lastFetchedPage, 1);
      expect(mockRepo.lastFetchedLimit, 20);
      expect(mockRepo.lastFetchedIsRead, true);
      expect(mockRepo.lastFetchedType, 'all');
      expect(result.length, 1);
      expect(result.first.id, 'n1');
    });

    test('Filter changes update query string and trigger fetch', () async {
      provider.setFilterIsRead(false);
      expect(provider.filterIsRead, false);
      expect(mockRepo.lastFetchedIsRead, false);
      expect(
        provider.currentCurlQueryString,
        '/api/v1/notifications?page=1&limit=20&isRead=false&type=all',
      );

      provider.setFilterType('demand');
      expect(provider.filterType, 'demand');
      expect(mockRepo.lastFetchedType, 'demand');
      expect(
        provider.currentCurlQueryString,
        '/api/v1/notifications?page=1&limit=20&isRead=false&type=demand',
      );

      provider.resetFilters();
      expect(provider.filterIsRead, true);
      expect(provider.filterType, 'all');
      expect(
        provider.currentCurlQueryString,
        '/api/v1/notifications?page=1&limit=20&isRead=true&type=all',
      );
    });

    test('markAsRead updates item state locally and notifies repository', () async {
      final sample = AppNotification(
        id: 'n_unread',
        title: 'New Group Pool Created',
        message: 'Dhaka Potato Bulk Buy is open.',
        createdAt: DateTime.now(),
        type: NotificationType.group,
        isRead: false,
      );
      mockRepo.notifications = [sample];
      provider.setNotifications([sample]);

      expect(provider.unreadCount, 1);

      await provider.markAsRead('n_unread');

      expect(mockRepo.lastMarkedReadId, 'n_unread');
      expect(provider.notifications.first.isRead, true);
      expect(provider.unreadCount, 0);
    });

    test('markAllAsRead marks all notifications as read', () async {
      final n1 = AppNotification(
        id: 'n1',
        title: 'Title 1',
        message: 'Message 1',
        createdAt: DateTime.now(),
        type: NotificationType.order,
        isRead: false,
      );
      final n2 = AppNotification(
        id: 'n2',
        title: 'Title 2',
        message: 'Message 2',
        createdAt: DateTime.now(),
        type: NotificationType.payment,
        isRead: false,
      );
      mockRepo.notifications = [n1, n2];
      provider.setNotifications([n1, n2]);

      expect(provider.unreadCount, 2);

      await provider.markAllAsRead();

      expect(mockRepo.didMarkAllRead, true);
      expect(provider.notifications.every((n) => n.isRead), true);
      expect(provider.unreadCount, 0);
    });
  });

  group('NotificationScreen Widget Tests', () {
    late MockNotificationRepository mockRepo;
    late NotificationProvider notificationProvider;
    late AuthProvider authProvider;
    late AppStateProvider appStateProvider;

    setUp(() {
      mockRepo = MockNotificationRepository();
      notificationProvider = NotificationProvider(
        repository: mockRepo,
        getNotificationsUseCase: GetNotificationsUseCase(mockRepo),
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase(mockRepo),
        markAllNotificationsAsReadUseCase: MarkAllNotificationsAsReadUseCase(mockRepo),
      );
      authProvider = AuthProvider();
      appStateProvider = AppStateProvider();
    });

    testWidgets('Renders NotificationScreen empty state without any dummy data', (tester) async {
      mockRepo.notifications = [];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: notificationProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: NotificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('GET http://localhost:3000/api/v1/notifications'), findsOneWidget);
      expect(find.text('Read (cURL)'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
      expect(find.text('No Notifications Found'), findsOneWidget);
      expect(find.text('Reset Filters (cURL Default)'), findsOneWidget);
    });

    testWidgets('Renders notifications list and filters interactively', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final nRead = AppNotification(
        id: 'n_read',
        title: 'Wholesale Offer Accepted',
        message: 'Your bulk offer for Potato Diamant was accepted by Farmer Rahim.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        type: NotificationType.bid,
        isRead: true,
      );

      final nUnread = AppNotification(
        id: 'n_unread',
        title: 'New Demand Order Created',
        message: 'Pool order #DEM-888 has reached 1000 KG.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.demand,
        isRead: false,
      );

      mockRepo.notifications = [nRead, nUnread];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: notificationProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: NotificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // By default isRead=true matching cURL specification
      expect(find.text('Wholesale Offer Accepted'), findsOneWidget);
      expect(find.text('READ'), findsOneWidget);

      // Switch to Unread tab
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      expect(find.text('New Demand Order Created'), findsOneWidget);
      expect(find.text('UNREAD'), findsOneWidget);

      // Tap on the notification card to open detail bottom sheet
      await tester.tap(find.text('New Demand Order Created'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });
}
