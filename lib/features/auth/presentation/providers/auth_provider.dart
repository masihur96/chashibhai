import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/models/models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _biometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Loading and error state
  bool _isLoading = false;
  String? _errorMessage;
  UserEntity? _registeredUser;

  final RegisterUseCase _registerUseCase;
  final LoginUseCase _loginUseCase;

  AuthProvider({RegisterUseCase? registerUseCase, LoginUseCase? loginUseCase})
    : _registerUseCase =
          registerUseCase ?? RegisterUseCase(AuthRepositoryImpl()),
      _loginUseCase = loginUseCase ?? LoginUseCase(AuthRepositoryImpl());

  // Getters
  AppUser? get currentUser => _currentUser;
  UserRole get userRole => _currentUser?.role ?? UserRole.buyer;
  double get walletBalance => _currentUser?.walletBalance ?? 0.0;
  bool get biometricEnabled => _biometricEnabled;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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

  /// Logs in a user with phone and password via API
  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _loginUseCase(phone: phone, password: password);

      // Determine user role
      UserRole mappedRole = UserRole.buyer;
      final r = user.role.toUpperCase();
      if (r == 'FARMER') {
        mappedRole = UserRole.farmer;
      } else if (r == 'ADMIN' || r == 'SUPER_ADMIN') {
        mappedRole = UserRole.admin;
      }

      _currentUser = AppUser(
        id: user.id ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
        name: user.name.isNotEmpty ? user.name : 'User',
        phone: user.phone,
        role: mappedRole,
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

  /// Registers a new user with the backend API
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
      final user = await _registerUseCase(
        name: name,
        phone: phone,
        password: password,
        role: role,
      );

      _registeredUser = user;
      _isLoading = false;

      // Sync with AppUser if needed
      _currentUser = AppUser(
        id: user.id ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
        name: user.name,
        phone: user.phone,
        role: role.toUpperCase() == 'FARMER' ? UserRole.farmer : UserRole.buyer,
      );

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
