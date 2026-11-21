import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationAsReadUseCase _markNotificationAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase _markAllNotificationsAsReadUseCase;

  /// Default cURL bearer token for notifications
  static const String defaultNotificationToken =
      NotificationRemoteDataSourceImpl.defaultFallbackToken;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Active filters matching user cURL defaults
  int _page = 1;
  final int _limit = 20;
  bool? _filterIsRead = true; // default true matching cURL
  String _filterType = 'all'; // default 'all' matching cURL

  bool _isMarkingRead = false;

  NotificationProvider({
    NotificationRepository? repository,
    GetNotificationsUseCase? getNotificationsUseCase,
    MarkNotificationAsReadUseCase? markNotificationAsReadUseCase,
    MarkAllNotificationsAsReadUseCase? markAllNotificationsAsReadUseCase,
  })  : _repository = repository ?? NotificationRepositoryImpl(),
        _getNotificationsUseCase = getNotificationsUseCase ??
            GetNotificationsUseCase(repository ?? NotificationRepositoryImpl()),
        _markNotificationAsReadUseCase = markNotificationAsReadUseCase ??
            MarkNotificationAsReadUseCase(repository ?? NotificationRepositoryImpl()),
        _markAllNotificationsAsReadUseCase = markAllNotificationsAsReadUseCase ??
            MarkAllNotificationsAsReadUseCase(repository ?? NotificationRepositoryImpl());

  // Getters
  NotificationRepository get repository => _repository;
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get page => _page;
  int get limit => _limit;
  bool? get filterIsRead => _filterIsRead;
  String get filterType => _filterType;
  bool get isMarkingRead => _isMarkingRead;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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
    notifyListeners();
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

  /// Marks a single notification as read
  Future<void> markAsRead(String notificationId, {String? token}) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
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

  /// Marks all notifications as read
  Future<void> markAllAsRead({String? token}) async {
    _isMarkingRead = true;
    notifyListeners();

    // Locally mark all as read immediately for snappy UI
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
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
}
