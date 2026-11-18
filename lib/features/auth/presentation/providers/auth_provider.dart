import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/models/models.dart';
import '../../../../core/utils/storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _biometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Loading, token and error state
  bool _isLoading = false;
  String? _errorMessage;
  String? _token; // Access Token
  String? _refreshToken; // Refresh Token
  UserEntity? _registeredUser;

  final RegisterUseCase _registerUseCase;
  final LoginUseCase _loginUseCase;
  final GetMeUseCase _getMeUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;

  AuthProvider({
    RegisterUseCase? registerUseCase,
    LoginUseCase? loginUseCase,
    GetMeUseCase? getMeUseCase,
    RefreshTokenUseCase? refreshTokenUseCase,
  }) : _registerUseCase =
           registerUseCase ?? RegisterUseCase(AuthRepositoryImpl()),
       _loginUseCase = loginUseCase ?? LoginUseCase(AuthRepositoryImpl()),
       _getMeUseCase = getMeUseCase ?? GetMeUseCase(AuthRepositoryImpl()),
       _refreshTokenUseCase =
           refreshTokenUseCase ?? RefreshTokenUseCase(AuthRepositoryImpl());

  // Getters
  AppUser? get currentUser => _currentUser;
  UserRole get userRole => _currentUser?.role ?? UserRole.buyer;
  double get walletBalance => _currentUser?.walletBalance ?? 0.0;
  bool get biometricEnabled => _biometricEnabled;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  UserEntity? get registeredUser => _registeredUser;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setCurrentUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setBiometricEnabled(bool enabled) {
    _biometricEnabled = enabled;
    notifyListeners();
  }

  /// Helper to convert UserEntity to AppUser
  AppUser _mapUserEntityToAppUser(UserEntity user) {
    UserRole mappedRole = UserRole.buyer;
    final r = user.role.toUpperCase();
    if (r == 'FARMER') {
      mappedRole = UserRole.farmer;
    } else if (r == 'ADMIN' || r == 'SUPER_ADMIN') {
      mappedRole = UserRole.admin;
    }

    return AppUser(
      id: user.id ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: user.name.isNotEmpty ? user.name : 'User',
      phone: user.phone,
      role: mappedRole,
    );
  }

  /// Generates a new access token using the stored refresh token via POST /api/v1/auth/refresh
  Future<String?> refreshAccessToken() async {
    final tokenToRefresh =
        _refreshToken ?? await StorageService().getString('refresh_token');

    if (tokenToRefresh == null || tokenToRefresh.isEmpty) {
      debugPrint('No refresh token available to generate new access token.');
      return null;
    }

    try {
      debugPrint('Refreshing access token via POST /api/v1/auth/refresh...');
      final tokenModel = await _refreshTokenUseCase(tokenToRefresh);

      _token = tokenModel.accessToken;
      await StorageService().setString('auth_token', tokenModel.accessToken);

      if (tokenModel.refreshToken != null &&
          tokenModel.refreshToken!.isNotEmpty) {
        _refreshToken = tokenModel.refreshToken;
        await StorageService().setString(
          'refresh_token',
          tokenModel.refreshToken!,
        );
      }

      debugPrint('Access token refreshed successfully.');
      notifyListeners();
      return _token;
    } catch (e) {
      debugPrint('Error refreshing access token: $e');
      // If refresh token is expired or invalid, clear stored session
      if (e is TokenExpiredException ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        await logout();
      }
      return null;
    }
  }

  /// Fetches current user profile from GET /api/v1/auth/me using access token.
  /// If the access token is expired (HTTP 401), automatically generates a new
  /// access token via /auth/refresh and retries the request seamlessly!
  Future<UserEntity?> fetchCurrentUser(String accessToken) async {
    try {
      final meUser = await _getMeUseCase(accessToken);
      _token = accessToken;
      await StorageService().setString('auth_token', accessToken);
      _currentUser = _mapUserEntityToAppUser(meUser);
      notifyListeners();
      return meUser;
    } on TokenExpiredException catch (_) {
      debugPrint(
        'Access token expired on /auth/me. Attempting token refresh...',
      );
      // Generate new access token using refresh token
      final newAccessToken = await refreshAccessToken();
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        try {
          debugPrint('Retrying /auth/me with newly generated access token...');
          final retriedUser = await _getMeUseCase(newAccessToken);
          _currentUser = _mapUserEntityToAppUser(retriedUser);
          notifyListeners();
          return retriedUser;
        } catch (retryError) {
          debugPrint('Failed /auth/me after token refresh: $retryError');
          return null;
        }
      }
      return null;
    } catch (e) {
      // Check if general exception message indicates unauthorized / 401
      if (e.toString().contains('401') ||
          e.toString().toLowerCase().contains('unauthorized')) {
        debugPrint('401 detected on /auth/me. Attempting token refresh...');
        final newAccessToken = await refreshAccessToken();
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          try {
            final retriedUser = await _getMeUseCase(newAccessToken);
            _currentUser = _mapUserEntityToAppUser(retriedUser);
            notifyListeners();
            return retriedUser;
          } catch (_) {
            return null;
          }
        }
      }
      debugPrint('Error fetching /auth/me: $e');
      return null;
    }
  }

  /// Logs in a user with phone and password via API, stores access & refresh tokens,
  /// then immediately fetches current user via GET /auth/me with access token.
  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginUser = await _loginUseCase(phone: phone, password: password);

      final authToken = loginUser.token;
      final refToken = loginUser.refreshToken;

      if (refToken != null && refToken.isNotEmpty) {
        _refreshToken = refToken;
        await StorageService().setString('refresh_token', refToken);
      }

      if (authToken != null && authToken.isNotEmpty) {
        _token = authToken;
        await StorageService().setString('auth_token', authToken);

        // Fetch current user via /auth/me using the access token
        final meUser = await fetchCurrentUser(authToken);
        if (meUser == null) {
          _currentUser = _mapUserEntityToAppUser(loginUser);
        }
      } else {
        _currentUser = _mapUserEntityToAppUser(loginUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user with the backend API, stores access & refresh tokens,
  /// then fetches current user via GET /auth/me with access token.
  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final regUser = await _registerUseCase(
        name: name,
        phone: phone,
        password: password,
        role: role,
      );

      _registeredUser = regUser;

      final authToken = regUser.token;
      final refToken = regUser.refreshToken;

      if (refToken != null && refToken.isNotEmpty) {
        _refreshToken = refToken;
        await StorageService().setString('refresh_token', refToken);
      }

      if (authToken != null && authToken.isNotEmpty) {
        _token = authToken;
        await StorageService().setString('auth_token', authToken);

        // Fetch current user via /auth/me using the access token
        final meUser = await fetchCurrentUser(authToken);
        if (meUser == null) {
          _currentUser = _mapUserEntityToAppUser(regUser);
        }
      } else {
        _currentUser = _mapUserEntityToAppUser(regUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears user session and tokens
  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    await StorageService().remove('auth_token');
    await StorageService().remove('refresh_token');
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics(String appLocale) async {
    final authDesc = appLocale == 'bn'
        ? 'বায়োমেট্রিক ব্যবহার করে লগইন করুন'
        : 'Login using biometrics';

    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _localAuth.authenticate(
        localizedReason: authDesc,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
