import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../state/negotiation_provider.dart';

class NegotiationsListScreen extends StatefulWidget {
  const NegotiationsListScreen({super.key});

  @override
  State<NegotiationsListScreen> createState() => _NegotiationsListScreenState();
}

class _NegotiationsListScreenState extends State<NegotiationsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Default bearer token from user curl specification
  static const String _defaultCurlToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE2MDc1NCwiZXhwIjoxNzk1MTYxNjU0fQ.jgyCtzVA9VRSEncgD72S_SCSaeIBQ5LLN_O4oUKOVWA';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNegotiations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNegotiations() async {
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
    final provider = context.read<NegotiationProvider>();
    await provider.fetchMyNegotiations(token: token);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final negotiationProvider = context.watch<NegotiationProvider>();
    final negotiations = negotiationProvider.filteredNegotiations;
    final isLoading = negotiationProvider.isLoading;
    final error = negotiationProvider.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'My Negotiations',
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
            tooltip: 'Refresh Negotiations',
            onPressed: isLoading ? null : _fetchNegotiations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNegotiations,
        color: const Color(0xFF2E7D32),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // cURL Endpoint pill / Indicator banner
            _buildCurlEndpointBanner(isLoading, negotiationProvider.negotiations.length),
            const SizedBox(height: 16),

            // Overview summary cards
            _buildSummaryRow(negotiationProvider),
            const SizedBox(height: 16),

            // Search bar
            _buildSearchBar(negotiationProvider),
            const SizedBox(height: 12),

            // Status filter chips
            _buildStatusFilters(negotiationProvider),
            const SizedBox(height: 16),

            // Error banner if any
            if (error != null && negotiations.isEmpty) ...[
              _buildErrorBanner(error),
              const SizedBox(height: 16),
            ],

            // Main Content: Loading, Empty, or List
            if (isLoading && negotiations.isEmpty)
              _buildLoadingState()
            else if (negotiations.isEmpty)
              _buildEmptyState()
            else
              ...negotiations.map(
                (neg) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNegotiationCard(neg, currencyFormat),
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
              '/api/v1/negotiations/my',
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
                  isLoading ? 'Syncing...' : '$totalLoaded deals',
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

  Widget _buildSummaryRow(NegotiationProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Pending',
            count: provider.pendingCount,
            color: const Color(0xFFFFA000),
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Countered',
            count: provider.counteredCount,
            color: const Color(0xFF1976D2),
            icon: Icons.swap_horiz_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Accepted',
            count: provider.acceptedCount,
            color: const Color(0xFF2E7D32),
            icon: Icons.check_circle_outline_rounded,
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

  Widget _buildSearchBar(NegotiationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => provider.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search by product or farmer...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildStatusFilters(NegotiationProvider provider) {
    final filters = ['All', 'Pending', 'Countered', 'Accepted', 'Rejected'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((status) {
          final isSelected = provider.selectedStatus.toLowerCase() == status.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (_) => provider.setSelectedStatus(status),
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

  Widget _buildNegotiationCard(Negotiation neg, NumberFormat currencyFormat) {
    final statusColor = _getStatusColor(neg.status);
    final statusText = _getStatusLabel(neg.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
            // Top row: Product image, Product name, Farmer, and Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: ProductImageView(
                      imageUrl: neg.productImageUrl ?? 'assets/images/potato.png',
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
                        neg.productName ?? 'Agricultural Supply',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            neg.farmerName ?? 'Farmer Abdul',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price Breakdown Box
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
                        'YOUR OFFER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        neg.offerPrice != null
                            ? currencyFormat.format(neg.offerPrice)
                            : '৳-',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  if (neg.counterPrice != null) ...[
                    const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FARMER COUNTER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(neg.counterPrice),
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Message / Note Preview (if available)
            if (neg.message != null && neg.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      neg.message!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Footer: Timestamp & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(neg.createdAt ?? DateTime.now()),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                _buildActionButtons(neg),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Negotiation neg) {
    final provider = context.read<NegotiationProvider>();

    if (neg.status == NegotiationStatus.countered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offer declined.')),
              );
              provider.rejectNegotiation(neg.id);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('Decline', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              provider.acceptCounterOffer(neg.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Counter offer of ৳${neg.counterPrice?.toStringAsFixed(0)} accepted!'),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Accept Deal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (neg.status == NegotiationStatus.accepted) {
      return ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proceeding to order fulfillment...')),
          );
        },
        icon: const Icon(Icons.shopping_bag_outlined, size: 14),
        label: const Text('Checkout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
        ),
      );
    } else {
      return Text(
        'Waiting for response',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade600,
        ),
      );
    }
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
            'Fetching negotiations from server...',
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
            child: Icon(
              Icons.handshake_outlined,
              size: 36,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Negotiations Found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You haven\'t started any price negotiations with farmers yet. Explore products and make direct offers to farmers!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
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
            onPressed: _fetchNegotiations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(NegotiationStatus status) {
    switch (status) {
      case NegotiationStatus.pending:
        return const Color(0xFFFFA000);
      case NegotiationStatus.countered:
        return const Color(0xFF1976D2);
      case NegotiationStatus.accepted:
        return const Color(0xFF2E7D32);
      case NegotiationStatus.rejected:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel(NegotiationStatus status) {
    switch (status) {
      case NegotiationStatus.pending:
        return 'Pending';
      case NegotiationStatus.countered:
        return 'Countered';
      case NegotiationStatus.accepted:
        return 'Accepted';
      case NegotiationStatus.rejected:
        return 'Declined';
    }
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
