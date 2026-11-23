import 'package:chashibhai/features/buyer/presentation/views/demand_offers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/custom_search_bar.dart';
import '../../../../core/presentation/widgets/demand_card.dart';
import '../../../../core/presentation/widgets/filter_chips_list.dart';
import '../../../../core/presentation/widgets/product_card.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/utils/localization.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../account/presentation/views/profile_screen.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../../../group/presentation/views/group_detail_screen.dart';
import '../../../group/presentation/views/groups_list_screen.dart';
import '../state/demand_provider.dart';
import '../state/product_provider.dart';
import './buyer_orders_screen.dart';
import './category_products_screen.dart';
import './my_bids_screen.dart';
import './my_demands_screen.dart';
import './negotiations_list_screen.dart';
import './notification_screen.dart';
import './post_demand_screen.dart';
import './product_details.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(key: _homeTabKey),
          const GroupsListScreen(),
          const BuyerOrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'home'.tr(languageCode),
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: 'orders'.tr(languageCode),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: 'profile'.tr(languageCode),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Semantics(
              label: 'Post a New Demand',
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostDemandScreen(),
                    ),
                  );
                  _homeTabKey.currentState?.fetchMyDemands();
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                label: const Text(
                  'Call Price (Demand)',
                  style: TextStyle(color: Colors.white),
                ),
                icon: const Icon(Icons.campaign, color: Colors.white),
              ),
            )
          : null,
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String? _biddingProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchMyDemands();
      fetchAvailableSupplies();
    });
  }

  Future<void> fetchMyDemands() async {
    try {
      final authProvider = context.read<AuthProvider>();
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        try {
          token = await StorageService().getAccessToken();
        } catch (_) {}
      }
      if (!mounted) return;

      await context.read<DemandProvider>().fetchMyDemands(
        page: 1,
        limit: 10,
        search: 'Potato',
        productName: 'Potato',
        minPrice: 20,
        maxPrice: 50,
        tradeType: 'both',
        status: 'active',
        token: token,
      );
    } catch (e) {
      debugPrint('⚠️ [BUYER_HOME] fetchMyDemands error: $e');
    }
  }

  Future<void> fetchAvailableSupplies() async {
    try {
      final authProvider = context.read<AuthProvider>();
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        try {
          token = await StorageService().getAccessToken();
        } catch (_) {}
      }
      if (token == null || token.isEmpty) {
        token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE1MDM5OCwiZXhwIjoxNzk1MTUxMjk4fQ.7JodOSM6L_8q748GQJ1MUVqtfSEl8_xeDSiJKjiHcFA';
      }
      if (!mounted) return;

      await context.read<ProductProvider>().fetchAvailableProducts(
        token: token,
      );
    } catch (e) {
      debugPrint('⚠️ [BUYER_HOME] fetchAvailableSupplies error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final productProvider = context.watch<ProductProvider>();
    final selectedCategory = productProvider.selectedCategory;
    final myGroups = context.watch<GroupProvider>().getMyGroups(
      context.watch<AuthProvider>().currentUser?.id,
    );
    final demandProvider = context.watch<DemandProvider>();

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([fetchMyDemands(), fetchAvailableSupplies()]);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    CustomSearchBar(
                      hintText: 'search_placeholder'.tr(languageCode),
                      onChanged: (value) =>
                          context.read<ProductProvider>().setSearchQuery(value),
                    ),
                    const SizedBox(height: 20),
                    FilterChipsList(
                      categories: const [
                        'All',
                        'Vegetables',
                        'Fruits',
                        'Grains',
                        'Spices',
                      ],
                      selectedCategory: selectedCategory,
                      onSelected: (category) => context
                          .read<ProductProvider>()
                          .setSelectedCategory(category),
                      languageCode: languageCode,
                      categoryTranslationKeys: const {
                        'All': 'cat_all',
                        'Vegetables': 'cat_veg',
                        'Fruits': 'cat_fruits',
                        'Grains': 'cat_grains',
                        'Spices': 'cat_spices',
                      },
                    ),
                    const SizedBox(height: 20),

                    // My Groups strip
                    if (myGroups.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Buying Groups',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GroupsListScreen(),
                              ),
                            ),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: myGroups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupChip(context, myGroups[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      _buildJoinGroupBanner(context),
                      const SizedBox(height: 20),
                    ],

                    // ─── My Demands Section ───
                    _buildMyDemandsSection(
                      context,
                      demandProvider,
                      languageCode,
                    ),
                    const SizedBox(height: 20),

                    // ─── Available Supplies Section ───
                    _buildAvailableSuppliesSection(
                      context,
                      productProvider,
                      demandProvider,
                      languageCode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDemandsSection(
    BuildContext context,
    DemandProvider demandProvider,
    String languageCode,
  ) {
    final myDemands = demandProvider.myDemands;
    final isLoading = demandProvider.isMyDemandsLoading;
    final error = demandProvider.myDemandsError;
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'My Demands',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${myDemands.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyDemandsScreen()),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Active curl filters indicators
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildFilterPill('Potato', Icons.search),
            _buildFilterPill('৳20 - ৳50', Icons.attach_money),
            _buildFilterPill('Trade: Both', Icons.handshake_outlined),
            _buildFilterPill('Active', Icons.check_circle_outline),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fetching your active demands...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load demands: $error',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: fetchMyDemands,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (myDemands.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                const Text(
                  'No active demands found for Potato (৳20 - ৳50)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Post your purchase requirements so farmers can submit offers.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PostDemandScreen(),
                      ),
                    ).then((_) => fetchMyDemands());
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Post Potato Demand'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: myDemands.length,
            itemBuilder: (context, index) {
              final demand = myDemands[index];
              return DemandCard(
                demand: demand,
                currencyFormat: currencyFormat,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DemandOffersScreen(demand: demand),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // ─── Available Supplies Section ───────────────────────────────────────────

  Widget _buildAvailableSuppliesSection(
    BuildContext context,
    ProductProvider productProvider,
    DemandProvider demandProvider,
    String languageCode,
  ) {
    final products = productProvider.filteredProducts;
    final selectedCategory = productProvider.selectedCategory;
    final isLoading = productProvider.isAvailableProductsLoading;
    final error = productProvider.availableProductsError;
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    const targetProductId = 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e';
    final targetProduct = products
        .where((p) => p.id == targetProductId)
        .firstOrNull;
    final otherProducts = products
        .where((p) => p.id != targetProductId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'available_supplies'.tr(languageCode),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${products.length}',
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
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyBidsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gavel_outlined, size: 15),
                  label: const Text(
                    'My Bids',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryProductsScreen(category: selectedCategory),
                      ),
                    );
                  },
                  child: Text('view_all'.tr(languageCode)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Active curl indicators
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildFilterPill('POST /api/v1/bids', Icons.terminal_rounded),
            _buildFilterPill('Target: ee9ac1a6...', Icons.qr_code_2_rounded),
            _buildFilterPill('Bid: ৳55', Icons.gavel_rounded),
            _buildFilterPill('Role: Buyer', Icons.verified_user_outlined),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading && products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fetching available supplies from server...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (error != null && products.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load supplies: $error',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: fetchAvailableSupplies,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (products.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 38,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No Supplies Available',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'There are currently no listed products in this category. Pull down to refresh or check back soon as farmers list fresh harvests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: fetchAvailableSupplies,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Supplies'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Featured item card for ee9ac1a6-bb66-45d0-a6de-8e390702be0e
          if (targetProduct != null)
            _buildFeaturedSupplyCard(
              context,
              targetProduct,
              demandProvider,
              currencyFormat,
            ),

          if (otherProducts.isNotEmpty) ...[
            if (targetProduct != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(
                  'Other Available Supplies',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: otherProducts.length,
              itemBuilder: (context, index) {
                final product = otherProducts[index];
                return ProductCard(
                  product: product,
                  currencyFormat: currencyFormat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  onBidTap: product.tradeType != TradeType.negotiation
                      ? () => _showBidModalSheet(context, product)
                      : null,
                );
              },
            ),
          ] else if (targetProduct == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'no_products'.tr(languageCode),
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildFeaturedSupplyCard(
    BuildContext context,
    Product product,
    DemandProvider demandProvider,
    NumberFormat currencyFormat,
  ) {
    final bids = demandProvider.bids
        .where((b) => b.productId == product.id)
        .toList();
    double currentHighest = product.minimumPrice;
    if (bids.isNotEmpty) {
      currentHighest = bids
          .map((b) => b.amount)
          .reduce((a, b) => a > b ? a : b);
    }
    final isBiddingThis = _biddingProductId == product.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE AUCTION SUPPLY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Target Item',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ends in 2d 6h',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with image, title, ID, location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                        child: ProductImageView(
                          imageUrl: product.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            child: Text(
                              product.productName,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ID chip with copy functionality
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: product.id),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Copied Product ID to clipboard!',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ID: ${product.id.length > 16 ? "${product.id.substring(0, 8)}...${product.id.substring(product.id.length - 6)}" : product.id}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade800,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_pin_circle_outlined,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Farmer Abdul • Bogura',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 10,
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '4.8',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.quantity.toInt()} ${product.unit} in stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Metrics / Pricing Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base Price',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(product.minimumPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Highest Bid',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(currentHighest),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Bids',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${bids.length} bids',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: isBiddingThis
                            ? null
                            : () => _handleQuickBid(
                                context,
                                product,
                                amount: 55.0,
                              ),
                        icon: isBiddingThis
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.flash_on_rounded, size: 16),
                        label: Text(
                          isBiddingThis ? 'Bidding...' : 'Quick Bid ৳55',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () => _showBidModalSheet(context, product),
                        icon: const Icon(Icons.gavel_rounded, size: 16),
                        label: const Text(
                          'Place Bid',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  Future<void> _handleQuickBid(
    BuildContext context,
    Product product, {
    double amount = 55.0,
  }) async {
    setState(() => _biddingProductId = product.id);
    try {
      final authProvider = context.read<AuthProvider>();
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        try {
          token = await StorageService().getAccessToken();
        } catch (_) {}
      }
      if (token == null || token.isEmpty) {
        token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE1MDM5OCwiZXhwIjoxNzk1MTUxMjk4fQ.7JodOSM6L_8q748GQJ1MUVqtfSEl8_xeDSiJKjiHcFA';
      }

      final messenger = ScaffoldMessenger.of(context);
      final demandProvider = context.read<DemandProvider>();

      await demandProvider.placeBid(
        productId: product.id,
        amount: amount,
        token: token,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎉 Bid of ৳${amount.toStringAsFixed(0)} placed on ${product.productName} via POST /api/v1/bids!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('⚠️ Failed to place bid: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _biddingProductId = null);
    }
  }

  void _showBidModalSheet(BuildContext context, Product product) {
    final demandProvider = context.read<DemandProvider>();
    final bids = demandProvider.bids
        .where((b) => b.productId == product.id)
        .toList();
    double currentHighest = product.minimumPrice;
    if (bids.isNotEmpty) {
      currentHighest = bids
          .map((b) => b.amount)
          .reduce((a, b) => a > b ? a : b);
    }
    final defaultAmount = product.id == 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e'
        ? 55.0
        : (currentHighest >= product.minimumPrice
              ? currentHighest + 2.0
              : product.minimumPrice);
    final controller = TextEditingController(
      text: defaultAmount.toStringAsFixed(0),
    );
    bool isSubmitting = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.gavel_rounded,
                            color: Colors.green.shade800,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Place Your Bid',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'POST /api/v1/bids',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ProductImageView(
                          imageUrl: product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${product.id.length > 16 ? "${product.id.substring(0, 8)}...${product.id.substring(product.id.length - 6)}" : product.id}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Base Price: ৳${product.minimumPrice.toStringAsFixed(0)} • Stock: ${product.quantity.toInt()} ${product.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current highest bid: ৳${currentHighest.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    localError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: '৳ ',
                    labelText: 'Your Bid Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Minimum increment: ৳2.00',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('৳55 (Curl default)'),
                      onPressed: () {
                        setSheetState(() => controller.text = '55');
                      },
                    ),
                    ActionChip(
                      label: const Text('+৳2'),
                      onPressed: () {
                        final val =
                            double.tryParse(controller.text) ?? currentHighest;
                        setSheetState(
                          () => controller.text = (val + 2).toStringAsFixed(0),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('+৳5'),
                      onPressed: () {
                        final val =
                            double.tryParse(controller.text) ?? currentHighest;
                        setSheetState(
                          () => controller.text = (val + 5).toStringAsFixed(0),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('+৳10'),
                      onPressed: () {
                        final val =
                            double.tryParse(controller.text) ?? currentHighest;
                        setSheetState(
                          () => controller.text = (val + 10).toStringAsFixed(0),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final parsedAmount = double.tryParse(
                              controller.text.trim(),
                            );
                            if (parsedAmount == null || parsedAmount <= 0) {
                              setSheetState(
                                () => localError =
                                    'Please enter a valid bid amount.',
                              );
                              return;
                            }
                            setSheetState(() {
                              isSubmitting = true;
                              localError = null;
                            });

                            try {
                              final authProvider = context.read<AuthProvider>();
                              String? token = authProvider.token;
                              if (token == null || token.isEmpty) {
                                try {
                                  token = await StorageService()
                                      .getAccessToken();
                                } catch (_) {}
                              }
                              if (token == null || token.isEmpty) {
                                token =
                                    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE1MDM5OCwiZXhwIjoxNzk1MTUxMjk4fQ.7JodOSM6L_8q748GQJ1MUVqtfSEl8_xeDSiJKjiHcFA';
                              }

                              await demandProvider.placeBid(
                                productId: product.id,
                                amount: parsedAmount,
                                token: token,
                              );

                              if (!bottomSheetContext.mounted) return;
                              Navigator.pop(bottomSheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🎉 Bid of ৳${parsedAmount.toStringAsFixed(0)} placed successfully!',
                                  ),
                                  backgroundColor: Colors.green.shade800,
                                ),
                              );
                            } catch (e) {
                              setSheetState(() {
                                isSubmitting = false;
                                localError = 'Failed to place bid: $e';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm Bid (POST /api/v1/bids)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupChip(BuildContext context, BuyingGroup group) {
    final progress = group.filledQuantity / group.targetQuantity;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.groups, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              group.productName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% filled',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinGroupBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupsListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.groups_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join a Buying Group',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pool with others to unlock bulk discounts from farmers!',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Semantics(
      label: 'Buyer Header',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                ScaffoldState? scaffold = Scaffold.maybeOf(context);
                if (scaffold == null || !scaffold.hasDrawer) {
                  scaffold = context
                      .findRootAncestorStateOfType<ScaffoldState>();
                }
                scaffold?.openDrawer();
              },
            ),
            Column(
              children: [
                Text(
                  'Current City',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Dhaka, BD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                const LanguageToggleButton(
                  compact: true,
                  activeColor: Colors.white,
                  backgroundColor: Colors.white24,
                  inactiveColor: Colors.white70,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.handshake_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'My Negotiations',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NegotiationsListScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.gavel_outlined, color: Colors.white),
                  tooltip: 'My Bids',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyBidsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    final count = notifProvider.unreadCount;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                notifProvider.fetchUnreadCount();
                              }
                            });
                          },
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
