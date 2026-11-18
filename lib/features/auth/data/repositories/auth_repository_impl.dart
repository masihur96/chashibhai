import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_model.dart';
import '../models/refresh_token_request_model.dart';
import '../models/register_request_model.dart';
import '../models/token_model.dart';

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
  Future<UserEntity> login({
    required String phone,
    required String password,
  }) async {
    final request = LoginRequestModel(
      phone: phone,
      password: password,
    );
    return await remoteDataSource.login(request);
  }

  @override
  Future<UserEntity> getMe(String token) async {
    return await remoteDataSource.getMe(token);
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    final request = RefreshTokenRequestModel(refreshToken: refreshToken);
    return await remoteDataSource.refreshToken(request);
  }

  @override
  Future<UserEntity?> getProfile(String userId) async {
    return null;
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return true;
  }

  @override
  Future<void> logout() async {
    // Logout logic
  }
}
