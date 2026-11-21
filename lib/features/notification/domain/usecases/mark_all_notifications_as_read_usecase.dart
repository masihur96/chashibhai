import '../repositories/notification_repository.dart';

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository repository;

  MarkAllNotificationsAsReadUseCase(this.repository);

  Future<bool> call({
    String? token,
  }) {
    return repository.markAllAsRead(
      token: token,
    );
  }
}
