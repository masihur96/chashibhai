import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/create_demand_request_model.dart';
import '../../data/models/create_bid_request_model.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../../domain/usecases/create_demand_usecase.dart';
import '../../domain/usecases/get_my_demands_usecase.dart';
import '../../domain/usecases/get_demands_usecase.dart';
import '../../domain/usecases/create_bid_usecase.dart';
import '../../domain/usecases/get_product_bids_usecase.dart';
import '../../domain/usecases/get_my_bids_usecase.dart';
import '../../domain/usecases/submit_demand_offer_usecase.dart';
import '../../domain/usecases/get_demand_offers_usecase.dart';
import '../../domain/usecases/get_demand_by_id_usecase.dart';
import '../../domain/usecases/accept_demand_offer_usecase.dart';
import '../../data/models/create_demand_offer_request_model.dart';

class DemandProvider extends ChangeNotifier {
  List<DemandPost> _demands = [];
  List<DemandPost> _myDemands = [];
  List<Bid> _bids = [];
  List<Bid> _myBids = [];
  final Map<String, List<DemandOffer>> _demandOffersMap = {};
  final Map<String, DemandPost> _demandDetailsMap = {};
  bool _isLoading = false;
  bool _isDemandsLoading = false;
  bool _isMyDemandsLoading = false;
  bool _isPlacingBid = false;
  bool _isProductBidsLoading = false;
  bool _isMyBidsLoading = false;
  bool _isSubmittingOffer = false;
  bool _isOffersLoading = false;
  bool _isDemandDetailsLoading = false;
  bool _isAcceptingOffer = false;
  String? _errorMessage;
  String? _demandsError;
  String? _myDemandsError;
  String? _bidError;
  String? _productBidsError;
  String? _myBidsError;
  String? _submitOfferError;
  String? _offersError;
  String? _demandDetailsError;
  String? _acceptOfferError;
  String? _lastLoadedProductId;
  DemandOffer? _lastSubmittedOffer;
  AcceptDemandOfferResult? _lastAcceptedOfferResult;
  final List<DemandOffer> _myOffers = [];

  final CreateDemandUseCase _createDemandUseCase;
  final GetMyDemandsUseCase _getMyDemandsUseCase;
  final GetDemandsUseCase _getDemandsUseCase;
  final CreateBidUseCase _createBidUseCase;
  final GetProductBidsUseCase _getProductBidsUseCase;
  final GetMyBidsUseCase _getMyBidsUseCase;
  final SubmitDemandOfferUseCase _submitDemandOfferUseCase;
  final GetDemandOffersUseCase _getDemandOffersUseCase;
  final GetDemandByIdUseCase _getDemandByIdUseCase;
  final AcceptDemandOfferUseCase _acceptDemandOfferUseCase;
  final BuyerRepository _buyerRepository;

  DemandProvider({
    CreateDemandUseCase? createDemandUseCase,
    GetMyDemandsUseCase? getMyDemandsUseCase,
    GetDemandsUseCase? getDemandsUseCase,
    CreateBidUseCase? createBidUseCase,
    GetProductBidsUseCase? getProductBidsUseCase,
    GetMyBidsUseCase? getMyBidsUseCase,
    SubmitDemandOfferUseCase? submitDemandOfferUseCase,
    GetDemandOffersUseCase? getDemandOffersUseCase,
    GetDemandByIdUseCase? getDemandByIdUseCase,
    AcceptDemandOfferUseCase? acceptDemandOfferUseCase,
    BuyerRepository? buyerRepository,
  })  : _buyerRepository = buyerRepository ?? BuyerRepositoryImpl(),
        _createDemandUseCase = createDemandUseCase ??
            CreateDemandUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getMyDemandsUseCase = getMyDemandsUseCase ??
            GetMyDemandsUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getDemandsUseCase = getDemandsUseCase ??
            GetDemandsUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _createBidUseCase = createBidUseCase ??
            CreateBidUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getProductBidsUseCase = getProductBidsUseCase ??
            GetProductBidsUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getMyBidsUseCase = getMyBidsUseCase ??
            GetMyBidsUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _submitDemandOfferUseCase = submitDemandOfferUseCase ??
            SubmitDemandOfferUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getDemandOffersUseCase = getDemandOffersUseCase ??
            GetDemandOffersUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _getDemandByIdUseCase = getDemandByIdUseCase ??
            GetDemandByIdUseCase(buyerRepository ?? BuyerRepositoryImpl()),
        _acceptDemandOfferUseCase = acceptDemandOfferUseCase ??
            AcceptDemandOfferUseCase(buyerRepository ?? BuyerRepositoryImpl());

