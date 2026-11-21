import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../state/demand_provider.dart';

enum OfferSortOption {
  lowestPrice('Lowest Price', Icons.arrow_downward_rounded),
  highestPrice('Highest Price', Icons.arrow_upward_rounded),
  newest('Newest First', Icons.access_time_rounded),
  topRating('Top Rated', Icons.star_rate_rounded);

  final String label;
  final IconData icon;
  const OfferSortOption(this.label, this.icon);
}

class DemandOffersScreen extends StatefulWidget {
  final DemandPost? demand;
  final String? demandId;

  const DemandOffersScreen({
    super.key,
    this.demand,
    this.demandId,
  });

  @override
  State<DemandOffersScreen> createState() => _DemandOffersScreenState();
}

class _DemandOffersScreenState extends State<DemandOffersScreen> {
  static const String fallbackDemandId = 'b93b37c9-64b8-4844-a3a0-95390974aeab';

  late String _effectiveDemandId;
  DemandPost? _currentDemand;
  OfferSortOption _sortOption = OfferSortOption.lowestPrice;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 0,
  );
  final NumberFormat _unitPriceFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 1,
  );

  @override
  void initState() {
    super.initState();
    _currentDemand = widget.demand;
    _effectiveDemandId = widget.demand?.id ?? widget.demandId ?? fallbackDemandId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<DemandProvider>();

    // 1. Fetch offers from backend
    provider.fetchDemandOffers(demandId: _effectiveDemandId).ignore();

    // 2. Fetch fresh demand details if not provided or to ensure latest info
    try {
      final fetchedDemand = await provider.fetchDemandById(demandId: _effectiveDemandId);
      if (mounted) {
        setState(() {
          _currentDemand = fetchedDemand;
        });
      }
    } catch (_) {
      // If fetching demand details fails, retain widget.demand
    }
  }

  List<DemandOffer> _getSortedOffers(List<DemandOffer> offers) {
    final list = List<DemandOffer>.from(offers);
    switch (_sortOption) {
      case OfferSortOption.lowestPrice:
        list.sort((a, b) => a.offerPrice.compareTo(b.offerPrice));
        break;
      case OfferSortOption.highestPrice:
        list.sort((a, b) => b.offerPrice.compareTo(a.offerPrice));
        break;
      case OfferSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case OfferSortOption.topRating:
        list.sort((a, b) {
          final ratingA = a.farmer?.rating ?? 0.0;
          final ratingB = b.farmer?.rating ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final demandProvider = context.watch<DemandProvider>();
    final offers = demandProvider.getOffersForDemand(_effectiveDemandId);
    final isLoading = demandProvider.isOffersLoading && offers.isEmpty;
    final errorMessage = demandProvider.offersError;

    // Use current demand or provider cached detail
    final demand = _currentDemand ?? demandProvider.getDemandDetail(_effectiveDemandId);
    final sortedOffers = _getSortedOffers(offers);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demand Offers',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: AppColors.textPrimary,
              ),
            ),
            if (demand != null)
              Text(
                demand.productName,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh Offers',
            onPressed: demandProvider.isOffersLoading ? null : _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: isLoading
            ? _buildLoadingState()
            : errorMessage != null && offers.isEmpty
                ? _buildErrorState(errorMessage)
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Demand Specifications & Details Header
                      if (demand != null)
                        SliverToBoxAdapter(
                          child: _buildDemandDetailsCard(demand, offers.length),
                        ),

                      // Market Intelligence & Price Comparison Banner
                      if (demand != null && offers.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildOffersIntelligenceBanner(demand, offers),
                        ),

                      // Filter & Sort Bar
                      if (offers.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildSortFilterBar(offers.length),
                        ),

                      // Offers List or Empty State
                      if (offers.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(demand),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final offer = sortedOffers[index];
                                final isBestPrice = _isLowestPrice(offer, offers);
                                return _buildOfferCard(
                                  offer: offer,
                                  demand: demand,
                                  isBestPrice: isBestPrice,
                                );
                              },
                              childCount: sortedOffers.length,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  bool _isLowestPrice(DemandOffer offer, List<DemandOffer> offers) {
    if (offers.isEmpty) return false;
    double lowest = offers.first.offerPrice;
    for (final o in offers) {
      if (o.offerPrice < lowest) {
        lowest = o.offerPrice;
      }
    }
    return (offer.offerPrice - lowest).abs() < 0.01;
  }

  // ─── Demand Details Header Card ─────────────────────────────────────────────

  Widget _buildDemandDetailsCard(DemandPost demand, int totalOffers) {
    final theme = Theme.of(context);
    final totalTargetBudget = demand.quantity * demand.callingPrice;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Image + Main Demand Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Hero(
                    tag: demand.id,
                    child: ProductImageView(
                      imageUrl: demand.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(
                            label: demand.status.name.toUpperCase(),
                            variant: demand.status == DemandStatus.active
                                ? BadgeVariant.success
                                : BadgeVariant.neutral,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: demand.tradeType == TradeType.auction
                                  ? Colors.orange.withValues(alpha: 0.12)
                                  : Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              demand.tradeType.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: demand.tradeType == TradeType.auction
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        demand.productName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              demand.deliveryLocation.isNotEmpty
                                  ? demand.deliveryLocation
                                  : 'Location specified in order',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
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
          ),

          const Divider(height: 1),

          // Key Specifications Matrix
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSpecItem(
                    label: 'Target Price',
                    value: '${_unitPriceFormat.format(demand.callingPrice)}/kg',
                    icon: Icons.sell_outlined,
                    valueColor: AppColors.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildSpecItem(
                    label: 'Required Qty',
                    value: '${NumberFormat('#,##0').format(demand.quantity)} KG',
                    icon: Icons.inventory_2_outlined,
                    valueColor: AppColors.textPrimary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildSpecItem(
                    label: 'Est. Budget',
                    value: _currencyFormat.format(totalTargetBudget),
                    icon: Icons.account_balance_wallet_outlined,
                    valueColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Expiry & Protection Footer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _formatExpiry(demand.expiryTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Escrow Protected',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── Offers Market Intelligence Banner ─────────────────────────────────────

  Widget _buildOffersIntelligenceBanner(
    DemandPost demand,
    List<DemandOffer> offers,
  ) {
    if (offers.isEmpty) return const SizedBox.shrink();

    double lowestPrice = offers.first.offerPrice;
    double highestPrice = offers.first.offerPrice;
    double sum = 0.0;

    for (final o in offers) {
      if (o.offerPrice < lowestPrice) lowestPrice = o.offerPrice;
      if (o.offerPrice > highestPrice) highestPrice = o.offerPrice;
      sum += o.offerPrice;
    }

    final avgPrice = sum / offers.length;
    final maxSavingsPerKg = demand.callingPrice - lowestPrice;
    final totalSavings = maxSavingsPerKg > 0 ? maxSavingsPerKg * demand.quantity : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8F5E9),
            Colors.green.shade50.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Market Intelligence',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${offers.length} Offers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best Offer',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_unitPriceFormat.format(lowestPrice)}/kg',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Offer',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_unitPriceFormat.format(avgPrice)}/kg',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Max Savings',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      totalSavings > 0
                          ? _currencyFormat.format(totalSavings)
                          : 'On Target',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: totalSavings > 0 ? AppColors.primary : Colors.blue.shade700,
                      ),
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

  // ─── Filter & Sort Bar ──────────────────────────────────────────────────────

  Widget _buildSortFilterBar(int totalOffers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Received Offers ($totalOffers)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<OfferSortOption>(
            initialValue: _sortOption,
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(_sortOption.icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _sortOption.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => OfferSortOption.values.map((option) {
              return PopupMenuItem<OfferSortOption>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 16,
                      color: _sortOption == option
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option.label,
                      style: GoogleFonts.outfit(
                        fontWeight: _sortOption == option
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _sortOption == option
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Individual Offer Card ──────────────────────────────────────────────────

  Widget _buildOfferCard({
    required DemandOffer offer,
    required DemandPost? demand,
    required bool isBestPrice,
  }) {
    final farmer = offer.farmer;
    final farmerName = farmer?.name.isNotEmpty == true ? farmer!.name : 'Verified Farmer';
    final district = farmer?.district;
    final phone = farmer?.phone;
    final rating = farmer?.rating ?? 0.0;
    final quantity = demand?.quantity ?? 1000.0;
    final totalOfferPrice = offer.offerPrice * quantity;

    // Price difference against target calling price
    final callingPrice = demand?.callingPrice ?? offer.offerPrice;
    final priceDiff = callingPrice - offer.offerPrice;
    final isCheaper = priceDiff > 0.01;
    final isMoreExpensive = priceDiff < -0.01;
    final isFulfilled = demand?.status == DemandStatus.fulfilled;
    final lastAcceptedOfferId = context.watch<DemandProvider>().lastAcceptedOfferResult?.offerId;
    final isThisOfferAccepted = lastAcceptedOfferId == offer.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBestPrice ? AppColors.primary.withValues(alpha: 0.6) : Colors.grey.shade200,
          width: isBestPrice ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isBestPrice ? 0.05 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best Price ribbon if applicable
          if (isBestPrice)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Best Value Offer',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  if (isCheaper)
                    Text(
                      'Save ${_currencyFormat.format(priceDiff * quantity)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farmer Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Farmer Avatar
                    ClipOval(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: (farmer?.avatarUrl != null &&
                                farmer!.avatarUrl!.isNotEmpty)
                            ? Image.network(
                                farmer.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildAvatarFallback(farmerName),
                              )
                            : _buildAvatarFallback(farmerName),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  farmerName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (district != null && district.isNotEmpty) ...[
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  district,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: rating > 0
                                      ? Colors.amber.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: rating > 0
                                          ? Colors.amber.shade700
                                          : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating > 0 ? rating.toStringAsFixed(1) : 'New',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: rating > 0
                                            ? Colors.amber.shade900
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Submission time
                    Text(
                      _formatRelativeTime(offer.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Pricing Summary Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offered Rate',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _unitPriceFormat.format(offer.offerPrice),
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                ' / kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total for ${NumberFormat('#,##0').format(quantity)} kg',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(totalOfferPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price Difference Badge
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (isCheaper)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_downward_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${_unitPriceFormat.format(priceDiff)} below target (Save ${_currencyFormat.format(priceDiff * quantity)})',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isMoreExpensive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 12,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${_unitPriceFormat.format(priceDiff.abs())} above target',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Exact match with target price',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                  ],
                ),

                // Farmer Note / Delivery Commitment
                if (offer.note != null && offer.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.note!.trim(),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.normal,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons: Call Farmer & Accept Offer
                Row(
                  children: [
                    if (phone != null && phone.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => _handleCallFarmer(phone, farmerName),
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isFulfilled
                            ? null
                            : () => _showAcceptOfferModal(
                                offer: offer,
                                demand: demand,
                                farmerName: farmerName,
                                phone: phone,
                                quantity: quantity,
                                totalPrice: totalOfferPrice,
                              ),
                        icon: Icon(
                          isThisOfferAccepted
                              ? Icons.verified_rounded
                              : (isFulfilled
                                  ? Icons.lock_outline_rounded
                                  : Icons.check_circle_outline),
                          size: 16,
                        ),
                        label: Text(
                          isThisOfferAccepted
                              ? 'Offer Accepted'
                              : (isFulfilled ? 'Demand Fulfilled' : 'Accept Offer'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isThisOfferAccepted
                              ? AppColors.primary
                              : (isFulfilled ? Colors.grey.shade300 : AppColors.primary),
                          foregroundColor: isFulfilled && !isThisOfferAccepted
                              ? Colors.grey.shade600
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Accept Offer Confirmation Modal ────────────────────────────────────────

  void _showAcceptOfferModal({
    required DemandOffer offer,
    required DemandPost? demand,
    required String farmerName,
    required String? phone,
    required double quantity,
    required double totalPrice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Accept Farmer Offer',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review details before locking the agreement in escrow.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Order Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Farmer', farmerName),
                    const Divider(height: 14),
                    _buildModalRow(
                      'Product',
                      demand?.productName ?? 'Demand Item',
                    ),
                    const Divider(height: 14),
                    _buildModalRow(
                      'Agreed Rate',
                      '${_unitPriceFormat.format(offer.offerPrice)} / kg',
                    ),
                    const Divider(height: 14),
                    _buildModalRow(
                      'Quantity',
                      '${NumberFormat('#,##0').format(quantity)} KG',
                    ),
                    const Divider(height: 14),
                    _buildModalRow(
                      'Total Escrow Deposit',
                      _currencyFormat.format(totalPrice),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Escrow notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Escrow Protection Active: Funds are securely held in ChashiBhai Escrow and only released to $farmerName after you confirm delivery receipt.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmAcceptOffer(offer, farmerName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Confirm & Proceed',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAcceptOffer(DemandOffer offer, String farmerName) async {
    final provider = context.read<DemandProvider>();

    // Show loading dialog while processing acceptance
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Accepting offer & creating order...',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await provider.acceptDemandOffer(
        demandId: _effectiveDemandId,
        offerId: offer.id,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

      // Update local state
      setState(() {
        if (_currentDemand != null) {
          _currentDemand = _currentDemand!.copyWith(status: DemandStatus.fulfilled);
        }
      });
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message.isNotEmpty
                      ? result.message
                      : 'Offer accepted! Order created for $farmerName.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

      final errMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errMsg,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _handleCallFarmer(String phone, String name) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $name\'s phone ($phone) to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.amber,
          onPressed: () {},
        ),
      ),
    );
  }

  // ─── Empty & Error & Loading States ─────────────────────────────────────────

  Widget _buildEmptyState(DemandPost? demand) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Offers Received Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farmers haven\'t submitted offers for this demand yet.\nUsually, offers start arriving within 24 hours of posting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Check for New Offers'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Offers',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Skeleton Header Card
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        // Skeleton items
        for (int i = 0; i < 3; i++) ...[
          Container(
            height: 130,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Format Helpers ─────────────────────────────────────────────────────────

  String _formatExpiry(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} days (${DateFormat('MMM d').format(expiryTime)})';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours} hours';
    } else {
      return 'Expires soon';
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'Just now' : '${mins}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Widget _buildAvatarFallback(String farmerName) {
    final initial = farmerName.trim().isNotEmpty
        ? farmerName.trim().substring(0, 1).toUpperCase()
        : 'F';
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: 16,
        ),
      ),
    );
  }
}
