import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiPath {
  ApiPath._();

  /// Allow overriding base URL dynamically at runtime if needed
  static String? customBaseUrl;

  /// Returns the appropriate base URL:
  /// - On Android emulator, 'http://10.0.2.2:3000/api/v1' (points to host localhost:3000)
  /// - On iOS simulator / macOS / Web, 'http://localhost:3000/api/v1'
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  /// Returns origin (e.g. 'http://localhost:3000' or 'http://10.0.2.2:3000')
  static String get serverOrigin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  // Upload endpoint
  static String get upload => '$baseUrl/upload';

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/users/me';
  static String get usersMe => '$baseUrl/users/me';
  static String get authMe => '$baseUrl/auth/me';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';

  // User & Profile
  static String get userProfile => '$baseUrl/users/profile';
  static String get updateProfile => '$baseUrl/users/profile';
  static String get usersProfile => '$baseUrl/users/profile';

  // Products
  static String get products => '$baseUrl/products';
  static String get myProducts => '$baseUrl/products/my';
  static String productById(String id) => '$baseUrl/products/$id';
  static String get productCategories => '$baseUrl/products/categories';

  // Demands
  static String get demands => '$baseUrl/demands';
  static String get myDemands => '$baseUrl/demands/my';

  // Bids
  static String get bids => '$baseUrl/bids';
  static String get myBids => '$baseUrl/bids/my';
  static String bidsByProduct(String productId) => '$baseUrl/bids/product/$productId';

  // Negotiations
  static String get negotiations => '$baseUrl/negotiations';
  static String get myNegotiations => '$baseUrl/negotiations/my';
  static String negotiationById(String id) => '$baseUrl/negotiations/$id';

  // Groups
  static String get groups => '$baseUrl/groups';

  // Orders
  static String get orders => '$baseUrl/orders';

  // Wallet
  static String get wallet => '$baseUrl/wallet';
  static String get transactions => '$baseUrl/wallet/transactions';

  // Admin
  static String get adminDashboard => '$baseUrl/admin/dashboard';
  static String get adminUsers => '$baseUrl/admin/users';
  static String adminUserById(String id) => '$baseUrl/admin/users/$id';
  static String adminVerifyUser(String id) => '$baseUrl/admin/users/$id/verify';
  static String adminBanUser(String id) => '$baseUrl/admin/users/$id/ban';
}
