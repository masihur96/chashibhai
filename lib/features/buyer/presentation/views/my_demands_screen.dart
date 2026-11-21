import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../state/demand_provider.dart';
import './demand_offers_screen.dart';
import './post_demand_screen.dart';

/// Filter options for Demand Status
enum DemandStatusFilter {
  all('All', Icons.apps_rounded),
  active('Active', Icons.check_circle_outline_rounded),
  fulfilled('Fulfilled', Icons.task_alt_rounded),
  expired('Expired', Icons.timer_off_outlined);

  final String label;
  final IconData icon;
  const DemandStatusFilter(this.label, this.icon);
}

/// Filter options for Demand Trade Type
enum DemandTradeTypeFilter {
  all('All Types', Icons.all_inclusive_rounded),
  negotiation('Negotiation', Icons.handshake_outlined),
  auction('Auction', Icons.gavel_rounded),
  both('Both / Hybrid', Icons.swap_horiz_rounded);

  final String label;
  final IconData icon;
  const DemandTradeTypeFilter(this.label, this.icon);
}

/// Sort options for Demands
enum DemandSortOption {
  newest('Newest First', Icons.schedule_rounded),
  oldest('Oldest First', Icons.history_rounded),
  priceLowToHigh('Calling Price: Low to High', Icons.arrow_upward_rounded),
  priceHighToLow('Calling Price: High to Low', Icons.arrow_downward_rounded),
  quantityHighToLow('Quantity: High to Low', Icons.inventory_2_outlined),
  expiringSoon('Expiring Soonest', Icons.timer_outlined);

  final String label;
  final IconData icon;
  const DemandSortOption(this.label, this.icon);
}

class MyDemandsScreen extends StatefulWidget {
  const MyDemandsScreen({super.key});

  @override
  State<MyDemandsScreen> createState() => _MyDemandsScreenState();
}

