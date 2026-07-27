import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/mock_data.dart';

class AppStateProvider extends ChangeNotifier {
  String _appLocale = 'en';
  List<AppNotification> _notifications = MockData.demoNotifications;

  String get appLocale => _appLocale;
  List<AppNotification> get notifications => _notifications;

  void setAppLocale(String locale) {
    _appLocale = locale;
    notifyListeners();
  }

  void setNotifications(List<AppNotification> notifications) {
    _notifications = notifications;
    notifyListeners();
  }
}
