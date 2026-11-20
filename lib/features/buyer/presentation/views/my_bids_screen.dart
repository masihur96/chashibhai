import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../state/demand_provider.dart';
import '../state/product_provider.dart';
import './product_details.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  /// Default bearer token from user curl specification
  static const String _defaultCurlToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE2NDIxMiwiZXhwIjoxNzk1MTY1MTEyfQ.YQmIE4_tvYuZdMQonDMTJWXI6baALYW-Ee5kD5Fbl0E';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBids();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBids() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    String? token = authProvider.token;
    if (token == null || token.isEmpty) {
      try {
        token = await StorageService().getAccessToken();
      } catch (_) {}
    }
    if (token == null || token.isEmpty) {
      token = _defaultCurlToken;
    }

    if (!mounted) return;
    final demandProvider = context.read<DemandProvider>();
    await demandProvider.fetchMyBids(token: token);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final demandProvider = context.watch<DemandProvider>();
    final allBids = demandProvider.myBids;
    final isLoading = demandProvider.isMyBidsLoading;
    final error = demandProvider.myBidsError;

    // Filter by tab & search query
    final filteredBids = allBids.where((b) {
      final statusLower = (b.status ?? '').toLowerCase();
      final isWinning = b.isWinning == true || statusLower == 'winning' || statusLower == 'active';
      final isOutbid = b.isWinning == false || statusLower == 'outbid';

      bool matchesStatus = true;
      if (_selectedFilter == 'Winning') {
        matchesStatus = isWinning && statusLower != 'outbid';
      } else if (_selectedFilter == 'Outbid') {
        matchesStatus = isOutbid;
      }

      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          (b.productName?.toLowerCase().contains(query) ?? false) ||
          b.productId.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    final winningCount = allBids.where((b) =>
        (b.isWinning == true || (b.status ?? '').toLowerCase() == 'winning') &&
        (b.status ?? '').toLowerCase() != 'outbid').length;
    final outbidCount = allBids.where((b) =>
        b.isWinning == false || (b.status ?? '').toLowerCase() == 'outbid').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'My Bids',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Bids',
            onPressed: isLoading ? null : _fetchBids,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBids,
        color: const Color(0xFF2E7D32),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // cURL Endpoint pill banner
            _buildCurlEndpointBanner(isLoading, allBids.length),
            const SizedBox(height: 16),

            // Summary metrics row
            _buildSummaryRow(
              totalCount: allBids.length,
              winningCount: winningCount,
              outbidCount: outbidCount,
            ),
            const SizedBox(height: 16),

            // Search bar
            _buildSearchBar(),
            const SizedBox(height: 12),

            // Filter chips
            _buildFilterChips(
              totalCount: allBids.length,
              winningCount: winningCount,
              outbidCount: outbidCount,
            ),
            const SizedBox(height: 16),

            // Error banner if any
            if (error != null && allBids.isEmpty) ...[
              _buildErrorBanner(error),
              const SizedBox(height: 16),
            ],

            // Main Content: Loading, Empty, or List
            if (isLoading && allBids.isEmpty)
              _buildLoadingState()
            else if (filteredBids.isEmpty)
              _buildEmptyState()
            else
              ...filteredBids.map(
                (bid) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBidCard(bid, currencyFormat),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurlEndpointBanner(bool isLoading, int totalLoaded) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'GET',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '/api/v1/bids/my',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLoading ? Colors.amber.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLoading ? Colors.amber.shade300 : Colors.green.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.amber.shade700 : const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isLoading ? 'Syncing...' : '$totalLoaded bids',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLoading ? Colors.amber.shade900 : Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required int totalCount,
    required int winningCount,
    required int outbidCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Total Bids',
            count: totalCount,
            color: Colors.grey.shade800,
            icon: Icons.gavel_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Leading',
            count: winningCount,
            color: const Color(0xFF2E7D32),
            icon: Icons.emoji_events_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Outbid',
            count: outbidCount,
            color: const Color(0xFFE65100),
            icon: Icons.trending_down_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by product name...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required int totalCount,
    required int winningCount,
    required int outbidCount,
  }) {
    final filters = [
      {'label': 'All', 'count': totalCount},
      {'label': 'Winning', 'count': winningCount},
      {'label': 'Outbid', 'count': outbidCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final isSelected = _selectedFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('$label ($count)'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = label),
              selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBidCard(Bid bid, NumberFormat currencyFormat) {
    final statusLower = (bid.status ?? '').toLowerCase();
    final isOutbid = bid.isWinning == false || statusLower == 'outbid';
    final isWinning = (bid.isWinning == true || statusLower == 'winning' || statusLower == 'active') && !isOutbid;

    final badgeColor = isWinning ? const Color(0xFF2E7D32) : (isOutbid ? const Color(0xFFE65100) : Colors.blue.shade700);
    final badgeLabel = isWinning ? '👑 HIGHEST BID' : (isOutbid ? '⚠️ OUTBID' : 'ACTIVE BID');

    final effectiveName = bid.productName ?? 'Agricultural Supply (${bid.productId.length > 8 ? bid.productId.substring(0, 8) : bid.productId})';
    final effectiveImage = bid.productImageUrl ?? 'assets/images/potato.png';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinning ? Colors.green.shade300 : (isOutbid ? Colors.orange.shade300 : Colors.grey.shade200),
          width: isWinning ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Product image, Product name, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: ProductImageView(
                      imageUrl: effectiveImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${bid.productId.length > 10 ? bid.productId.substring(0, 10) : bid.productId}...',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price Details Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR BID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(bid.amount),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  if (bid.currentHighestBid != null && isOutbid) ...[
                    const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CURRENT HIGHEST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(bid.currentHighestBid),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Footer: Timestamp & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(bid.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => _openAuctionDetails(bid),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      child: const Text('View Auction', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                    ),
                    if (isOutbid) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _openAuctionDetails(bid),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Increase Bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAuctionDetails(Bid bid) {
    // Find or create product object to navigate to ProductDetailsScreen
    final productProvider = context.read<ProductProvider>();
    final matchedProduct = productProvider.products.firstWhere(
      (p) => p.id == bid.productId,
      orElse: () => Product(
        id: bid.productId,
        farmerId: 'f1',
        productName: bid.productName ?? 'Auction Supply',
        imageUrl: bid.productImageUrl ?? 'assets/images/potato.png',
        quantity: 500,
        unit: bid.productUnit ?? 'KG',
        minimumPrice: bid.productMinimumPrice ?? bid.amount,
        tradeType: TradeType.auction,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: bid.productEndTime ?? DateTime.now().add(const Duration(days: 2)),
        category: 'Vegetables',
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(product: matchedProduct),
      ),
    ).then((_) {
      // Re-fetch bids upon returning in case new bid was placed
      _fetchBids();
    });
  }

  Widget _buildLoadingState() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(height: 14),
          Text(
            'Fetching your bids from server...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.green.shade50,
            child: const Icon(
              Icons.gavel_rounded,
              size: 36,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bids Found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You haven\'t placed any bids on live auctions yet. Browse available supplies and place bids to get the best produce prices!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.storefront_outlined, size: 16),
            label: const Text('Browse Live Auctions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _fetchBids,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }
}