class _MyDemandsScreenState extends State<MyDemandsScreen> {
  /// Default token from user's latest cURL specification
  static const String defaultFilterCurlToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTI0MzEwNSwiZXhwIjoxNzk1MjQ0MDA1fQ.BtzvQslgjVYxDxLMLX1w_QmrRcZCI6acecmsbrvzByk';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _searchQuery = '';
  DemandStatusFilter _selectedStatus = DemandStatusFilter.all;
  DemandTradeTypeFilter _selectedTradeType = DemandTradeTypeFilter.all;
  DemandSortOption _selectedSort = DemandSortOption.newest;
  bool _onlyWithOffers = false;
  double? _minPrice;
  double? _maxPrice;
  String _selectedDistrict = 'All';

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text;
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWithCurl();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  /// Fetches demands matching exact cURL specification:
  /// GET /api/v1/demands/my?page=1&limit=10&product_name=Potato&minPrice=20&min_price=20&maxPrice=50&max_price=50&tradeType=both&trade_type=both&status=all
  Future<void> _fetchWithCurl({
    int page = 1,
    int limit = 10,
    String? productName,
    double? minPrice,
    double? maxPrice,
    String? tradeType,
    String? status,
  }) async {
    final effectiveProductName = productName ?? (_searchQuery.isNotEmpty ? _searchQuery : 'Potato');
    final effectiveMinPrice = minPrice ?? (_minPrice ?? 20.0);
    final effectiveMaxPrice = maxPrice ?? (_maxPrice ?? 50.0);
    final effectiveTradeType = tradeType ??
        (_selectedTradeType == DemandTradeTypeFilter.auction
            ? 'auction'
            : (_selectedTradeType == DemandTradeTypeFilter.negotiation
                ? 'negotiation'
                : 'both'));
    final effectiveStatus = status ??
        (_selectedStatus == DemandStatusFilter.active
            ? 'active'
            : (_selectedStatus == DemandStatusFilter.fulfilled
                ? 'fulfilled'
                : (_selectedStatus == DemandStatusFilter.expired
                    ? 'expired'
                    : 'all')));

    final authProvider = context.read<AuthProvider>();
    String? token = authProvider.token;
    if (token == null || token.isEmpty) {
      try {
        token = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (token == null || token.isEmpty) {
      token = defaultFilterCurlToken;
    }

    if (!mounted) return;

    try {
      await context.read<DemandProvider>().fetchMyDemands(
        page: page,
        limit: limit,
        productName: effectiveProductName,
        minPrice: effectiveMinPrice,
        maxPrice: effectiveMaxPrice,
        tradeType: effectiveTradeType,
        status: effectiveStatus,
        token: token,
      );
    } catch (e) {
      debugPrint('⚠️ [MY_DEMANDS] fetchWithCurl error: $e');
    }
  }

  Future<void> _fetchDemands() async {
    await _fetchWithCurl();
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = DemandStatusFilter.all;
      _selectedTradeType = DemandTradeTypeFilter.all;
      _selectedSort = DemandSortOption.newest;
      _onlyWithOffers = false;
      _minPrice = null;
      _maxPrice = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedDistrict = 'All';
    });
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedStatus != DemandStatusFilter.all) count++;
    if (_selectedTradeType != DemandTradeTypeFilter.all) count++;
    if (_selectedSort != DemandSortOption.newest) count++;
    if (_onlyWithOffers) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_selectedDistrict != 'All') count++;
    return count;
  }

  List<DemandPost> _getFilteredDemands(List<DemandPost> myDemands, DemandProvider demandProvider) {
    return myDemands.where((d) {
      // 1. Search Query
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final nameMatches = d.productName.toLowerCase().contains(q);
        final locMatches = d.deliveryLocation.toLowerCase().contains(q);
        final idMatches = d.id.toLowerCase().contains(q);
        if (!nameMatches && !locMatches && !idMatches) return false;
      }

      // 2. Status Filter
      if (_selectedStatus != DemandStatusFilter.all) {
        if (_selectedStatus == DemandStatusFilter.active && d.status != DemandStatus.active) {
          return false;
        }
        if (_selectedStatus == DemandStatusFilter.fulfilled && d.status != DemandStatus.fulfilled) {
          return false;
        }
        if (_selectedStatus == DemandStatusFilter.expired && d.status != DemandStatus.expired) {
          return false;
        }
      }

      // 3. Trade Type Filter
      if (_selectedTradeType != DemandTradeTypeFilter.all) {
        if (_selectedTradeType == DemandTradeTypeFilter.negotiation && d.tradeType != TradeType.negotiation) {
          return false;
        }
        if (_selectedTradeType == DemandTradeTypeFilter.auction && d.tradeType != TradeType.auction) {
          return false;
        }
        if (_selectedTradeType == DemandTradeTypeFilter.both && d.tradeType != TradeType.both) {
          return false;
        }
      }

      // 4. Only with offers filter
      if (_onlyWithOffers) {
        final offersCount = d.offersCount ?? demandProvider.getOffersForDemand(d.id).length;
        if (offersCount == 0) return false;
      }

      // 5. Min price
      if (_minPrice != null && d.callingPrice < _minPrice!) {
        return false;
      }

      // 6. Max price
      if (_maxPrice != null && d.callingPrice > _maxPrice!) {
        return false;
      }

      // 7. District / Location
      if (_selectedDistrict != 'All') {
        if (!d.deliveryLocation.toLowerCase().contains(_selectedDistrict.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_selectedSort) {
          case DemandSortOption.newest:
            final aDate = a.createdAt ?? a.expiryTime;
            final bDate = b.createdAt ?? b.expiryTime;
            return bDate.compareTo(aDate);
          case DemandSortOption.oldest:
            final aDate = a.createdAt ?? a.expiryTime;
            final bDate = b.createdAt ?? b.expiryTime;
            return aDate.compareTo(bDate);
          case DemandSortOption.priceLowToHigh:
            return a.callingPrice.compareTo(b.callingPrice);
          case DemandSortOption.priceHighToLow:
            return b.callingPrice.compareTo(a.callingPrice);
          case DemandSortOption.quantityHighToLow:
            return b.quantity.compareTo(a.quantity);
          case DemandSortOption.expiringSoon:
            return a.expiryTime.compareTo(b.expiryTime);
        }
      });
  }

  List<String> _extractDistricts(List<DemandPost> demands) {
    final Set<String> districts = {'All'};
    for (final d in demands) {
      final loc = d.deliveryLocation.trim();
      if (loc.isNotEmpty) {
        final parts = loc.split(',');
        final district = parts.last.trim();
        if (district.isNotEmpty) {
          districts.add(district);
        }
      }
    }
    return districts.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = context.watch<AppStateProvider>().isBangla;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final demandProvider = context.watch<DemandProvider>();

    final myDemands = demandProvider.myDemands.isNotEmpty
        ? demandProvider.myDemands
        : demandProvider.demands
            .where((d) => currentUser != null && d.buyerId == currentUser.id)
            .toList();

    final isLoading = demandProvider.isMyDemandsLoading;
    final error = demandProvider.myDemandsError;
    final filteredDemands = _getFilteredDemands(myDemands, demandProvider);
    final availableDistricts = _extractDistricts(myDemands);

    // Compute metrics
    final totalCount = myDemands.length;
    final activeCount = myDemands.where((d) => d.status == DemandStatus.active).length;
    final fulfilledCount = myDemands.where((d) => d.status == DemandStatus.fulfilled).length;
    final totalOffers = myDemands.fold<int>(0, (sum, d) {
      final count = d.offersCount ?? demandProvider.getOffersForDemand(d.id).length;
      return sum + count;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla ? 'আমার চাহিদাসমূহ' : 'My Demands',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isBangla
                  ? '$totalCount টি চাহিদার মধ্যে ${filteredDemands.length} টি দেখানো হচ্ছে'
                  : 'Showing ${filteredDemands.length} of $totalCount demands',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // Filter Sheet trigger button
          IconButton(
            tooltip: isBangla ? 'ফিল্টার' : 'Filter & Sort',
            onPressed: () => _showFilterBottomSheet(
              context,
              availableDistricts,
              myDemands,
              demandProvider,
              isBangla,
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 22),
                if (_activeFiltersCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_activeFiltersCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            tooltip: isBangla ? 'রিফ্রেশ' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: _fetchDemands,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: Text(
          isBangla ? 'নতুন চাহিদা' : 'Post Demand',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostDemandScreen()),
          ).then((_) {
            if (mounted) _fetchDemands();
          });
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchDemands,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── KPI Stats Summary Bar ───
            SliverToBoxAdapter(
              child: _buildKpiStatsBar(
                totalCount: totalCount,
                activeCount: activeCount,
                fulfilledCount: fulfilledCount,
                totalOffers: totalOffers,
                isBangla: isBangla,
              ),
            ),

            // ─── Search & Filter Controls ───
            SliverToBoxAdapter(
              child: _buildSearchAndFilterControls(
                isBangla: isBangla,
                availableDistricts: availableDistricts,
                myDemands: myDemands,
                demandProvider: demandProvider,
              ),
            ),

            // ─── Active Filter Pills (if any) ───
            if (_activeFiltersCount > 0 || _searchQuery.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildActiveFilterTags(isBangla),
              ),

            // ─── Error Banner (if error occurred) ───
            if (error != null && myDemands.isEmpty)
              SliverToBoxAdapter(
                child: _buildErrorBanner(error, isBangla),
              ),

            // ─── Main Content: Loading, Empty, or List ───
            if (isLoading && myDemands.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSkeletonCard(),
                    childCount: 3,
                  ),
                ),
              )
            else if (myDemands.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildPureEmptyState(isBangla),
              )
            else if (filteredDemands.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildFilteredEmptyState(isBangla),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final demand = filteredDemands[index];
                      final offersCount = demand.offersCount ??
                          demandProvider.getOffersForDemand(demand.id).length;
                      return _buildDemandCard(
                        context: context,
                        demand: demand,
                        offersCount: offersCount,
                        isBangla: isBangla,
                      );
                    },
                    childCount: filteredDemands.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── KPI Stats Summary Bar ───────────────────────────────────────────────

  Widget _buildKpiStatsBar({
    required int totalCount,
    required int activeCount,
    required int fulfilledCount,
    required int totalOffers,
    required bool isBangla,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'মোট চাহিদা' : 'Total',
              count: '$totalCount',
              icon: Icons.assignment_outlined,
              color: Colors.blueGrey,
              isSelected: _selectedStatus == DemandStatusFilter.all && !_onlyWithOffers,
              onTap: () {
                setState(() {
                  _selectedStatus = DemandStatusFilter.all;
                  _onlyWithOffers = false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'সক্রিয়' : 'Active',
              count: '$activeCount',
              icon: Icons.check_circle_outline,
              color: AppColors.primary,
              isSelected: _selectedStatus == DemandStatusFilter.active && !_onlyWithOffers,
              onTap: () {
                setState(() {
                  _selectedStatus = DemandStatusFilter.active;
                  _onlyWithOffers = false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'অফার প্রাপ্ত' : 'Offers',
              count: '$totalOffers',
              icon: Icons.local_offer_outlined,
              color: const Color(0xFFE65100),
              isSelected: _onlyWithOffers,
              onTap: () {
                setState(() {
                  _onlyWithOffers = !_onlyWithOffers;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'সম্পন্ন' : 'Fulfilled',
              count: '$fulfilledCount',
              icon: Icons.task_alt_outlined,
              color: Colors.indigo,
              isSelected: _selectedStatus == DemandStatusFilter.fulfilled && !_onlyWithOffers,
              onTap: () {
                setState(() {
                  _selectedStatus = DemandStatusFilter.fulfilled;
                  _onlyWithOffers = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: isSelected ? color : Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search & Filter Controls ────────────────────────────────────────────

  Widget _buildSearchAndFilterControls({
    required bool isBangla,
    required List<String> availableDistricts,
    required List<DemandPost> myDemands,
    required DemandProvider demandProvider,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input field
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: isBangla
                    ? 'পণ্য, অবস্থান বা চাহিদা আইডি দিয়ে খুঁজুন...'
                    : 'Search by product, location, or ID...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable quick chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filter bottom sheet button
                InkWell(
                  onTap: () => _showFilterBottomSheet(
                    context,
                    availableDistricts,
                    myDemands,
                    demandProvider,
                    isBangla,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _activeFiltersCount > 0
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _activeFiltersCount > 0 ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: _activeFiltersCount > 0 ? AppColors.primary : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBangla ? 'ফিল্টার' : 'Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _activeFiltersCount > 0 ? AppColors.primary : Colors.grey.shade800,
                          ),
                        ),
                        if (_activeFiltersCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFiltersCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status Chips
                ...DemandStatusFilter.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.grey.shade800,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                    ),
                  );
                }),

                // Quick Toggle: With Offers
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.local_offer,
                      size: 14,
                      color: _onlyWithOffers ? const Color(0xFFE65100) : Colors.grey.shade600,
                    ),
                    label: Text(isBangla ? 'অফার আছে' : 'With Offers'),
                    selected: _onlyWithOffers,
                    selectedColor: const Color(0xFFFFF3E0),
                    checkmarkColor: const Color(0xFFE65100),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _onlyWithOffers ? FontWeight.bold : FontWeight.w500,
                      color: _onlyWithOffers ? const Color(0xFFE65100) : Colors.grey.shade800,
                    ),
                    side: BorderSide(
                      color: _onlyWithOffers ? const Color(0xFFE65100) : Colors.grey.shade300,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _onlyWithOffers = val;
                      });
                    },
                  ),
                ),

                // Quick Trade Type Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<DemandTradeTypeFilter>(
                    initialValue: _selectedTradeType,
                    onSelected: (tradeType) {
                      setState(() {
                        _selectedTradeType = tradeType;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedTradeType != DemandTradeTypeFilter.all
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedTradeType != DemandTradeTypeFilter.all
                              ? Colors.blue.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 13,
                            color: _selectedTradeType != DemandTradeTypeFilter.all
                                ? Colors.blue.shade800
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedTradeType == DemandTradeTypeFilter.all
                                ? (isBangla ? 'বাণিজ্য ধরন' : 'Trade Type')
                                : _selectedTradeType.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedTradeType != DemandTradeTypeFilter.all
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => DemandTradeTypeFilter.values
                        .map(
                          (t) => PopupMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 16, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(t.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // Quick Sort Chip
                PopupMenuButton<DemandSortOption>(
                  initialValue: _selectedSort,
                  onSelected: (sortOption) {
                    setState(() {
                      _selectedSort = sortOption;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedSort != DemandSortOption.newest
                          ? Colors.purple.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedSort != DemandSortOption.newest
                            ? Colors.purple.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedSort.icon,
                          size: 13,
                          color: _selectedSort != DemandSortOption.newest
                              ? Colors.purple.shade800
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedSort.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedSort != DemandSortOption.newest
                                ? Colors.purple.shade800
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => DemandSortOption.values
                      .map(
                        (s) => PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(s.icon, size: 16, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text(s.label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active Filter Tags ──────────────────────────────────────────────────

  Widget _buildActiveFilterTags(bool isBangla) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isBangla ? 'সক্রিয় ফিল্টার:' : 'Active Filters:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          if (_searchQuery.isNotEmpty)
            _buildRemovableTag(
              label: '"$_searchQuery"',
              onRemove: () {
                _searchController.clear();
              },
            ),
          if (_selectedStatus != DemandStatusFilter.all)
            _buildRemovableTag(
              label: 'Status: ${_selectedStatus.label}',
              onRemove: () {
                setState(() => _selectedStatus = DemandStatusFilter.all);
              },
            ),
          if (_selectedTradeType != DemandTradeTypeFilter.all)
            _buildRemovableTag(
              label: 'Trade: ${_selectedTradeType.label}',
              onRemove: () {
                setState(() => _selectedTradeType = DemandTradeTypeFilter.all);
              },
            ),
          if (_onlyWithOffers)
            _buildRemovableTag(
              label: isBangla ? 'অফার আছে' : 'With Offers',
              onRemove: () {
                setState(() => _onlyWithOffers = false);
              },
            ),
          if (_selectedSort != DemandSortOption.newest)
            _buildRemovableTag(
              label: 'Sort: ${_selectedSort.label}',
              onRemove: () {
                setState(() => _selectedSort = DemandSortOption.newest);
              },
            ),
          if (_minPrice != null || _maxPrice != null)
            _buildRemovableTag(
              label: '৳${_minPrice ?? 0} - ${_maxPrice != null ? "৳$_maxPrice" : "∞"}',
              onRemove: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                  _minPriceController.clear();
                  _maxPriceController.clear();
                });
              },
            ),
          if (_selectedDistrict != 'All')
            _buildRemovableTag(
              label: 'Location: $_selectedDistrict',
              onRemove: () {
                setState(() => _selectedDistrict = 'All');
              },
            ),
          InkWell(
            onTap: _resetAllFilters,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                isBangla ? 'সব মুছুন' : 'Clear All',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemovableTag({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ─── Demand Card ─────────────────────────────────────────────────────────

  Widget _buildDemandCard({
    required BuildContext context,
    required DemandPost demand,
    required int offersCount,
    required bool isBangla,
  }) {
    final isAuction = demand.tradeType == TradeType.auction;
    final isBoth = demand.tradeType == TradeType.both;
    final tradeLabel = isAuction ? 'Auction' : (isBoth ? 'Both' : 'Negotiation');
    final tradeColor = isAuction
        ? const Color(0xFFE65100)
        : (isBoth ? const Color(0xFF00796B) : const Color(0xFF1565C0));
    final tradeBg = isAuction
        ? const Color(0xFFFFF3E0)
        : (isBoth ? const Color(0xFFE0F2F1) : const Color(0xFFE3F2FD));
    final tradeIcon = isAuction
        ? Icons.gavel_rounded
        : (isBoth ? Icons.swap_horiz_rounded : Icons.handshake_outlined);

    // Expiry calculation
    final now = DateTime.now();
    final difference = demand.expiryTime.difference(now);
    final isExpired = demand.status == DemandStatus.expired || difference.isNegative;
    final isExpiringSoon = !isExpired && difference.inHours < 48;

    String expiryText;
    Color expiryColor;
    if (isExpired) {
      expiryText = isBangla ? 'মেয়াদোত্তীর্ণ' : 'Expired';
      expiryColor = Colors.grey.shade600;
    } else if (difference.inDays == 0) {
      final hours = difference.inHours;
      expiryText = isBangla
          ? (hours > 0 ? '$hours ঘণ্টা বাকি' : 'আজই শেষ!')
          : (hours > 0 ? '$hours hrs left' : 'Ends today!');
      expiryColor = AppColors.error;
    } else {
      final days = difference.inDays;
      expiryText = isBangla ? '$days দিন বাকি' : '$days days left';
      expiryColor = isExpiringSoon ? const Color(0xFFE65100) : Colors.grey.shade700;
    }

    // Status colors
    Color statusBg;
    Color statusFg;
    String statusLabel;
    IconData statusIcon;
    switch (demand.status) {
      case DemandStatus.active:
        statusBg = const Color(0xFFE8F5E9);
        statusFg = AppColors.primary;
        statusLabel = isBangla ? 'সক্রিয়' : 'Active';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case DemandStatus.fulfilled:
        statusBg = const Color(0xFFE3F2FD);
        statusFg = const Color(0xFF1976D2);
        statusLabel = isBangla ? 'সম্পন্ন' : 'Fulfilled';
        statusIcon = Icons.task_alt_rounded;
        break;
      case DemandStatus.expired:
        statusBg = Colors.grey.shade100;
        statusFg = Colors.grey.shade700;
        statusLabel = isBangla ? 'মেয়াদ শেষ' : 'Expired';
        statusIcon = Icons.timer_off_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DemandOffersScreen(demand: demand)),
            ).then((_) {
              if (mounted) _fetchDemands();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row: Status + Trade Type + Expiry
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusFg),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Trade Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tradeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tradeIcon, size: 12, color: tradeColor),
                          const SizedBox(width: 4),
                          Text(
                            tradeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tradeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Expiry Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExpiringSoon
                            ? AppColors.error.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: isExpiringSoon
                            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpiringSoon ? Icons.alarm_rounded : Icons.schedule_rounded,
                            size: 12,
                            color: expiryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expiryText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.w500,
                              color: expiryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Thumbnail and details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Hero(
                          tag: 'demand_${demand.id}',
                          child: ProductImageView(
                            imageUrl: demand.imageUrl,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Main info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            demand.productName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Quantity & Target Price Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${demand.quantity.toStringAsFixed(demand.quantity.truncateToDouble() == demand.quantity ? 0 : 1)} KG',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_currencyFormat.format(demand.callingPrice)} / KG',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Location row
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  demand.deliveryLocation.isNotEmpty
                                      ? demand.deliveryLocation
                                      : 'Location not specified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom row: Offers Count Badge + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Offers Count Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: offersCount > 0
                            ? const Color(0xFFE8F5E9)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: offersCount > 0
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            offersCount > 0
                                ? Icons.local_offer_rounded
                                : Icons.hourglass_top_rounded,
                            size: 13,
                            color: offersCount > 0 ? AppColors.primary : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            offersCount > 0
                                ? (isBangla
                                    ? '$offersCount টি অফার জমা হয়েছে'
                                    : '$offersCount ${offersCount == 1 ? "Offer" : "Offers"} Received')
                                : (isBangla ? 'অফারের অপেক্ষায়' : 'Awaiting Offers'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: offersCount > 0 ? AppColors.primary : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // View Offers button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isBangla ? 'অফার দেখুন' : 'View Offers',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 13),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DemandOffersScreen(demand: demand)),
                        ).then((_) {
                          if (mounted) _fetchDemands();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filter Bottom Sheet ─────────────────────────────────────────────────

  void _showFilterBottomSheet(
    BuildContext context,
    List<String> availableDistricts,
    List<DemandPost> myDemands,
    DemandProvider demandProvider,
    bool isBangla,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final previewCount = _getFilteredDemands(myDemands, demandProvider).length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBangla ? 'ফিল্টার এবং সাজান' : 'Filter & Sort Demands',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _resetAllFilters();
                            });
                            setState(() {});
                          },
                          child: Text(
                            isBangla ? 'রিসেট করুন' : 'Reset All',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable filter options
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      children: [
                        // 1. Status Filter Section
                        Text(
                          isBangla ? 'চাহিদার অবস্থা (Status)' : 'Demand Status',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DemandStatusFilter.values.map((status) {
                            final selected = _selectedStatus == status;
                            return ChoiceChip(
                              avatar: Icon(
                                status.icon,
                                size: 14,
                                color: selected ? Colors.white : Colors.grey.shade700,
                              ),
                              label: Text(status.label),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.grey.shade800,
                              ),
                              onSelected: (val) {
                                setSheetState(() {
                                  _selectedStatus = status;
                                });
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // 2. Trade Type Filter Section
                        Text(
                          isBangla ? 'বাণিজ্যের ধরন (Trade Type)' : 'Trade Type',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DemandTradeTypeFilter.values.map((tradeType) {
                            final selected = _selectedTradeType == tradeType;
                            return ChoiceChip(
                              avatar: Icon(
                                tradeType.icon,
                                size: 14,
                                color: selected ? Colors.white : Colors.grey.shade700,
                              ),
                              label: Text(tradeType.label),
                              selected: selected,
                              selectedColor: const Color(0xFF1565C0),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.grey.shade800,
                              ),
                              onSelected: (val) {
                                setSheetState(() {
                                  _selectedTradeType = tradeType;
                                });
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // 3. Offers Filter Section
                        Text(
                          isBangla ? 'অফার স্ট্যাটাস (Offers)' : 'Offers Filter',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: Text(isBangla ? 'সব চাহিদা' : 'All Demands'),
                              selected: !_onlyWithOffers,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_onlyWithOffers ? Colors.white : Colors.grey.shade800,
                              ),
                              onSelected: (val) {
                                setSheetState(() => _onlyWithOffers = false);
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              avatar: Icon(
                                Icons.local_offer,
                                size: 14,
                                color: _onlyWithOffers ? Colors.white : const Color(0xFFE65100),
                              ),
                              label: Text(isBangla ? 'অফার প্রাপ্ত চাহিদা' : 'With Offers Only'),
                              selected: _onlyWithOffers,
                              selectedColor: const Color(0xFFE65100),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _onlyWithOffers ? Colors.white : Colors.grey.shade800,
                              ),
                              onSelected: (val) {
                                setSheetState(() => _onlyWithOffers = true);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 4. Sort By Section
                        Text(
                          isBangla ? 'সাজানোর ক্রম (Sort By)' : 'Sort By',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DemandSortOption.values.map((sortOption) {
                            final selected = _selectedSort == sortOption;
                            return ChoiceChip(
                              avatar: Icon(
                                sortOption.icon,
                                size: 14,
                                color: selected ? Colors.white : Colors.grey.shade700,
                              ),
                              label: Text(sortOption.label),
                              selected: selected,
                              selectedColor: const Color(0xFF6A1B9A),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.grey.shade800,
                              ),
                              onSelected: (val) {
                                setSheetState(() {
                                  _selectedSort = sortOption;
                                });
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // 5. Price Range Filter
                        Text(
                          isBangla ? 'সর্বোচ্চ/সর্বনিম্ন কলিং মূল্য (৳)' : 'Calling Price Range (৳/KG)',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  prefixText: '৳ ',
                                  hintText: isBangla ? 'সর্বনিম্ন' : 'Min Price',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) {
                                  setSheetState(() {
                                    _minPrice = double.tryParse(val);
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('—', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  prefixText: '৳ ',
                                  hintText: isBangla ? 'সর্বোচ্চ' : 'Max Price',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) {
                                  setSheetState(() {
                                    _maxPrice = double.tryParse(val);
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 6. District / Delivery Location
                        if (availableDistricts.length > 1) ...[
                          Text(
                            isBangla ? 'ডেলিভারি এলাকা (District)' : 'Delivery Location',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableDistricts.map((district) {
                              final selected = _selectedDistrict == district;
                              return ChoiceChip(
                                label: Text(district),
                                selected: selected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : Colors.grey.shade800,
                                ),
                                onSelected: (val) {
                                  setSheetState(() {
                                    _selectedDistrict = district;
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Apply button
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          isBangla
                              ? 'ফিল্টার প্রয়োগ করুন ($previewCount টি ফলাফল)'
                              : 'Apply Filters ($previewCount ${previewCount == 1 ? "Result" : "Results"})',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Loading Skeleton ────────────────────────────────────────────────────

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 70,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 14,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 160,
                      height: 12,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Error Banner ────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String error, bool isBangla) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBangla ? 'চাহিদা লোড করা যায়নি' : 'Unable to load demands',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                ),
                Text(
                  error,
                  style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _fetchDemands,
            child: Text(
              isBangla ? 'পুনরায় চেষ্টা' : 'Retry',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pure Empty State (0 Demands total) ───────────────────────────────────

  Widget _buildPureEmptyState(bool isBangla) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isBangla ? 'কোন চাহিদা পোস্ট করা হয়নি' : 'No Demands Posted Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isBangla
                  ? 'আপনার প্রয়োজনীয় কৃষিপণ্যের বিবরণ (পরিমাণ, টার্গেট মূল্য, ডেলিভারি স্থান) দিয়ে একটি চাহিদা পোস্ট করুন। দেশের বিভিন্ন প্রান্তের কৃষকরা সরাসরি আপনাকে তাদের সেরা অফার পাঠাবেন।'
                  : 'Post what agricultural produce you need—specifying your quantity, target calling price, and delivery location. Verified farmers will submit competitive offers directly to you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                isBangla ? 'প্রথম চাহিদা পোস্ট করুন' : 'Post Your First Demand',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostDemandScreen()),
                ).then((_) {
                  if (mounted) _fetchDemands();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filtered Empty State (Filtered results == 0) ─────────────────────────

  Widget _buildFilteredEmptyState(bool isBangla) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                size: 48,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isBangla ? 'ফিল্টারের সাথে কোনো চাহিদা মিলেনি' : 'No Demands Match Your Filters',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? (isBangla
                      ? '"$_searchQuery" সম্পর্কিত কোনো চাহিদা পাওয়া যায়নি। ফিল্টার পরিবর্তন করে পুনরায় চেষ্টা করুন।'
                      : 'No demands matching "$_searchQuery" with your active filters. Try broadening your criteria.')
                  : (isBangla
                      ? 'আপনার বর্তমান ফিল্টারের সাথে মিলে এমন কোনো চাহিদা পাওয়া যায়নি। ফিল্টার রিসেট করুন।'
                      : 'None of your posted demands match the current filters. Reset filters to see all your demands.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(
                isBangla ? 'সকল ফিল্টার রিসেট করুন' : 'Reset All Filters',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _resetAllFilters,
            ),
          ],
        ),
      ),
    );
  }
}
