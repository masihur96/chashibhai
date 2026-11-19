import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Product? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  Product? _localProduct;

  @override
  void initState() {
    super.initState();
    _localProduct = widget.initialProduct;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductDetails();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    final token = context.read<AuthProvider>().token;
    final product = await context
        .read<ProductProvider>()
        .fetchProductById(id: widget.productId, token: token);
    if (mounted && product != null) {
      setState(() {
        _localProduct = product;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isLoading = productProvider.isProductDetailLoading;
    final errorMessage = productProvider.productDetailError;
    final product = _localProduct ?? productProvider.selectedProduct;
    final currencyFmt = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Builder(
        builder: (context) {
          if (product == null && isLoading) {
            return _buildLoadingScreen();
          }

          if (product == null && errorMessage != null) {
            return _buildErrorScreen(errorMessage);
          }

          if (product == null) {
            return _buildNotFoundScreen();
          }

          return Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(product),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          const LinearProgressIndicator(
                            minHeight: 2.5,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        _buildMainContent(product, currencyFmt),
                        const SizedBox(height: 100), // Spacing for bottom bar
                      ],
                    ),
                  ),
                ],
              ),
              _buildBottomActionBar(product),
            ],
          );
        },
      ),
    );
  }

  // ─── Sliver App Bar with Image Carousel ────────────────────────────────────

  Widget _buildSliverAppBar(Product product) {
    final images = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : (product.imageUrl.isNotEmpty ? [product.imageUrl] : <String>[]);

    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1B5E20),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildCircularButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: _buildCircularButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: _loadProductDetails,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: _buildCircularButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit Listing',
            onTap: () => _navigateToEdit(product),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isNotEmpty)
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (idx) {
                  setState(() => _currentImageIndex = idx);
                },
                itemBuilder: (context, index) {
                  return ProductImageView(
                    imageUrl: images[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              )
            else
              Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

            // Top gradient overlay for action icon contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay for transition into body
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFF4F6F9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Image indicator pill
            if (images.length > 1)
              Positioned(
                bottom: 18,
                right: 18,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Carousel dots
            if (images.length > 1)
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final isSel = i == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSel ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : Colors.white70,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ─── Main Content ────────────────────────────────────────────────────────────

  Widget _buildMainContent(Product product, NumberFormat currencyFmt) {
    final tradeInfo = _getTradeMeta(product.tradeType);
    final daysRemaining = product.endTime.difference(DateTime.now()).inDays;
    final isActive = product.status.toLowerCase() == 'active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top badges row
                Row(
                  children: [
                    _buildStatusPill(
                      label: isActive ? 'Active Listing' : product.status.toUpperCase(),
                      isActive: isActive,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      label: tradeInfo.label,
                      bg: tradeInfo.bg,
                      fg: tradeInfo.fg,
                      icon: tradeInfo.icon,
                    ),
                    const Spacer(),
                    if (product.category.isNotEmpty)
                      _buildCategoryChip(product.category),
                  ],
                ),
                const SizedBox(height: 14),

                // Product Name
                Text(
                  product.productName,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 14),

                // Price Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minimum Starting Price',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currencyFmt.format(product.minimumPrice),
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ ${product.unit}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildTotalValueCard(product, currencyFmt),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 4 Quick Stats Grid ───────────────────────────────────────────
          _buildQuickStats(product),
          const SizedBox(height: 16),

          // ── Timeline & Validity Card ─────────────────────────────────────
          _buildTimelineCard(product, daysRemaining),
          const SizedBox(height: 16),

          // ── Trade Terms & Mode Card ──────────────────────────────────────
          _buildTradeDetailsCard(product, tradeInfo),
          const SizedBox(height: 16),

          // ── Gallery Strip (if multiple photos) ───────────────────────────
          if (product.imageUrls.length > 1) ...[
            _buildGalleryStrip(product.imageUrls),
            const SizedBox(height: 16),
          ],

          // ── Product Meta & ID Card ───────────────────────────────────────
          _buildMetaInfoCard(product),
        ],
      ),
    );
  }

  // ─── Sub-Widgets ─────────────────────────────────────────────────────────────

  Widget _buildTotalValueCard(Product product, NumberFormat currencyFmt) {
    final total = product.minimumPrice * product.quantity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Est. Total Value',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            currencyFmt.format(total),
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Product product) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            icon: Icons.scale_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Total Stock',
            value: '${product.quantity} ${product.unit}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            icon: Icons.category_outlined,
            color: const Color(0xFFF57C00),
            label: 'Category',
            value: product.category.isNotEmpty ? product.category : 'General',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            icon: Icons.gavel_rounded,
            color: const Color(0xFF1565C0),
            label: 'Trade Type',
            value: _getTradeMeta(product.tradeType).label,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Product product, int daysRemaining) {
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final isExpired = daysRemaining < 0;
    final isEndingSoon = daysRemaining >= 0 && daysRemaining <= 2;

    final Color statusColor = isExpired
        ? AppColors.error
        : (isEndingSoon ? const Color(0xFFE65100) : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_rounded, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Listing Timeline',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isExpired
                      ? 'Expired'
                      : (daysRemaining == 0
                          ? 'Ends today'
                          : '$daysRemaining days left'),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTimelineRow(
            label: 'Start Time',
            dateTimeStr: dateFmt.format(product.startTime),
            icon: Icons.play_circle_outline_rounded,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            label: 'End / Expiry Time',
            dateTimeStr: dateFmt.format(product.endTime),
            icon: Icons.stop_circle_outlined,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required String label,
    required String dateTimeStr,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          dateTimeStr,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTradeDetailsCard(Product product, _TradeMeta tradeInfo) {
    String description;
    switch (product.tradeType) {
      case TradeType.auction:
        description =
            'Buyers place competitive bids on your stock. You can monitor bids in real-time and finalize with the highest eligible bidder.';
        break;
      case TradeType.negotiation:
        description =
            'Buyers can submit private price offers. You have full discretion to accept, counter, or decline each offer individually.';
        break;
      case TradeType.both:
        description =
            'Hybrid mode: Open for public competitive bidding and direct private counter-offers simultaneously to maximize deal value.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: tradeInfo.fg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tradeInfo.icon, color: tradeInfo.fg, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Trading Terms & Conditions',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryStrip(List<String> images) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Product Images (${images.length})',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ProductImageView(
                        imageUrl: images[index],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfoCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.tag_rounded, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listing Reference ID',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  product.id,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: AppColors.primary,
            tooltip: 'Copy ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: product.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Bottom Action Bar ───────────────────────────────────────────────────────

  Widget _buildBottomActionBar(Product product) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToEdit(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Edit Listing',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    ).then((result) {
      if (result == 'deleted' && mounted) {
        Navigator.of(context).pop();
      } else {
        _loadProductDetails();
      }
    });
  }

  // ─── Badges & Meta Helpers ───────────────────────────────────────────────────

  Widget _buildStatusPill({required String label, required bool isActive}) {
    final color = isActive ? AppColors.success : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        category.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  _TradeMeta _getTradeMeta(TradeType type) {
    switch (type) {
      case TradeType.auction:
        return const _TradeMeta(
          'AUCTION',
          Color(0xFFFFF3E0),
          Color(0xFFE65100),
          Icons.gavel_rounded,
        );
      case TradeType.negotiation:
        return const _TradeMeta(
          'NEGOTIATE',
          Color(0xFFE3F2FD),
          Color(0xFF0D47A1),
          Icons.handshake_outlined,
        );
      case TradeType.both:
        return const _TradeMeta(
          'HYBRID (BOTH)',
          Color(0xFFE0F2F1),
          Color(0xFF004D40),
          Icons.all_inclusive_rounded,
        );
    }
  }

  // ─── Loading & Error Screens ─────────────────────────────────────────────────

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading product details...',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load product',
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
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProductDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Center(
        child: Text(
          'Product not found',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TradeMeta {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _TradeMeta(this.label, this.bg, this.fg, this.icon);
}
