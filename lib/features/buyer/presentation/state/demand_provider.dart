import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/create_demand_request_model.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../../domain/usecases/create_demand_usecase.dart';
import '../../domain/usecases/get_my_demands_usecase.dart';

class DemandProvider extends ChangeNotifier {
  List<DemandPost> _demands = List<DemandPost>.from(MockData.demoDemands);
  List<DemandPost> _myDemands = [];
  List<Bid> _bids = List<Bid>.from(MockData.demoBids);
  bool _isLoading = false;
  bool _isMyDemandsLoading = false;
  String? _errorMessage;
  String? _myDemandsError;

  final CreateDemandUseCase _createDemandUseCase;
  final GetMyDemandsUseCase _getMyDemandsUseCase;
  final BuyerRepository _buyerRepository;

  DemandProvider({
    CreateDemandUseCase? createDemandUseCase,
    GetMyDemandsUseCase? getMyDemandsUseCase,
    BuyerRepository? buyerRepository,
  })  : _buyerRepository = buyerRepository ?? BuyerRepositoryImpl(),
        _createDemandUseCase = createDemandUseCase ??
            CreateDemandUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getMyDemandsUseCase = getMyDemandsUseCase ??
            GetMyDemandsUseCase(buyerRepository ?? BuyerRepositoryImpl());

  List<DemandPost> get demands => _demands;
  List<DemandPost> get myDemands => _myDemands;
  List<Bid> get bids => _bids;
  bool get isLoading => _isLoading;
  bool get isMyDemandsLoading => _isMyDemandsLoading;
  String? get errorMessage => _errorMessage;
  String? get myDemandsError => _myDemandsError;
  BuyerRepository get buyerRepository => _buyerRepository;

  void setDemands(List<DemandPost> demands) {
    _demands = demands;
    notifyListeners();
  }

  void setMyDemands(List<DemandPost> myDemands) {
    _myDemands = myDemands;
    notifyListeners();
  }

  void addDemand(DemandPost demand) {
    _demands.removeWhere((d) => d.id == demand.id);
    _demands.insert(0, demand);
    _myDemands.removeWhere((d) => d.id == demand.id);
    _myDemands.insert(0, demand);
    notifyListeners();
  }

  void setBids(List<Bid> bids) {
    _bids = bids;
    notifyListeners();
  }

  /// Uploads demand product images using POST /api/v1/upload
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return await _buyerRepository.uploadImages(
      files: files,
      token: token,
    );
  }

  /// Fetches the buyer's own demands using GET /api/v1/demands/my
  Future<List<DemandPost>> fetchMyDemands({
    int page = 1,
    int limit = 10,
    String? search = 'Potato',
    String? productName = 'Potato',
    double? minPrice = 20,
    double? maxPrice = 50,
    String? tradeType = 'both',
    String? status = 'active',
    String? token,
  }) async {
    _isMyDemandsLoading = true;
    _myDemandsError = null;
    notifyListeners();

    try {
      final fetched = await _getMyDemandsUseCase(
        page: page,
        limit: limit,
        search: search,
        productName: productName,
        minPrice: minPrice,
        maxPrice: maxPrice,
        tradeType: tradeType,
        status: status,
        token: token,
      );
      _myDemands = fetched;
      return fetched;
    } catch (e) {
      _myDemandsError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isMyDemandsLoading = false;
      notifyListeners();
    }
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

