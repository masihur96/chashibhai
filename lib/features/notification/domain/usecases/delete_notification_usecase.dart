import '../repositories/notification_repository.dart';

class DeleteNotificationUseCase {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  Future<bool> call({
    required String notificationId,
    String? token,
  }) {
    return repository.deleteNotification(
      notificationId: notificationId,
      token: token,
    );
  }
}
