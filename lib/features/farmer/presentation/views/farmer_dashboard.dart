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

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveListings({String? filter}) async {
    final activeFilter = filter ?? _selectedFilter;
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    String? category;
    String? search;

    if (activeFilter != 'All') {
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
      search: search,
      token: token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context, productProvider, currencyFormat),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _currentIndex == 0
          ? _buildFAB(context)
          : null,
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined, color: Colors.grey[500]),
            selectedIcon: Icon(Icons.space_dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.grey[500]),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.grey[500]),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Semantics(
      label: 'Add New Product',
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) => _fetchActiveListings());
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        label: Text(
          'Add Product',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

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
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildQuickActionsRow(context),
                        const SizedBox(height: 24),
                        _buildStatsGrid(currencyFormat, productProvider.myProducts.length),
                        const SizedBox(height: 28),
                        _buildActiveListingsSection(context, productProvider, currencyFormat),
                        const SizedBox(height: 28),
                        _buildRecentDemandsSection(context, currencyFormat),
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

  // ─── Sliver App Bar / Hero Header ───────────────────────────────────────────

  Widget _buildSliverHeader(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final greeting = _getGreeting();

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _buildHeaderBackground(context, user, greeting),
      ),
      title: Text(
        'ChaShiBhai',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
              tooltip: 'Notifications',
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
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildHeaderBackground(BuildContext context, AppUser? user, String greeting) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
            Color(0xFF43A047),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  _buildAvatarCircle(user),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user?.name ?? 'Farmer',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.district != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                user!.district!,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildEarningsChip(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(AppUser? user) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: user?.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user!.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
            )
          : const Icon(Icons.person_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildEarningsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Total Earnings',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10,
            ),
          ),
          Text(
            '৳84,250',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌱';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  // ─── Quick Actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActionsRow(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.inventory_2_outlined, label: 'My\nListings', color: AppColors.primary),
      _QuickAction(icon: Icons.gavel_rounded, label: 'Active\nBids', color: const Color(0xFFF57C00)),
      _QuickAction(icon: Icons.handshake_outlined, label: 'Deals', color: const Color(0xFF1565C0)),
      _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', color: const Color(0xFF6A1B9A)),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildQuickActionTile(action),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionTile(_QuickAction action) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Grid ──────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(NumberFormat currencyFormat, int activeCount) {
    final stats = [
      _StatItem(
        title: 'Active Listings',
        value: '$activeCount',
        icon: Icons.storefront_outlined,
        color: AppColors.success,
        trend: '+2 this week',
        trendPositive: true,
      ),
      _StatItem(
        title: 'Active Bids',
        value: '12',
        icon: Icons.gavel_rounded,
        color: const Color(0xFFF57C00),
        trend: '3 ending soon',
        trendPositive: false,
      ),
      _StatItem(
        title: 'Pending Deals',
        value: '5',
        icon: Icons.handshake_outlined,
        color: const Color(0xFF1565C0),
        trend: '1 awaiting you',
        trendPositive: false,
      ),
      _StatItem(
        title: 'Wallet Balance',
        value: '৳12,000',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF6A1B9A),
        trend: 'Available',
        trendPositive: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (stat.trendPositive ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stat.trendPositive
                          ? Icons.trending_up_rounded
                          : Icons.info_outline_rounded,
                      size: 10,
                      color: stat.trendPositive ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                stat.title,
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.trend,
                style: GoogleFonts.outfit(
                  color: stat.trendPositive ? AppColors.success : AppColors.warning,
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
    final myProducts = productProvider.myProducts;
    final isLoading = productProvider.isMyProductsLoading;
    final error = productProvider.myProductsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Your Active Listings',
          count: isLoading ? null : myProducts.length,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconBtn(
                icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                tooltip: _isSearching ? 'Close' : 'Search',
                onTap: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _fetchActiveListings();
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              _buildIconBtn(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: isLoading ? null : () => _fetchActiveListings(),
              ),
            ],
          ),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 10),
          _buildSearchField(),
        ],
        const SizedBox(height: 14),
        _buildFilterChips(),
        const SizedBox(height: 16),
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

  Widget _buildSectionHeader({
    required String title,
    int? count,
    Widget? trailing,
  }) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
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
            color: onTap == null ? Colors.grey[300] : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search listings (e.g. Rice, Wheat…)',
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _fetchActiveListings();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _fetchActiveListings(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
                _fetchActiveListings(filter: filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const _ShimmerBox(),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded, color: Colors.red.shade600, size: 22),
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  error,
                  style: GoogleFonts.outfit(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _fetchActiveListings(),
            child: Text(
              'Retry',
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
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
      title: 'No Active Listings',
      subtitle: _selectedFilter == 'All'
          ? 'Start by adding your first product to reach buyers.'
          : 'No listings found in "$_selectedFilter". Try a different category.',
      action: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((_) => _fetchActiveListings());
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Add First Product', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─── Listing Cards ───────────────────────────────────────────────────────────

  Widget _buildListingList(List<Product> products, NumberFormat currencyFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildListingCard(context, products[index], currencyFormat);
      },
    );
  }

  Widget _buildListingCard(
    BuildContext context,
    Product product,
    NumberFormat currencyFormat,
  ) {
    final tradeInfo = _getTradeInfo(product.tradeType);

    return Semantics(
      label: 'Listing: ${product.productName}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: product),
                ),
              ).then((_) => _fetchActiveListings());
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Semantics(
                      image: true,
                      label: '${product.productName} image',
                      child: ProductImageView(
                        imageUrl: product.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Product Details
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
                            _buildActiveBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.quantity} ${product.unit} available',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (product.category.isNotEmpty)
                              _buildBadge(
                                product.category.toUpperCase(),
                                Colors.grey.shade100,
                                Colors.grey.shade700,
                              ),
                            const SizedBox(width: 6),
                            _buildBadge(
                              tradeInfo.label,
                              tradeInfo.bgColor,
                              tradeInfo.textColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Price + Arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currencyFormat.format(product.minimumPrice),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'min price',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
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

  Widget _buildActiveBadge() {
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

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  _TradeInfo _getTradeInfo(TradeType type) {
    switch (type) {
      case TradeType.auction:
        return _TradeInfo(
          label: 'AUCTION',
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
        );
      case TradeType.negotiation:
        return _TradeInfo(
          label: 'NEGOTIATE',
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF0D47A1),
        );
      case TradeType.both:
        return _TradeInfo(
          label: 'BOTH',
          bgColor: const Color(0xFFE0F2F1),
          textColor: const Color(0xFF004D40),
        );
    }
  }

  // ─── Recent Demands Section ──────────────────────────────────────────────────

  Widget _buildRecentDemandsSection(BuildContext context, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Recent Buyer Demands',
          trailing: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'View All',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildRecentDemandsList(context, currencyFormat),
      ],
    );
  }

  Widget _buildRecentDemandsList(BuildContext context, NumberFormat currencyFormat) {
    final demands = context.watch<DemandProvider>().demands;

    if (demands.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No recent buyer demands',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: demands.length > 3 ? 3 : demands.length,
      itemBuilder: (context, index) {
        final demand = demands[index];
        return Semantics(
          label: 'Demand: ${demand.productName}',
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

// ─── Helper Models ───────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendPositive;
  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendPositive,
  });
}

class _TradeInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _TradeInfo({required this.label, required this.bgColor, required this.textColor});
}

// ─── Shimmer Placeholder ─────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
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
      builder: (_, __) {
        return Container(
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
        );
      },
    );
  }
}
