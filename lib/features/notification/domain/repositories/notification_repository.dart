import '../../../../core/models/models.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? token,
  });

  Future<bool> markAsRead({
    required String notificationId,
    String? token,
  });

  Future<bool> markAllAsRead({
    String? token,
  });
}
