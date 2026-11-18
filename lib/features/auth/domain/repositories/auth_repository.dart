import '../../data/models/token_model.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  });
  Future<UserEntity> login({
    required String phone,
    required String password,
  });
  Future<UserEntity> getMe(String token);
  Future<TokenModel> refreshToken(String refreshToken);
  Future<UserEntity?> getProfile(String userId);
  Future<bool> changePassword(String oldPassword, String newPassword);
  Future<void> logout();
}
