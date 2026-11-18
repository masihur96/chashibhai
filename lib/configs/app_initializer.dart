import 'package:flutter/widgets.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Initialize required services, storage, and configurations here
  }
}
