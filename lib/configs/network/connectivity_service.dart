import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  void updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(_isConnected);
      notifyListeners();
    }
  }

  Future<bool> checkConnectivity() async {
    return _isConnected;
  }

  @override
  void dispose() {
    _connectionController.close();
    super.dispose();
  }
}
