import '../../../../core/models/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import './add_product_screen.dart';
import './edit_product_screen.dart';
import '../../../admin/presentation/views/analytics_screen.dart';
import '../../../account/presentation/views/profile_screen.dart';
import '../../../../core/presentation/widgets/demand_card.dart';
import './demand_details_screen.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _currentIndex = 0;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _filters = [
    'All',
    'Rice (Curl Filter)',
    'Rice',
    'Vegetables',
    'Fruits',
    'Grains',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches own products matching the curl specification:
  /// curl -X 'GET' 'http://localhost:3000/api/v1/products/my?page=1&limit=10&category=rice&tradeType=both&trade_type=both&minPrice=30&min_price=30&maxPrice=100&max_price=100&search=Rice&status=active'
  Future<void> _fetchActiveListings({String? filter}) async {
    final activeFilter = filter ?? _selectedFilter;
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    String? category;
    String? tradeType;
    double? minPrice;
    double? maxPrice;
    String? search;

    if (activeFilter == 'Rice (Curl Filter)') {
      // Matches the exact curl provided by user
      category = 'rice';
      tradeType = 'both';
      minPrice = 30.0;
      maxPrice = 100.0;
      search = 'Rice';
    } else if (activeFilter != 'All') {
      category = activeFilter.toLowerCase();
    }

    if (_searchController.text.trim().isNotEmpty) {
      search = _searchController.text.trim();
    }

    await context.read<ProductProvider>().fetchMyProducts(
      page: 1,
      limit: 10,
      status: 'active',
      category: category,
      tradeType: tradeType,
      minPrice: minPrice,
      maxPrice: maxPrice,
      search: search,
      token: token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context, productProvider, currencyFormat),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Semantics(
              label: 'Add New Product',
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProductScreen()),
                  ).then((_) => _fetchActiveListings());
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                label: const Text('Add Product', style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeTab(
    BuildContext context,
    ProductProvider productProvider,
    NumberFormat currencyFormat,
  ) {
    return RefreshIndicator(
      onRefresh: () => _fetchActiveListings(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildFarmerHeader(context),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(currencyFormat, productProvider.myProducts.length),
                      const SizedBox(height: 32),
                      _buildActiveListingsSection(context, productProvider, currencyFormat),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Buyer Demands',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRecentDemandsList(context, currencyFormat),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListingsSection(
    BuildContext context,
    ProductProvider productProvider,
    NumberFormat currencyFormat,
  ) {
    final myProducts = productProvider.myProducts;
    final isLoading = productProvider.isMyProductsLoading;
    final error = productProvider.myProductsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Your Active Listings',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${myProducts.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    size: 20,
                    color: Colors.grey[700],
                  ),
                  tooltip: _isSearching ? 'Close search' : 'Search listings',
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _fetchActiveListings();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh listings',
                  onPressed: isLoading ? null : () => _fetchActiveListings(),
                ),
              ],
            ),
          ],
        ),
        if (_isSearching) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your active listings (e.g. Rice)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _fetchActiveListings();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _fetchActiveListings(),
          ),
        ],
        const SizedBox(height: 12),
        // Filter chips (including exact curl filter)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              final isCurlFilter = filter.contains('Curl');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurlFilter) ...[
                        Icon(
                          Icons.tune,
                          size: 14,
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: isCurlFilter
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.grey[100],
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : (isCurlFilter
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.grey[300]!),
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    _fetchActiveListings(filter: filter);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Listing content: Loading / Error / Empty / List
        if (isLoading && myProducts.isEmpty)
          _buildLoadingState()
        else if (error != null && myProducts.isEmpty)
          _buildErrorState(error)
        else if (myProducts.isEmpty)
          _buildEmptyState(context)
        else
          _buildListingList(myProducts, currencyFormat),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Fetching active listings from server...',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _fetchActiveListings(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No Active Listings Found',
      subtitle: _selectedFilter == 'All'
          ? 'You haven\'t added any active products yet.'
          : 'No active listings matching "$_selectedFilter".',
      action: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) => _fetchActiveListings());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildFarmerHeader(BuildContext context) {
    return Semantics(
      label: 'Farmer Dashboard Header',
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {
                    ScaffoldState? scaffold = Scaffold.maybeOf(context);
                    if (scaffold == null || !scaffold.hasDrawer) {
                      scaffold = context.findRootAncestorStateOfType<ScaffoldState>();
                    }
                    scaffold?.openDrawer();
                  },
                ),
                Text(
                  'Farmer Dashboard',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Total Earnings',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 16),
            ),
            Text(
              '৳ 84,250.00',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(NumberFormat currencyFormat, int activeCount) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Active Listings', '$activeCount', Icons.inventory_2_outlined, Colors.green),
        _buildStatCard('Active Bids', '12', Icons.gavel, Colors.orange),
        _buildStatCard('Pending Deals', '5', Icons.handshake, Colors.blue),
        _buildStatCard('Wallet', '৳12,000', Icons.account_balance_wallet, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingList(List<Product> products, NumberFormat currencyFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        Color tradeBadgeBg;
        Color tradeBadgeText;
        String tradeText;

        switch (product.tradeType) {
          case TradeType.auction:
            tradeBadgeBg = Colors.orange.withValues(alpha: 0.1);
            tradeBadgeText = Colors.orange.shade800;
            tradeText = 'AUCTION';
            break;
          case TradeType.negotiation:
            tradeBadgeBg = Colors.blue.withValues(alpha: 0.1);
            tradeBadgeText = Colors.blue.shade800;
            tradeText = 'NEGOTIATION';
            break;
          case TradeType.both:
            tradeBadgeBg = Colors.teal.withValues(alpha: 0.1);
            tradeBadgeText = Colors.teal.shade800;
            tradeText = 'BOTH';
            break;
        }

        return Semantics(
          label: 'Listing Card for ${product.productName}',
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: product),
                  ),
                ).then((_) => _fetchActiveListings());
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Semantics(
                        image: true,
                        label: 'Product Image',
                        child: ProductImageView(
                          imageUrl: product.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.quantity} ${product.unit} listed',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (product.category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tradeBadgeBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tradeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tradeBadgeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(product.minimumPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey[400]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentDemandsList(BuildContext context, NumberFormat currencyFormat) {
    final demands = context.watch<DemandProvider>().demands;
    if (demands.isEmpty) return const Text('No recent demands.');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: demands.length > 3 ? 3 : demands.length,
      itemBuilder: (context, index) {
        final demand = demands[index];
        return Semantics(
          label: 'Demand Card for ${demand.productName}',
          child: DemandCard(
            demand: demand,
            currencyFormat: currencyFormat,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DemandDetailsScreen(demand: demand),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
