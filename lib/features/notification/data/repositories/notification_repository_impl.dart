import '../../../../core/models/models.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({NotificationRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? NotificationRemoteDataSourceImpl();

  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? token,
  }) {
    return _remoteDataSource.getNotifications(
      page: page,
      limit: limit,
      isRead: isRead,
      type: type,
      token: token,
    );
  }

  @override
  Future<bool> markAsRead({
    required String notificationId,
    String? token,
  }) {
    return _remoteDataSource.markAsRead(
      notificationId: notificationId,
      token: token,
    );
  }

  @override
  Future<bool> markAllAsRead({
    String? token,
  }) {
    return _remoteDataSource.markAllAsRead(
      token: token,
    );
  }
}
