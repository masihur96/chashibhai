import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  });
  Future<UserEntity?> login(String emailOrPhone, String password);
  Future<UserEntity?> getProfile(String userId);
  Future<bool> changePassword(String oldPassword, String newPassword);
  Future<void> logout();
}
