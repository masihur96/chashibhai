import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_notifications_unread_count_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetNotificationsUnreadCountUseCase _getNotificationsUnreadCountUseCase;
  final MarkNotificationAsReadUseCase _markNotificationAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase _markAllNotificationsAsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;

  /// Default cURL bearer token for notifications
  static const String defaultNotificationToken =
      NotificationRemoteDataSourceImpl.defaultFallbackToken;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _unreadCount = 0;
  bool _isLoadingUnreadCount = false;

  // Active filters matching user cURL defaults
  int _page = 1;
  final int _limit = 20;
  bool? _filterIsRead = true; // default true matching cURL
  String _filterType = 'all'; // default 'all' matching cURL

  bool _isMarkingRead = false;
  bool _isDeleting = false;

  NotificationProvider({
    NotificationRepository? repository,
    GetNotificationsUseCase? getNotificationsUseCase,
    GetNotificationsUnreadCountUseCase? getNotificationsUnreadCountUseCase,
    MarkNotificationAsReadUseCase? markNotificationAsReadUseCase,
    MarkAllNotificationsAsReadUseCase? markAllNotificationsAsReadUseCase,
    DeleteNotificationUseCase? deleteNotificationUseCase,
  })  : _repository = repository ?? NotificationRepositoryImpl(),
        _getNotificationsUseCase = getNotificationsUseCase ??
            GetNotificationsUseCase(repository ?? NotificationRepositoryImpl()),
        _getNotificationsUnreadCountUseCase = getNotificationsUnreadCountUseCase ??
            GetNotificationsUnreadCountUseCase(repository ?? NotificationRepositoryImpl()),
        _markNotificationAsReadUseCase = markNotificationAsReadUseCase ??
            MarkNotificationAsReadUseCase(repository ?? NotificationRepositoryImpl()),
        _markAllNotificationsAsReadUseCase = markAllNotificationsAsReadUseCase ??
            MarkAllNotificationsAsReadUseCase(repository ?? NotificationRepositoryImpl()),
        _deleteNotificationUseCase = deleteNotificationUseCase ??
            DeleteNotificationUseCase(repository ?? NotificationRepositoryImpl());

  // Getters
  NotificationRepository get repository => _repository;
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _unreadCount > 0
      ? _unreadCount
      : _notifications.where((n) => !n.isRead).length;
  bool get isLoadingUnreadCount => _isLoadingUnreadCount;

  int get page => _page;
  int get limit => _limit;
  bool? get filterIsRead => _filterIsRead;
  String get filterType => _filterType;
  bool get isMarkingRead => _isMarkingRead;
  bool get isDeleting => _isDeleting;

  /// Returns the current active cURL URL string for UI display / transparency
  String get currentCurlQueryString {
    final params = <String>[
      'page=$_page',
      'limit=$_limit',
    ];
    if (_filterIsRead != null) {
      params.add('isRead=$_filterIsRead');
    }
    if (_filterType.isNotEmpty) {
      params.add('type=$_filterType');
    }
    return '/api/v1/notifications?${params.join('&')}';
  }

  void setFilterIsRead(bool? value) {
    if (_filterIsRead == value) return;
    _filterIsRead = value;
    _page = 1;
    notifyListeners();
    fetchNotifications();
  }

  void setFilterType(String type) {
    if (_filterType == type) return;
    _filterType = type;
    _page = 1;
    notifyListeners();
    fetchNotifications();
  }

  void resetFilters() {
    _filterIsRead = true;
    _filterType = 'all';
    _page = 1;
    notifyListeners();
    fetchNotifications();
  }

  /// Sets notifications directly (useful for tests and mocks)
  void setNotifications(List<AppNotification> list) {
    _notifications = list;
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  /// Sets unread count directly (useful for tests and mocks)
  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  /// Fetches unread count using GET /api/v1/notifications/unread-count
  Future<int> fetchUnreadCount({String? token}) async {
    _isLoadingUnreadCount = true;
    notifyListeners();

    try {
      final count = await _getNotificationsUnreadCountUseCase(
        token: token ?? defaultNotificationToken,
      );
      _unreadCount = count;
      return _unreadCount;
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION_PROVIDER] fetchUnreadCount error: $e');
      return _unreadCount;
    } finally {
      _isLoadingUnreadCount = false;
      notifyListeners();
    }
  }

  /// Fetches notifications using GET /api/v1/notifications?page=1&limit=20&isRead=true&type=all
  Future<List<AppNotification>> fetchNotifications({
    int? page,
    int? limit,
    bool? isRead,
    String? type,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final targetPage = page ?? _page;
    final targetLimit = limit ?? _limit;
    final targetIsRead = isRead ?? _filterIsRead;
    final targetType = type ?? _filterType;

    try {
      final list = await _getNotificationsUseCase(
        page: targetPage,
        limit: targetLimit,
        isRead: targetIsRead,
        type: targetType,
        token: token ?? defaultNotificationToken,
      );

      _notifications = list;

      // Silently fetch server unread-count as well
      try {
        fetchUnreadCount(token: token);
      } catch (_) {}

      return _notifications;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('⚠️ [NOTIFICATION_PROVIDER] fetchNotifications error: $e');
      return _notifications;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a specific notification as read using PATCH /api/v1/notifications/:id/read
  Future<void> markAsRead(String notificationId, {String? token}) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      await _markNotificationAsReadUseCase(
        notificationId: notificationId,
        token: token ?? defaultNotificationToken,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION_PROVIDER] markAsRead error: $e');
    }
  }

  /// Marks all notifications as read using PATCH /api/v1/notifications/read-all
  Future<void> markAllAsRead({String? token}) async {
    _isMarkingRead = true;
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _markAllNotificationsAsReadUseCase(
        token: token ?? defaultNotificationToken,
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION_PROVIDER] markAllAsRead error: $e');
    } finally {
      _isMarkingRead = false;
      notifyListeners();
    }
  }

  /// Deletes a specific notification using DELETE /api/v1/notifications/:id
  Future<bool> deleteNotification(String notificationId, {String? token}) async {
    _isDeleting = true;
    notifyListeners();

    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    AppNotification? removed;
    if (idx >= 0) {
      removed = _notifications.removeAt(idx);
      if (!removed.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    }

    try {
      final success = await _deleteNotificationUseCase(
        notificationId: notificationId,
        token: token ?? defaultNotificationToken,
      );
      return success;
    } catch (e) {
      // Revert if failed
      if (removed != null && idx >= 0) {
        _notifications.insert(idx, removed);
        if (!removed.isRead) _unreadCount++;
        notifyListeners();
      }
      debugPrint('⚠️ [NOTIFICATION_PROVIDER] deleteNotification error: $e');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
