import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = MockData.demoOrders;
  List<Transaction> _transactions = MockData.demoTransactions;

  List<Order> get orders => _orders;
  List<Transaction> get transactions => _transactions;

  void setOrders(List<Order> orders) {
    _orders = orders;
    notifyListeners();
  }

  void setTransactions(List<Transaction> transactions) {
    _transactions = transactions;
    notifyListeners();
  }
}
