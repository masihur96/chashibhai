import 'package:flutter/material.dart';

import '../features/account/presentation/views/settings_screen.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/buyer/presentation/views/buyer_home.dart';
import '../features/farmer/presentation/views/farmer_dashboard.dart';
import '../features/splash/presentation/views/splash_screen.dart';
import '../features/wallet/presentation/views/wallet_screen.dart';

class RouteGenerator {
  RouteGenerator._();

  static const String splash = '/';
  static const String login = '/login';
  static const String buyerHome = '/buyer_home';
  static const String farmerDashboard = '/farmer_dashboard';
  static const String wallet = '/wallet';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case buyerHome:
        return MaterialPageRoute(builder: (_) => const BuyerHomeScreen());
      case farmerDashboard:
        return MaterialPageRoute(builder: (_) => const FarmerDashboard());
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      case RouteGenerator.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
