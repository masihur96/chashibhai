import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<UserEntity> call({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    return await repository.updateProfile(token: token, data: data);
  }
}
