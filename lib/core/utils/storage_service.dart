import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String authBoxName = 'auth_box';
  Box? _authBox;
  final Map<String, dynamic> _memoryFallback = {};

  /// Initializes Hive for Flutter and opens the auth box
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _authBox = await Hive.openBox(authBoxName);
      debugPrint('📦 [HIVE] Initialized and opened box "$authBoxName" successfully.');
    } catch (e) {
      debugPrint('⚠️ [HIVE] Initialization warning: $e. Falling back to memory cache.');
    }
  }

  Future<Box> _getBox() async {
    if (_authBox != null && _authBox!.isOpen) {
      return _authBox!;
    }
    try {
      _authBox = await Hive.openBox(authBoxName);
      return _authBox!;
    } catch (_) {
      try {
        await Hive.initFlutter();
        _authBox = await Hive.openBox(authBoxName);
        return _authBox!;
      } catch (e) {
        debugPrint('⚠️ [HIVE] Error opening box: $e');
        rethrow;
      }
    }
  }

  Future<void> setString(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      final box = await _getBox();
      await box.put(key, value);
    } catch (e) {
      debugPrint('⚠️ [HIVE] Error saving string ($key): $e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      final box = await _getBox();
      final val = box.get(key);
      if (val != null) return val.toString();
    } catch (e) {
      debugPrint('⚠️ [HIVE] Error getting string ($key): $e');
    }
    return _memoryFallback[key] as String?;
  }

  Future<void> setBool(String key, bool value) async {
    _memoryFallback[key] = value;
    try {
      final box = await _getBox();
      await box.put(key, value);
    } catch (e) {
      debugPrint('⚠️ [HIVE] Error saving bool ($key): $e');
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      final box = await _getBox();
      final val = box.get(key);
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('⚠️ [HIVE] Error getting bool ($key): $e');
    }
    return _memoryFallback[key] as bool?;
  }

  Future<void> remove(String key) async {
    _memoryFallback.remove(key);
    try {
      final box = await _getBox();
      await box.delete(key);
    } catch (e) {
      debugPrint('⚠️ [HIVE] Error removing key ($key): $e');
    }
  }

  Future<void> clear() async {
    _memoryFallback.clear();
    try {
      final box = await _getBox();
      await box.clear();
      debugPrint('🧹 [HIVE] Cleared all data in "$authBoxName".');
    } catch (e) {
      debugPrint('⚠️ [HIVE] Error clearing box: $e');
    }
  }

  // --- Dedicated Token & Auth Storage with Hive ---

  /// Saves access token and optional refresh token into Hive
  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await setString('auth_token', accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await setString('refresh_token', refreshToken);
    }
    debugPrint('💾 [HIVE] Stored auth tokens into Hive box "$authBoxName".');
  }

  /// Retrieves the saved access token from Hive
  Future<String?> getAccessToken() async {
    return getString('auth_token');
  }

  /// Retrieves the saved refresh token from Hive
  Future<String?> getRefreshToken() async {
    return getString('refresh_token');
  }

  /// Cleans all authentication and token data from Hive upon logout
  Future<void> clearAuthData() async {
    await remove('auth_token');
    await remove('refresh_token');
    await remove('user_role');
    await remove('user_data');
    await clear();
    debugPrint('🧹 [HIVE] Cleaned all auth tokens and session data from Hive.');
  }

  /// Returns true if a non-empty access token is currently saved in Hive
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
