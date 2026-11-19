import 'package:flutter/material.dart';

import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/admin_dashboard_model.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AdminRemoteDataSource _dataSource;

  AdminDashboardModel? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  AdminDashboardProvider({AdminRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AdminRemoteDataSourceImpl();

  AdminDashboardModel? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get hasData => _dashboardData != null;

  Future<void> fetchDashboardData({String? token, bool isRefresh = false}) async {
    if (!isRefresh && _dashboardData == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else if (isRefresh) {
      _errorMessage = null;
    }

    try {
      final result = await _dataSource.getDashboardData(token: token);
      _dashboardData = result;
      _lastUpdated = DateTime.now();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