  List<DemandPost> get demands => _demands;
  List<DemandPost> get myDemands => _myDemands;
  List<Bid> get bids => _bids;
  List<Bid> get myBids {
    if (_myBids.isNotEmpty) return _myBids;
    final fallback = _bids.where((b) =>
        b.buyerId == '395e2439-099f-41da-a739-019f5a08e504' ||
        b.buyerId == 'u1').toList();
    fallback.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return fallback;
  }
  bool get isLoading => _isLoading;
  bool get isDemandsLoading => _isDemandsLoading;
  bool get isMyDemandsLoading => _isMyDemandsLoading;
  bool get isPlacingBid => _isPlacingBid;
  bool get isProductBidsLoading => _isProductBidsLoading;
  bool get isMyBidsLoading => _isMyBidsLoading;
  String? get errorMessage => _errorMessage;
  String? get demandsError => _demandsError;
  String? get myDemandsError => _myDemandsError;
  String? get bidError => _bidError;
  String? get productBidsError => _productBidsError;
  String? get myBidsError => _myBidsError;
  bool get isSubmittingOffer => _isSubmittingOffer;
  String? get submitOfferError => _submitOfferError;
  bool get isOffersLoading => _isOffersLoading;
  String? get offersError => _offersError;
  bool get isDemandDetailsLoading => _isDemandDetailsLoading;
  String? get demandDetailsError => _demandDetailsError;
  bool get isAcceptingOffer => _isAcceptingOffer;
  String? get acceptOfferError => _acceptOfferError;
  AcceptDemandOfferResult? get lastAcceptedOfferResult => _lastAcceptedOfferResult;
  DemandOffer? get lastSubmittedOffer => _lastSubmittedOffer;
  List<DemandOffer> get myOffers => List.unmodifiable(_myOffers);
  String? get lastLoadedProductId => _lastLoadedProductId;
  BuyerRepository get buyerRepository => _buyerRepository;

  List<DemandOffer> getOffersForDemand(String demandId) =>
      _demandOffersMap[demandId] ?? [];

