import '../repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<bool> call({
    required String notificationId,
    String? token,
  }) {
    return repository.markAsRead(
      notificationId: notificationId,
      token: token,
    );
  }
}
