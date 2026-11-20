import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/create_demand_request_model.dart';
import '../../data/models/create_bid_request_model.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../../domain/usecases/create_demand_usecase.dart';
import '../../domain/usecases/get_my_demands_usecase.dart';
import '../../domain/usecases/create_bid_usecase.dart';
import '../../domain/usecases/get_product_bids_usecase.dart';

class DemandProvider extends ChangeNotifier {
  List<DemandPost> _demands = List<DemandPost>.from(MockData.demoDemands);
  List<DemandPost> _myDemands = [];
  List<Bid> _bids = List<Bid>.from(MockData.demoBids);
  bool _isLoading = false;
  bool _isMyDemandsLoading = false;
  bool _isPlacingBid = false;
  bool _isProductBidsLoading = false;
  String? _errorMessage;
  String? _myDemandsError;
  String? _bidError;
  String? _productBidsError;
  String? _lastLoadedProductId;

  final CreateDemandUseCase _createDemandUseCase;
  final GetMyDemandsUseCase _getMyDemandsUseCase;
  final CreateBidUseCase _createBidUseCase;
  final GetProductBidsUseCase _getProductBidsUseCase;
  final BuyerRepository _buyerRepository;

  DemandProvider({
    CreateDemandUseCase? createDemandUseCase,
    GetMyDemandsUseCase? getMyDemandsUseCase,
    CreateBidUseCase? createBidUseCase,
    GetProductBidsUseCase? getProductBidsUseCase,
    BuyerRepository? buyerRepository,
  })  : _buyerRepository = buyerRepository ?? BuyerRepositoryImpl(),
        _createDemandUseCase = createDemandUseCase ??
            CreateDemandUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getMyDemandsUseCase = getMyDemandsUseCase ??
            GetMyDemandsUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _createBidUseCase = createBidUseCase ??
            CreateBidUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getProductBidsUseCase = getProductBidsUseCase ??
            GetProductBidsUseCase(buyerRepository ?? BuyerRepositoryImpl());

  List<DemandPost> get demands => _demands;
  List<DemandPost> get myDemands => _myDemands;
  List<Bid> get bids => _bids;
  bool get isLoading => _isLoading;
  bool get isMyDemandsLoading => _isMyDemandsLoading;
  bool get isPlacingBid => _isPlacingBid;
  bool get isProductBidsLoading => _isProductBidsLoading;
  String? get errorMessage => _errorMessage;
  String? get myDemandsError => _myDemandsError;
  String? get bidError => _bidError;
  String? get productBidsError => _productBidsError;
  String? get lastLoadedProductId => _lastLoadedProductId;
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

  void addBid(Bid bid) {
    _bids.removeWhere((b) => b.id == bid.id);
    _bids.insert(0, bid);
    _bids.sort((a, b) => b.amount.compareTo(a.amount));
    notifyListeners();
  }

  List<Bid> getProductBids(String productId) {
    final list = _bids.where((b) => b.productId == productId).toList();
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// Fetches auction bids for a product using GET /api/v1/bids/product/{productId}
  Future<List<Bid>> fetchProductBids({
    required String productId,
    String? token,
  }) async {
    _isProductBidsLoading = true;
    _productBidsError = null;
    _lastLoadedProductId = productId;
    notifyListeners();

    try {
      final fetchedBids = await _getProductBidsUseCase(
        productId: productId,
        token: token,
      );
      // Sort bids highest amount first
      fetchedBids.sort((a, b) => b.amount.compareTo(a.amount));

      // Merge into _bids: remove existing for this product, insert fetched
      _bids.removeWhere((b) => b.productId == productId);
      _bids.insertAll(0, fetchedBids);
      _isProductBidsLoading = false;
      notifyListeners();
      return fetchedBids;
    } catch (e) {
      _isProductBidsLoading = false;
      _productBidsError = e.toString().replaceFirst('Exception: ', '');

      // Offline / fallback handling: if no bids present for this product, load matching demoBids
      final existingForProduct = _bids.where((b) => b.productId == productId).toList();
      if (existingForProduct.isEmpty) {
        final mockBids = MockData.demoBids.where((b) => b.productId == productId).toList();
        if (mockBids.isNotEmpty) {
          _bids.insertAll(0, mockBids);
        }
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Places a bid using POST /api/v1/bids
  Future<Bid> placeBid({
    required String productId,
    required double amount,
    String? token,
  }) async {
    _isPlacingBid = true;
    _bidError = null;
    notifyListeners();

    try {
      final newBid = await _createBidUseCase(
        request: CreateBidRequestModel(
          productId: productId,
          amount: amount,
        ),
        token: token,
      );
      addBid(newBid);
      _isPlacingBid = false;
      notifyListeners();
      return newBid;
    } catch (e) {
      _isPlacingBid = false;
      _bidError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
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

