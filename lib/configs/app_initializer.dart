import 'package:flutter/widgets.dart';
import '../core/utils/storage_service.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Initialize Hive storage and auth box
    await StorageService().init();
  }
}
