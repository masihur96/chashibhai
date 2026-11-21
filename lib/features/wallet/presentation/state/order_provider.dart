import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<Transaction> _transactions = [];

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
