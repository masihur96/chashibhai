import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';

class DemandProvider extends ChangeNotifier {
  List<DemandPost> _demands = MockData.demoDemands;
  List<Bid> _bids = MockData.demoBids;

  List<DemandPost> get demands => _demands;
  List<Bid> get bids => _bids;

  void setDemands(List<DemandPost> demands) {
    _demands = demands;
    notifyListeners();
  }

  void setBids(List<Bid> bids) {
    _bids = bids;
    notifyListeners();
  }
}
