import '../../../../core/models/models.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<AppNotification>> call({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? token,
  }) {
    return repository.getNotifications(
      page: page,
      limit: limit,
      isRead: isRead,
      type: type,
      token: token,
    );
  }
}
