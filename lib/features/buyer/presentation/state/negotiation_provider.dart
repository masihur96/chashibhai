import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../../domain/repositories/buyer_repository.dart';
import '../../domain/usecases/get_my_negotiations_usecase.dart';

class NegotiationProvider extends ChangeNotifier {
  List<Negotiation> _negotiations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final GetMyNegotiationsUseCase _getMyNegotiationsUseCase;
  final BuyerRepository _buyerRepository;

  NegotiationProvider({
    GetMyNegotiationsUseCase? getMyNegotiationsUseCase,
    BuyerRepository? buyerRepository,
  })  : _buyerRepository = buyerRepository ?? BuyerRepositoryImpl(),
        _getMyNegotiationsUseCase = getMyNegotiationsUseCase ??
            GetMyNegotiationsUseCase(buyerRepository ?? BuyerRepositoryImpl());

  List<Negotiation> get negotiations => _negotiations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  BuyerRepository get buyerRepository => _buyerRepository;

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Negotiation> get filteredNegotiations {
    return _negotiations.where((n) {
      // Filter by status
      final matchesStatus = _selectedStatus == 'All' ||
          n.status.name.toLowerCase() == _selectedStatus.toLowerCase();

      // Filter by search query
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          (n.productName?.toLowerCase().contains(q) ?? false) ||
          (n.farmerName?.toLowerCase().contains(q) ?? false) ||
          (n.message?.toLowerCase().contains(q) ?? false);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get pendingCount =>
      _negotiations.where((n) => n.status == NegotiationStatus.pending).length;
  int get counteredCount =>
      _negotiations.where((n) => n.status == NegotiationStatus.countered).length;
  int get acceptedCount =>
      _negotiations.where((n) => n.status == NegotiationStatus.accepted).length;

  /// Fetches the buyer's negotiations using GET /api/v1/negotiations/my
  Future<List<Negotiation>> fetchMyNegotiations({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _getMyNegotiationsUseCase(token: token);
      _negotiations = fetched;
      _isLoading = false;
      notifyListeners();
      return _negotiations;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return _negotiations;
    }
  }

  void acceptCounterOffer(String negotiationId) {
    final idx = _negotiations.indexWhere((n) => n.id == negotiationId);
    if (idx != -1) {
      final neg = _negotiations[idx];
      _negotiations[idx] = neg.copyWith(
        status: NegotiationStatus.accepted,
        offerPrice: neg.counterPrice ?? neg.offerPrice,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void rejectNegotiation(String negotiationId) {
    final idx = _negotiations.indexWhere((n) => n.id == negotiationId);
    if (idx != -1) {
      _negotiations[idx] = _negotiations[idx].copyWith(
        status: NegotiationStatus.rejected,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
