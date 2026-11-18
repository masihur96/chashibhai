import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/models/models.dart';
import '../../../../core/utils/storage_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _biometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Loading, token and error state
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  UserEntity? _registeredUser;

  final RegisterUseCase _registerUseCase;
  final LoginUseCase _loginUseCase;
  final GetMeUseCase _getMeUseCase;

  AuthProvider({
    RegisterUseCase? registerUseCase,
    LoginUseCase? loginUseCase,
    GetMeUseCase? getMeUseCase,
  }) : _registerUseCase =
           registerUseCase ?? RegisterUseCase(AuthRepositoryImpl()),
       _loginUseCase = loginUseCase ?? LoginUseCase(AuthRepositoryImpl()),
       _getMeUseCase = getMeUseCase ?? GetMeUseCase(AuthRepositoryImpl());

  // Getters
  AppUser? get currentUser => _currentUser;
  UserRole get userRole => _currentUser?.role ?? UserRole.buyer;
  double get walletBalance => _currentUser?.walletBalance ?? 0.0;
  bool get biometricEnabled => _biometricEnabled;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
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

  /// Fetches current user profile from GET /api/v1/auth/me using access token
  Future<UserEntity?> fetchCurrentUser(String accessToken) async {
    try {
      final meUser = await _getMeUseCase(accessToken);
      _token = accessToken;
      await StorageService().setString('auth_token', accessToken);
      _currentUser = _mapUserEntityToAppUser(meUser);
      notifyListeners();
      return meUser;
    } catch (e) {
      debugPrint('Error fetching /auth/me: $e');
      return null;
    }
  }

  /// Logs in a user with phone and password via API,
  /// then immediately fetches current user via GET /auth/me with access token.
  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginUser = await _loginUseCase(phone: phone, password: password);

      final authToken = loginUser.token;

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

  /// Registers a new user with the backend API,
  /// then if token is returned, fetches current user via GET /auth/me.
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