  DemandPost? getDemandDetail(String demandId) => _demandDetailsMap[demandId];

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
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches the buyer's bids using GET /api/v1/bids/my
  Future<List<Bid>> fetchMyBids({String? token}) async {
    _isMyBidsLoading = true;
    _myBidsError = null;
    notifyListeners();

    try {
      final fetched = await _getMyBidsUseCase(token: token);
      fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _myBids = fetched;
      _isMyBidsLoading = false;
      notifyListeners();
      return _myBids;
    } catch (e) {
      _isMyBidsLoading = false;
      _myBidsError = e.toString().replaceFirst('Exception: ', '');
      if (_myBids.isEmpty) {
        _myBids = _bids.where((b) =>
            b.buyerId == '395e2439-099f-41da-a739-019f5a08e504' ||
            b.buyerId == 'u1').toList();
        _myBids.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      notifyListeners();
      return _myBids;
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
      _myBids.removeWhere((b) => b.id == newBid.id);
      _myBids.insert(0, newBid);
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

  /// Fetches public buyer demands using GET /api/v1/demands?page=1&limit=10&tradeType=both&trade_type=both&status=active
  Future<List<DemandPost>> fetchDemands({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  }) async {
    _isDemandsLoading = true;
    _demandsError = null;
    notifyListeners();

    try {
      final fetched = await _getDemandsUseCase(
        page: page,
        limit: limit,
        tradeType: tradeType,
        status: status,
        search: search,
        token: token,
      );
      _demands = fetched;
      return fetched;
    } catch (e) {
      _demandsError = e.toString().replaceFirst('Exception: ', '');
      return _demands;
    } finally {
      _isDemandsLoading = false;
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

  /// Submits an offer on an active demand post using POST /api/v1/demands/{demandId}/offer
  Future<DemandOffer> submitDemandOffer({
    required String demandId,
    required double offerPrice,
    String? note,
    String? token,
  }) async {
    _isSubmittingOffer = true;
    _submitOfferError = null;
    notifyListeners();

    try {
      final newOffer = await _submitDemandOfferUseCase(
        demandId: demandId,
        request: CreateDemandOfferRequestModel(
          offerPrice: offerPrice,
          note: note,
        ),
        token: token,
      );
      _lastSubmittedOffer = newOffer;
      _myOffers.removeWhere((o) => o.id == newOffer.id);
      _myOffers.insert(0, newOffer);
      _isSubmittingOffer = false;
      notifyListeners();
      return newOffer;
    } catch (e) {
      _isSubmittingOffer = false;
      _submitOfferError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches offers submitted for a demand using GET /api/v1/demands/{demandId}/offers
  Future<List<DemandOffer>> fetchDemandOffers({
    required String demandId,
    String? token,
  }) async {
    _isOffersLoading = true;
    _offersError = null;
    notifyListeners();

    try {
      final offers = await _getDemandOffersUseCase(
        demandId: demandId,
        token: token,
      );
      // Sort offers lowest price first by default
      offers.sort((a, b) => a.offerPrice.compareTo(b.offerPrice));
      _demandOffersMap[demandId] = offers;
      _isOffersLoading = false;
      notifyListeners();
      return offers;
    } catch (e) {
      _isOffersLoading = false;
      _offersError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches single demand details using GET /api/v1/demands/{demandId}
  Future<DemandPost> fetchDemandById({
    required String demandId,
    String? token,
  }) async {
    _isDemandDetailsLoading = true;
    _demandDetailsError = null;
    notifyListeners();

    try {
      final demand = await _getDemandByIdUseCase(
        demandId: demandId,
        token: token,
      );
      _demandDetailsMap[demandId] = demand;
      // Also update in _demands or _myDemands if already exists
      final idx = _myDemands.indexWhere((d) => d.id == demand.id);
      if (idx != -1) {
        _myDemands[idx] = demand;
      }
      final dIdx = _demands.indexWhere((d) => d.id == demand.id);
      if (dIdx != -1) {
        _demands[dIdx] = demand;
      }
      _isDemandDetailsLoading = false;
      notifyListeners();
      return demand;
    } catch (e) {
      _isDemandDetailsLoading = false;
      _demandDetailsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Accepts an offer on a demand post using POST /api/v1/demands/{demandId}/offers/{offerId}/accept
  Future<AcceptDemandOfferResult> acceptDemandOffer({
    required String demandId,
    required String offerId,
    String? token,
  }) async {
    _isAcceptingOffer = true;
    _acceptOfferError = null;
    notifyListeners();

    try {
      final result = await _acceptDemandOfferUseCase(
        demandId: demandId,
        offerId: offerId,
        token: token,
      );
      _lastAcceptedOfferResult = result;

      // Update cached demand status to fulfilled
      if (_demandDetailsMap.containsKey(demandId)) {
        _demandDetailsMap[demandId] = _demandDetailsMap[demandId]!.copyWith(
          status: DemandStatus.fulfilled,
        );
      }
      final myDemIdx = _myDemands.indexWhere((d) => d.id == demandId);
      if (myDemIdx != -1) {
        _myDemands[myDemIdx] = _myDemands[myDemIdx].copyWith(
          status: DemandStatus.fulfilled,
        );
      }
      final demIdx = _demands.indexWhere((d) => d.id == demandId);
      if (demIdx != -1) {
        _demands[demIdx] = _demands[demIdx].copyWith(
          status: DemandStatus.fulfilled,
        );
      }

      _isAcceptingOffer = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isAcceptingOffer = false;
      _acceptOfferError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}

