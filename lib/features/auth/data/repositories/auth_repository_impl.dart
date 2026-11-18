import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/register_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl();

  @override
  Future<UserEntity> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    final request = RegisterRequestModel(
      name: name,
      phone: phone,
      password: password,
      role: role,
    );
    return await remoteDataSource.register(request);
  }

  @override
  Future<UserEntity?> login(String emailOrPhone, String password) async {
    // Placeholder login implementation
    return null;
  }

  @override
  Future<UserEntity?> getProfile(String userId) async {
    // Placeholder getProfile implementation
    return null;
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return true;
  }

  @override
  Future<void> logout() async {
    // Placeholder logout implementation
  }
}
