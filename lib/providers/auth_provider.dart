import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/models.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _biometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppUser? get currentUser => _currentUser;
  
  UserRole get userRole => _currentUser?.role ?? UserRole.buyer;
  
  double get walletBalance => _currentUser?.walletBalance ?? 0.0;
  
  bool get biometricEnabled => _biometricEnabled;

  void setCurrentUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setBiometricEnabled(bool enabled) {
    _biometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics(String appLocale) async {
    final authDesc = appLocale == 'bn' 
      ? 'বায়োমেট্রিক ব্যবহার করে লগইন করুন' 
      : 'Login using biometrics';
      
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
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
