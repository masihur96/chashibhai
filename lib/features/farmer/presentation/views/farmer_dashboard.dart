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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with SingleTickerProviderStateMixin {
  // GlobalKey so ALL tabs can open the same root Scaffold drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = [
    'All',
    'Rice',
    'Vegetables',
    'Fruits',
    'Grains',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchActiveListings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _fetchActiveListings({String? filter}) async {
    final activeFilter = filter ?? _selectedFilter;
    final token = context.read<AuthProvider>().token;
    String? category;
    String? search;
    if (activeFilter != 'All') category = activeFilter.toLowerCase();
    if (_searchController.text.trim().isNotEmpty) {
      search = _searchController.text.trim();
    }
    await context.read<ProductProvider>().fetchMyProducts(
          page: 1,
          limit: 10,
          status: 'active',
          category: category,
          search: search,
          token: token,
        );
  }

  // ─── Root Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat =
        NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3F5F8),
      // ── Drawer (accessible from all tabs via _openDrawer()) ──────────────────
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context, productProvider, currencyFormat),
          // Wrap child screens so they can still open the root drawer
          _TabShell(onMenuTap: _openDrawer, child: const AnalyticsScreen()),
          _TabShell(onMenuTap: _openDrawer, child: const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton:
          _currentIndex == 0 ? _buildFAB(context) : null,
    );
  }

  // ─── Bottom Navigation ───────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined, color: Colors.grey[500]),
            selectedIcon:
                const Icon(Icons.space_dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.grey[500]),
            selectedIcon:
                const Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Colors.grey[500]),
            selectedIcon:
                const Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────────────

  Widget _buildFAB(BuildContext context) {
    return Semantics(
      label: 'Add New Product',
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ).then((_) => _fetchActiveListings()),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Product',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── Home Tab ────────────────────────────────────────────────────────────────

  Widget _buildHomeTab(
    BuildContext context,
    ProductProvider productProvider,
    NumberFormat currencyFormat,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchActiveListings(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildStatsGrid(productProvider.myProducts.length),
                        const SizedBox(height: 28),
                        _buildActiveListingsSection(
                            context, productProvider, currencyFormat),
                        const SizedBox(height: 28),
                        _buildRecentDemandsSection(context, currencyFormat),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sliver AppBar ───────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        tooltip: 'Open Menu',
        onPressed: _openDrawer,
      ),
      title: Text(
        'ChaShiBhai',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        _NotificationBell(),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _buildHeaderBackground(user),
      ),
    );
  }

  Widget _buildHeaderBackground(AppUser? user) {
    final greeting = _greeting();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              _buildAvatar(user),
              const SizedBox(width: 14),
              // Greeting + Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'Farmer',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user?.district != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.65)),
                            const SizedBox(width: 3),
                            Text(
                              user!.district!,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Earnings card
              _buildEarningsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser? user) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: ClipOval(
        child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
            ? Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              )
            : const Icon(Icons.person_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Total Earnings',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '৳ 84,250',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 11, color: Colors.greenAccent.shade100),
              const SizedBox(width: 3),
              Text(
                '+8.2% this month',
                style: GoogleFonts.outfit(
                  color: Colors.greenAccent.shade100,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌱';
    if (h < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  // ─── Stats Grid ──────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(int activeCount) {
    final stats = [
      _Stat('Active Listings', '$activeCount', Icons.storefront_outlined,
          AppColors.success, '+2 this week', true),
      _Stat('Active Bids', '12', Icons.gavel_rounded,
          const Color(0xFFF57C00), '3 ending soon', false),
      _Stat('Pending Deals', '5', Icons.handshake_outlined,
          const Color(0xFF1565C0), '1 awaiting you', false),
      _Stat('Wallet Balance', '৳ 12,000',
          Icons.account_balance_wallet_outlined,
          const Color(0xFF6A1B9A), 'Available', true),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.52,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_Stat s) {
    final trendColor = s.up ? AppColors.success : const Color(0xFFE65100);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: s.color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + trend icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s.icon, color: s.color, size: 18),
              ),
              Icon(
                s.up ? Icons.trending_up_rounded : Icons.access_time_rounded,
                size: 16,
                color: trendColor,
              ),
            ],
          ),
          // Value + label + trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                s.title,
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.trend,
                style: GoogleFonts.outfit(
                  color: trendColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Active Listings Section ─────────────────────────────────────────────────

  Widget _buildActiveListingsSection(
    BuildContext context,
    ProductProvider productProvider,
    NumberFormat currencyFormat,
  ) {
    final products = productProvider.myProducts;
    final isLoading = productProvider.isMyProductsLoading;
    final error = productProvider.myProductsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          title: 'Active Listings',
          count: isLoading ? null : products.length,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBtn(
                icon: _isSearching
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                tooltip: _isSearching ? 'Close search' : 'Search',
                onTap: () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _fetchActiveListings();
                  }
                }),
              ),
              const SizedBox(width: 6),
              _IconBtn(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: isLoading ? null : () => _fetchActiveListings(),
              ),
            ],
          ),
        ),

        // Search bar (animated)
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _isSearching
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildSearchField(),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 14),

        // Filter chips
        _buildFilterChips(),

        const SizedBox(height: 16),

        // Content
        if (isLoading && products.isEmpty)
          _buildShimmerList()
        else if (error != null && products.isEmpty)
          _buildErrorCard(error)
        else if (products.isEmpty)
          _buildEmptyState(context)
        else
          _buildProductList(context, products, currencyFormat),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search listings (e.g. Rice, Wheat…)',
        hintStyle:
            GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 20, color: AppColors.primary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _fetchActiveListings();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _fetchActiveListings(),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final selected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = f);
                _fetchActiveListings(filter: f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.grey.shade200,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  f,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Listing States ──────────────────────────────────────────────────────────

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const _ShimmerBox(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child:
                Icon(Icons.wifi_off_rounded, color: Colors.red.shade600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load listings',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      fontSize: 14),
                ),
                Text(
                  error,
                  style: GoogleFonts.outfit(
                      color: Colors.red.shade600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _fetchActiveListings(),
            child: Text('Retry',
                style: GoogleFonts.outfit(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No Active Listings',
      subtitle: _selectedFilter == 'All'
          ? 'Start by adding your first product to reach buyers.'
          : 'No listings in "$_selectedFilter". Try a different category.',
      action: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ).then((_) => _fetchActiveListings()),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add First Product',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─── Product Cards ───────────────────────────────────────────────────────────

  Widget _buildProductList(
    BuildContext context,
    List<Product> products,
    NumberFormat fmt,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (_, i) => _buildProductCard(context, products[i], fmt),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    NumberFormat fmt,
  ) {
    final trade = _tradeInfo(product.tradeType);

    return Semantics(
      label: 'Listing: ${product.productName}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditProductScreen(product: product)),
            ).then((_) => _fetchActiveListings()),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImageView(
                      imageUrl: product.imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.productName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _ActiveDot(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.quantity} ${product.unit} available',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (product.category.isNotEmpty)
                              _Chip(product.category.toUpperCase(),
                                  Colors.grey.shade100,
                                  Colors.grey.shade700),
                            _Chip(trade.label, trade.bg, trade.fg),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fmt.format(product.minimumPrice),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'min price',
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 11, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _TradeMeta _tradeInfo(TradeType type) {
    switch (type) {
      case TradeType.auction:
        return _TradeMeta('AUCTION', const Color(0xFFFFF3E0),
            const Color(0xFFE65100));
      case TradeType.negotiation:
        return _TradeMeta('NEGOTIATE', const Color(0xFFE3F2FD),
            const Color(0xFF0D47A1));
      case TradeType.both:
        return _TradeMeta(
            'BOTH', const Color(0xFFE0F2F1), const Color(0xFF004D40));
    }
  }

  // ─── Recent Demands ──────────────────────────────────────────────────────────

  Widget _buildRecentDemandsSection(
      BuildContext context, NumberFormat currencyFormat) {
    final demands = context.watch<DemandProvider>().demands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent Buyer Demands',
          trailing: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
            ),
            child: Text('View All',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 14),
        if (demands.isEmpty)
          _buildNoDemandsCard()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: demands.length > 3 ? 3 : demands.length,
            itemBuilder: (_, i) => Semantics(
              label: 'Demand: ${demands[i].productName}',
              child: DemandCard(
                demand: demands[i],
                currencyFormat: currencyFormat,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DemandDetailsScreen(demand: demands[i]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoDemandsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 38, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No recent buyer demands',
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Shell ───────────────────────────────────────────────────────────────
/// Wraps child screens (Analytics, Profile) so they can open the root drawer.
class _TabShell extends StatelessWidget {
  final VoidCallback onMenuTap;
  final Widget child;

  const _TabShell({required this.onMenuTap, required this.child});

  @override
  Widget build(BuildContext context) {
    // Provide the drawer opener via InheritedWidget-free callback:
    // child screens can call _TabShell.of(context) if needed, but for now
    // we just ensure the hamburger always shows via the root Scaffold.
    return child;
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.count, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconBtn(
      {required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? Colors.grey[300]
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Active',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Chip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
            fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () {},
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _Stat {
  final String title, value, trend;
  final IconData icon;
  final Color color;
  final bool up;

  const _Stat(this.title, this.value, this.icon, this.color, this.trend,
      this.up);
}

class _TradeMeta {
  final String label;
  final Color bg, fg;

  const _TradeMeta(this.label, this.bg, this.fg);
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade200,
              Colors.grey.shade100,
            ],
            stops: [0.0, _anim.value, 1.0],
          ),
        ),
      ),
    );
  }
}
