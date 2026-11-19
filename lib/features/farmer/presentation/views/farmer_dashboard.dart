import '../../../../core/models/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import './add_product_screen.dart';
import './product_detail_screen.dart';
import '../../../admin/presentation/views/analytics_screen.dart';
import '../../../account/presentation/views/profile_screen.dart';
import './demand_details_screen.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FARMER DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _filters = [
    'All',
    'Rice (Curl Filter)',
    'Rice',
    'Vegetables',
    'Fruits',
    'Grains'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchListings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _fetchListings({String? filter}) async {
    final f = filter ?? _selectedFilter;
    final token = context.read<AuthProvider>().token;
    String? category;
    String? tradeType;
    double? minPrice;
    double? maxPrice;
    String? search;

    if (f == 'Rice (Curl Filter)') {
      category = 'rice';
      tradeType = 'both';
      minPrice = 30.0;
      maxPrice = 100.0;
      search = 'Rice';
    } else if (f != 'All') {
      category = f.toLowerCase();
    }

    if (_searchController.text.trim().isNotEmpty) {
      search = _searchController.text.trim();
    }

    await context.read<ProductProvider>().fetchMyProducts(
          page: 1,
          limit: 20,
          status: 'active',
          category: category,
          tradeType: tradeType,
          minPrice: minPrice,
          maxPrice: maxPrice,
          search: search,
          token: token,
        );
  }

  // ─── Scaffold ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final fmt = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F7),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _homeTab(context, pp, fmt),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
      floatingActionButton: _currentIndex == 0 ? _fab(context) : null,
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────────────────

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4))
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

  Widget _fab(BuildContext context) => FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()))
            .then((_) => _fetchListings()),
        backgroundColor: AppColors.primary,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Product',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
      );

  // ─── Home Tab ────────────────────────────────────────────────────────────────

  Widget _homeTab(
      BuildContext context, ProductProvider pp, NumberFormat fmt) {
    return RefreshIndicator(
      color: AppColors.primary,
      displacement: 60,
      onRefresh: _fetchListings,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────────────
          _heroAppBar(context),

          // ── Page content ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    _statsRow(pp.myProducts.length),
                    const SizedBox(height: 28),
                    // Active Listings Grid
                    _listingsSection(context, pp, fmt),
                    const SizedBox(height: 28),
                    // Buyer Demands Grid
                    _demandsSection(context, fmt),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero SliverAppBar ────────────────────────────────────────────────────────
  // expandedHeight is tightly sized; no extra transparent whitespace.

  Widget _heroAppBar(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning 🌱' : hour < 17 ? 'Good Afternoon ☀️' : 'Good Evening 🌙';

    return SliverAppBar(
      key: const ValueKey('hero-appbar'),
      pinned: true,
      snap: false,
      floating: false,
      // ⬇ Tight expanded height — no extra gap
      expandedHeight: 180,
      collapsedHeight: kToolbarHeight,
      backgroundColor: const Color(0xFF1B5E20),
      surfaceTintColor: Colors.transparent,
      forceElevated: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black38,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
        tooltip: 'Menu',
        onPressed: _openDrawer,
      ),
      title: Text(
        'ChaShiBhai',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.4,
        ),
      ),
      actions: [
        _NotifBell(),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // collapseMode: pin keeps the gradient covering the bar area
        collapseMode: CollapseMode.pin,
        background: _headerBg(user, greeting),
      ),
    );
  }

  Widget _headerBg(AppUser? user, String greeting) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      // align content at bottom so it shows just above the fold
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            _avatar(user),
            const SizedBox(width: 14),
            // Name + district
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(user?.name ?? 'Farmer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  if (user?.district != null)
                    Row(children: [
                      Icon(Icons.location_on_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 3),
                      Text(user!.district!,
                          style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11)),
                    ]),
                ],
              ),
            ),
            // Earnings pill
            _earningsPill(),
          ],
        ),
      ),
    );
  }

  Widget _avatar(AppUser? user) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.4), width: 2),
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: ClipOval(
          child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
              ? Image.network(user.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26))
              : const Icon(Icons.person_rounded,
                  color: Colors.white, size: 26),
        ),
      );

  Widget _earningsPill() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Total Earnings',
                style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 9,
                    fontWeight: FontWeight.w500)),
            Text('৳ 84,250',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_up_rounded,
                  size: 10,
                  color: Colors.greenAccent.shade100),
              const SizedBox(width: 2),
              Text('+8.2% month',
                  style: GoogleFonts.outfit(
                      color: Colors.greenAccent.shade100,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      );

  // ─── Stats Row ────────────────────────────────────────────────────────────────

  Widget _statsRow(int activeCount) {
    final stats = [
      _Stat('Listings', '$activeCount', Icons.storefront_outlined,
          AppColors.success, '+2 this week', true),
      _Stat('Active Bids', '12', Icons.gavel_rounded,
          const Color(0xFFF57C00), '3 ending soon', false),
      _Stat('Deals', '5', Icons.handshake_outlined,
          const Color(0xFF1565C0), '1 awaiting you', false),
      _Stat('Wallet', '৳12k', Icons.account_balance_wallet_outlined,
          const Color(0xFF6A1B9A), 'Available', true),
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: stats.indexOf(s) == 0 ? 0 : 6,
                      right: stats.indexOf(s) == stats.length - 1 ? 0 : 6),
                  child: _statCard(s),
                ),
              ))
          .toList(),
    );
  }

  Widget _statCard(_Stat s) {
    final tc = s.up ? AppColors.success : const Color(0xFFF57C00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: s.color.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(s.icon, color: s.color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(s.value,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          Text(s.title,
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Row(children: [
            Icon(
                s.up
                    ? Icons.trending_up_rounded
                    : Icons.access_time_rounded,
                size: 9,
                color: tc),
            const SizedBox(width: 2),
            Flexible(
              child: Text(s.trend,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      color: tc, fontSize: 9, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Active Listings Section ──────────────────────────────────────────────────

  Widget _listingsSection(
      BuildContext context, ProductProvider pp, NumberFormat fmt) {
    final products = pp.myProducts;
    final loading = pp.isMyProductsLoading;
    final error = pp.myProductsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _SectionHeader(
          title: 'Your Active Listings',
          count: loading ? null : products.length,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _IconBtn(
              icon: _isSearching
                  ? Icons.close_rounded
                  : Icons.search_rounded,
              tooltip: _isSearching ? 'Close' : 'Search',
              onTap: () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _fetchListings();
                }
              }),
            ),
            const SizedBox(width: 6),
            _IconBtn(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh',
              onTap: loading ? null : _fetchListings,
            ),
          ]),
        ),

        // Animated search bar
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _isSearching
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _searchField())
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 14),

        // Filter chips
        _filterChips(),

        const SizedBox(height: 16),

        // Grid content
        if (loading && products.isEmpty)
          _shimmerGrid()
        else if (error != null && products.isEmpty)
          _errorCard(error)
        else if (products.isEmpty)
          _emptyState(context)
        else
          _listingGrid(context, products, fmt),
      ],
    );
  }

  Widget _searchField() => TextField(
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
                    _fetchListings();
                    setState(() {});
                  })
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _fetchListings(),
        onChanged: (_) => setState(() {}),
      );

  Widget _filterChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final sel = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = f);
                  _fetchListings(filter: f);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : Colors.grey.shade200),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Text(f,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: sel
                              ? Colors.white
                              : AppColors.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  // ── Shimmer grid ─────────────────────────────────────────────────────────────

  Widget _shimmerGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
          child: const _ShimmerBox(),
        ),
      );

  Widget _errorCard(String error) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  color: Colors.red.shade600, size: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Failed to load listings',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                        fontSize: 14)),
                Text(error,
                    style: GoogleFonts.outfit(
                        color: Colors.red.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ])),
          TextButton(
              onPressed: _fetchListings,
              child: Text('Retry',
                  style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _emptyState(BuildContext context) => EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'No Active Listings',
        subtitle: _selectedFilter == 'All'
            ? 'Start by adding your first product to reach buyers.'
            : 'No listings in "$_selectedFilter". Try another category.',
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()))
              .then((_) => _fetchListings()),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add First Product',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ),
      );

  // ── Listing Grid ─────────────────────────────────────────────────────────────

  Widget _listingGrid(
      BuildContext context, List<Product> products, NumberFormat fmt) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.76),
      itemCount: products.length,
      itemBuilder: (_, i) => _listingCard(context, products[i], fmt),
    );
  }

  Widget _listingCard(
      BuildContext context, Product p, NumberFormat fmt) {
    final trade = _tradeMeta(p.tradeType);

    return Semantics(
      label: 'Listing: ${p.productName}',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: p.id,
              initialProduct: p,
            ),
          ),
        ).then((_) => _fetchListings()),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product image (top, full-width) ──────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                    child: ProductImageView(
                      imageUrl: p.imageUrl,
                      width: double.infinity,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Active badge overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4)
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Active',
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ]),
                    ),
                  ),
                  // Trade type badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: trade.bg,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4)
                        ],
                      ),
                      child: Text(trade.label,
                          style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: trade.fg)),
                    ),
                  ),
                ],
              ),

              // ── Info ───────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Text(p.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.3)),

                      // Category chip
                      if (p.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(p.category.toUpperCase(),
                              style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                        ),

                      // Quantity + price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.scale_outlined,
                                size: 11, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text('${p.quantity} ${p.unit} listed',
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(fmt.format(p.minimumPrice),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primary)),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TradeMeta _tradeMeta(TradeType t) {
    switch (t) {
      case TradeType.auction:
        return const _TradeMeta(
            'AUCTION', Color(0xFFFFF3E0), Color(0xFFE65100));
      case TradeType.negotiation:
        return const _TradeMeta(
            'NEGOTIATE', Color(0xFFE3F2FD), Color(0xFF0D47A1));
      case TradeType.both:
        return const _TradeMeta(
            'BOTH', Color(0xFFE0F2F1), Color(0xFF004D40));
    }
  }

  // ─── Demands Section ──────────────────────────────────────────────────────────

  Widget _demandsSection(BuildContext context, NumberFormat fmt) {
    final demands = context.watch<DemandProvider>().demands;
    final shown = demands.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Buyer Demands',
          count: demands.isNotEmpty ? demands.length : null,
          trailing: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero),
            child: Text('View All',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 14),
        if (demands.isEmpty)
          _noDemandsCard()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.84,
            ),
            itemCount: shown.length,
            itemBuilder: (_, i) => _demandCard(context, shown[i], fmt),
          ),
      ],
    );
  }

  Widget _demandCard(
      BuildContext context, DemandPost d, NumberFormat fmt) {
    final isAuction = d.tradeType == TradeType.auction;
    final tradeColor =
        isAuction ? const Color(0xFFF57C00) : const Color(0xFF1565C0);
    final tradeBg = isAuction
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE3F2FD);
    final tradeFg = tradeColor;

    final daysLeft = d.expiryTime.difference(DateTime.now()).inDays;
    final urgentColor =
        daysLeft <= 2 ? AppColors.error : AppColors.textSecondary;

    return Semantics(
      label: 'Demand: ${d.productName}',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DemandDetailsScreen(demand: d)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image with overlays ───────────────────────────────────────
              Stack(children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: ProductImageView(
                    imageUrl: d.imageUrl,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: d.status == DemandStatus.active
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: d.status == DemandStatus.active
                                      ? AppColors.success
                                      : Colors.grey,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                              d.status.toString().split('.').last
                                  .toUpperCase(),
                              style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: d.status == DemandStatus.active
                                      ? AppColors.success
                                      : Colors.grey.shade700)),
                        ]),
                  ),
                ),
                // Trade type badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: tradeBg,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                        d.tradeType.toString().split('.').last.toUpperCase(),
                        style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: tradeFg)),
                  ),
                ),
              ]),

              // ── Info ───────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.3)),

                      // Quantity
                      Row(children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text('${d.quantity.toStringAsFixed(0)} KG',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),

                      // Price row + expiry
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(fmt.format(d.callingPrice),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primary)),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.schedule_rounded,
                                size: 10, color: urgentColor),
                            const SizedBox(width: 3),
                            Text(
                                daysLeft <= 0
                                    ? 'Expired'
                                    : daysLeft == 1
                                        ? 'Expires tomorrow'
                                        : 'Expires in $daysLeft days',
                                style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: urgentColor,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noDemandsCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(children: [
            Icon(Icons.inbox_outlined, size: 38, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('No recent buyer demands',
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.count, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Row(children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$count',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
          ],
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconBtn({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
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
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(icon,
                size: 18,
                color: onTap == null
                    ? Colors.grey[300]
                    : AppColors.textSecondary),
          ),
        ),
      );
}

class _NotifBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
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
                  color: Color(0xFFFF6B35), shape: BoxShape.circle),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _Stat {
  final String title, value, trend;
  final IconData icon;
  final Color color;
  final bool up;

  const _Stat(
      this.title, this.value, this.icon, this.color, this.trend, this.up);
}

class _TradeMeta {
  final String label;
  final Color bg, fg;

  const _TradeMeta(this.label, this.bg, this.fg);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => AnimatedBuilder(
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
              stops: [0.0, _anim.value.clamp(0.01, 0.99), 1.0],
            ),
          ),
        ),
      );
}
