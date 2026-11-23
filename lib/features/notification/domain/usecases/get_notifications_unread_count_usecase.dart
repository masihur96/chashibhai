import '../repositories/notification_repository.dart';

class GetNotificationsUnreadCountUseCase {
  final NotificationRepository repository;

  GetNotificationsUnreadCountUseCase(this.repository);

  Future<int> call({String? token}) {
    return repository.getUnreadCount(token: token);
  }
}
