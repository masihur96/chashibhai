import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/models/models.dart';
import '../../../../core/utils/storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

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
  final LogoutUseCase _logoutUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  AuthProvider({
    RegisterUseCase? registerUseCase,
    LoginUseCase? loginUseCase,
    GetMeUseCase? getMeUseCase,
    RefreshTokenUseCase? refreshTokenUseCase,
    LogoutUseCase? logoutUseCase,
    UpdateProfileUseCase? updateProfileUseCase,
  }) : _registerUseCase =
           registerUseCase ?? RegisterUseCase(AuthRepositoryImpl()),
       _loginUseCase = loginUseCase ?? LoginUseCase(AuthRepositoryImpl()),
       _getMeUseCase = getMeUseCase ?? GetMeUseCase(AuthRepositoryImpl()),
       _refreshTokenUseCase =
           refreshTokenUseCase ?? RefreshTokenUseCase(AuthRepositoryImpl()),
       _logoutUseCase =
           logoutUseCase ?? LogoutUseCase(AuthRepositoryImpl()),
       _updateProfileUseCase =
           updateProfileUseCase ?? UpdateProfileUseCase(AuthRepositoryImpl());

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
  /// Maps to exact UserRole enum values: UserRole.farmer, UserRole.buyer, UserRole.admin
  AppUser _mapUserEntityToAppUser(UserEntity user) {
    UserRole mappedRole;
    final r = user.role.trim().toLowerCase();
    if (r == 'farmer') {
      mappedRole = UserRole.farmer;
    } else if (r == 'admin' || r == 'super_admin' || r == 'superadmin') {
      mappedRole = UserRole.admin;
    } else {
      mappedRole = UserRole.buyer;
    }

    final userName = user.name.isNotEmpty
        ? user.name
        : (_currentUser?.name.isNotEmpty == true
            ? _currentUser!.name
            : (user.phone.isNotEmpty ? user.phone : 'User'));

    final userPhone = user.phone.isNotEmpty
        ? user.phone
        : (_currentUser?.phone ?? '');

    return AppUser(
      id: user.id ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: userName,
      phone: userPhone,
      role: mappedRole,
      email: user.email ?? _currentUser?.email,
      avatarUrl: user.avatarUrl ?? _currentUser?.avatarUrl,
      district: user.district ?? _currentUser?.district,
      isVerified: user.isVerified,
    );
  }

  /// Checks Hive for stored access token, fetches current user by this token via /users/me,
  /// and restores the authenticated session if valid.
  Future<bool> tryAutoLogin() async {
    try {
      final savedToken = await StorageService().getAccessToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        debugPrint('🔍 [HIVE] Found access token in Hive storage. Fetching user via /users/me...');
        _token = savedToken;
        _refreshToken = await StorageService().getRefreshToken();
        final meUser = await fetchCurrentUser(savedToken);
        return meUser != null;
      }
    } catch (e) {
      debugPrint('⚠️ [HIVE] Auto-login error: $e');
    }
    return false;
  }

  /// Generates a new access token using the refresh token stored in Hive via POST /api/v1/auth/refresh
  Future<String?> refreshAccessToken() async {
    final tokenToRefresh =
        _refreshToken ?? await StorageService().getRefreshToken();

    if (tokenToRefresh == null || tokenToRefresh.isEmpty) {
      debugPrint('No refresh token available in Hive to generate new access token.');
      return null;
    }

    try {
      debugPrint('Refreshing access token via POST /api/v1/auth/refresh...');
      final tokenModel = await _refreshTokenUseCase(tokenToRefresh);

      _token = tokenModel.accessToken;
      if (tokenModel.refreshToken != null && tokenModel.refreshToken!.isNotEmpty) {
        _refreshToken = tokenModel.refreshToken;
      }

      // Update tokens in Hive
      await StorageService().saveAuthTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: _refreshToken,
      );

      debugPrint('Access token refreshed and stored in Hive successfully.');
      notifyListeners();
      return _token;
    } catch (e) {
      debugPrint('Error refreshing access token: $e');
      // If refresh token is expired or invalid, clear stored session from Hive
      if (e is TokenExpiredException ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        await logout();
      }
      return null;
    }
  }

  /// Fetches current user profile from GET /api/v1/users/me using access token.
  /// If the access token is expired (HTTP 401), automatically generates a new
  /// access token via /auth/refresh and retries the request seamlessly!
  Future<UserEntity?> fetchCurrentUser(String accessToken) async {
    try {
      final meUser = await _getMeUseCase(accessToken);
      _token = accessToken;
      await StorageService().setString('auth_token', accessToken);
      _currentUser = _mapUserEntityToAppUser(meUser);
      debugPrint('👤 [AUTH] Authenticated User: ${_currentUser?.name} | Role: ${_currentUser?.role.name.toUpperCase()}');
      notifyListeners();
      return meUser;
    } on TokenExpiredException catch (_) {
      debugPrint(
        'Access token expired on /users/me. Attempting token refresh...',
      );
      // Generate new access token using refresh token stored in Hive
      final newAccessToken = await refreshAccessToken();
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        try {
          debugPrint('Retrying /users/me with newly generated access token...');
          final retriedUser = await _getMeUseCase(newAccessToken);
          _currentUser = _mapUserEntityToAppUser(retriedUser);
          notifyListeners();
          return retriedUser;
        } catch (retryError) {
          debugPrint('Failed /users/me after token refresh: $retryError');
          return null;
        }
      }
      return null;
    } catch (e) {
      // Check if general exception message indicates unauthorized / 401
      if (e.toString().contains('401') ||
          e.toString().toLowerCase().contains('unauthorized')) {
        debugPrint('401 detected on /users/me. Attempting token refresh...');
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
      debugPrint('Error fetching /users/me: $e');
      return null;
    }
  }

  /// Logs in a user with phone and password via API, stores access & refresh tokens in Hive,
  /// then immediately fetches current user via GET /api/v1/users/me with access token.
  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginUser = await _loginUseCase(phone: phone, password: password);

      final authToken = loginUser.token;
      final refToken = loginUser.refreshToken;

      if (authToken != null && authToken.isNotEmpty) {
        _token = authToken;
        _refreshToken = refToken;

        // Keep token data into Hive
        await StorageService().saveAuthTokens(
          accessToken: authToken,
          refreshToken: refToken,
        );

        // Fetch current user via /users/me using the access token
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

  /// Registers a new user with backend API, stores access & refresh tokens into Hive,
  /// then fetches current user via GET /api/v1/users/me with access token.
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

      if (authToken != null && authToken.isNotEmpty) {
        _token = authToken;
        _refreshToken = refToken;

        // Keep token data into Hive
        await StorageService().saveAuthTokens(
          accessToken: authToken,
          refreshToken: refToken,
        );

        // Fetch current user via /users/me using the access token
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

  /// Logs out user: calls POST /api/v1/auth/logout API with bearer token,
  /// cleans Hive data, clears in-memory state and notifies listeners.
  Future<void> logout() async {
    final tokenToInvalidate = _token ?? await StorageService().getAccessToken();

    if (tokenToInvalidate != null && tokenToInvalidate.isNotEmpty) {
      try {
        debugPrint('🚪 [AUTH] Calling POST /api/v1/auth/logout with token: ${tokenToInvalidate.substring(0, tokenToInvalidate.length > 20 ? 20 : tokenToInvalidate.length)}...');
        await _logoutUseCase(tokenToInvalidate);
      } catch (e) {
        debugPrint('⚠️ [AUTH] Logout API call failed: $e');
      }
    }

    _token = null;
    _refreshToken = null;
    _currentUser = null;
    // Clean Hive data
    await StorageService().clearAuthData();
    notifyListeners();
  }

  /// Updates user profile on the server via PATCH /api/v1/users/me matching curl:
  /// {
  ///   "name": "Rafiq Ahmed",
  ///   "avatarUrl": "https://cdn.example.com/avatar.jpg",
  ///   "district": "Bogura",
  ///   "file": "string"
  /// }
  Future<bool> updateProfile({
    required String name,
    String? avatarUrl,
    String? district,
    String? file,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final token = _token ?? await StorageService().getAccessToken();
    if (token == null || token.isEmpty) {
      _errorMessage = 'User not authenticated.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final payload = <String, dynamic>{
      'name': name.trim(),
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) ...{
        'avatarUrl': avatarUrl.trim(),
        'avatar_url': avatarUrl.trim(),
        'avatar': avatarUrl.trim(),
      },
      if (district != null && district.trim().isNotEmpty)
        'district': district.trim(),
      if (file != null && file.trim().isNotEmpty)
        'file': file.trim(),
    };

    try {
      final updatedUserEntity =
          await _updateProfileUseCase(token: token, data: payload);
      _currentUser = _mapUserEntityToAppUser(updatedUserEntity);
      _currentUser = _currentUser?.copyWith(
        name: name.trim(),
        avatarUrl: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? avatarUrl.trim()
            : _currentUser?.avatarUrl,
        district: (district != null && district.trim().isNotEmpty)
            ? district.trim()
            : _currentUser?.district,
      );
      debugPrint(
        '✅ [AUTH] Profile updated on server: ${_currentUser?.name} | Avatar: ${_currentUser?.avatarUrl} | District: ${_currentUser?.district}',
      );
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
