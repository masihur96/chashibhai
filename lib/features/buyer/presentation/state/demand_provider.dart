import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';
import '../../data/models/create_demand_request_model.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../../domain/usecases/create_demand_usecase.dart';

class DemandProvider extends ChangeNotifier {
  List<DemandPost> _demands = List<DemandPost>.from(MockData.demoDemands);
  List<Bid> _bids = List<Bid>.from(MockData.demoBids);
  bool _isLoading = false;
  String? _errorMessage;

  final CreateDemandUseCase _createDemandUseCase;
  final BuyerRepository _buyerRepository;

  DemandProvider({
    CreateDemandUseCase? createDemandUseCase,
    BuyerRepository? buyerRepository,
  })  : _buyerRepository = buyerRepository ?? BuyerRepositoryImpl(),
        _createDemandUseCase = createDemandUseCase ??
            CreateDemandUseCase(buyerRepository ?? BuyerRepositoryImpl());

  List<DemandPost> get demands => _demands;
  List<Bid> get bids => _bids;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BuyerRepository get buyerRepository => _buyerRepository;

  void setDemands(List<DemandPost> demands) {
    _demands = demands;
    notifyListeners();
  }

  void addDemand(DemandPost demand) {
    _demands.removeWhere((d) => d.id == demand.id);
    _demands.insert(0, demand);
    notifyListeners();
  }

  void setBids(List<Bid> bids) {
    _bids = bids;
    notifyListeners();
  }

  /// Creates a new demand using POST /api/v1/demands
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newDemand = await _createDemandUseCase(
        request: request,
        token: token,
      );
      addDemand(newDemand);
      _isLoading = false;
      notifyListeners();
      return newDemand;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}

