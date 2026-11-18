import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';

class AppStateProvider extends ChangeNotifier {
  String _appLocale = 'en';
  List<AppNotification> _notifications = MockData.demoNotifications;

  String get appLocale => _appLocale;
  bool get isBangla => _appLocale == 'bn';
  bool get isEnglish => _appLocale == 'en';
  List<AppNotification> get notifications => _notifications;

  void setAppLocale(String locale) {
    if (_appLocale != locale) {
      _appLocale = locale;
      notifyListeners();
    }
  }

  void toggleLocale() {
    _appLocale = _appLocale == 'en' ? 'bn' : 'en';
    notifyListeners();
  }

  void setNotifications(List<AppNotification> notifications) {
    _notifications = notifications;
    notifyListeners();
  }
}
