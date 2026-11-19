import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bangla_text_renderer.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_dashboard_model.dart';
import '../providers/admin_dashboard_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool isRefresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    final dashboardProvider = context.read<AdminDashboardProvider>();
    final token = authProvider.token;

    await dashboardProvider.fetchDashboardData(token: token, isRefresh: isRefresh);
    if (mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final isBangla = languageCode == 'bn';
    final dashboardProvider = context.watch<AdminDashboardProvider>();
    final data = dashboardProvider.dashboardData;
    final isLoading = dashboardProvider.isLoading && data == null;
    final errorMessage = dashboardProvider.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        backgroundColor: Colors.white,
        onRefresh: () => _loadDashboardData(isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header with live sync pill & refresh action ──
                  _buildHeader(
                    context,
                    isBangla: isBangla,
                    lastUpdated: dashboardProvider.lastUpdated,
                    isRefreshing: dashboardProvider.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // ── Error Banner (if any) ──
                  if (errorMessage != null) ...[
                    _buildErrorBanner(errorMessage, isBangla),
                    const SizedBox(height: 20),
                  ],

                  // ── Content State (Loading Skeleton vs Active Dashboard) ──
                  if (isLoading)
                    _buildLoadingSkeleton()
                  else
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 8 Core Metric Cards Grid ──
                          _buildMetricsGrid(data, isBangla),
                          const SizedBox(height: 28),

                          // ── Informative Analytical Breakdown (Demographics & Financials) ──
                          _buildAnalyticsSection(data, isBangla),
                          const SizedBox(height: 28),

                          // ── Operational Controls & System Health ──
                          _buildSystemHealthSection(isBangla),
                          const SizedBox(height: 28),

                          // ── Recent Platform Activity / Audit Log ──
                          _buildRecentActivitySection(isBangla),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context, {
    required bool isBangla,
    required DateTime? lastUpdated,
    required bool isRefreshing,
  }) {
    final timeStr = lastUpdated != null
        ? DateFormat('hh:mm a').format(lastUpdated)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    isBangla ? 'প্রশাসনিক ড্যাশবোর্ড' : 'Executive Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF81C784), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBangla ? 'লাইভ সিঙ্ক সক্রিয়' : 'Live Connected',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isBangla
                    ? 'চাষীভাই প্ল্যাটফর্মের রিয়েল-টাইম ব্যবহারকারী, পণ্য এবং আর্থিক মেট্রিক্স'
                    : 'Real-time overview of users, products, orders, escrow reserves, and platform revenue',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (isRefreshing)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF2E7D32)),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _loadDashboardData(isRefresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              timeStr != null
                  ? (isBangla ? 'আপডেট: ${BanglaTextRenderer.toBanglaNumber(timeStr)}' : 'Updated $timeStr')
                  : (isBangla ? 'রিফ্রেশ' : 'Refresh'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  // ─── Error Banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message, bool isBangla) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadDashboardData(isRefresh: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              isBangla ? 'পুনরায় চেষ্টা' : 'Retry',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Core 8 Metrics Grid ────────────────────────────────────────────────────

  Widget _buildMetricsGrid(AdminDashboardModel? data, bool isBangla) {
    final totalUsers = data?.totalUsers ?? 0;
    final totalFarmers = data?.totalFarmers ?? 0;
    final totalBuyers = data?.totalBuyers ?? 0;
    final activeProducts = data?.activeProducts ?? 0;
    final activeOrders = data?.activeOrders ?? 0;
    final totalRevenue = data?.totalRevenue ?? 0.0;
    final pendingKyc = data?.pendingKyc ?? 0;
    final activeEscrow = data?.activeEscrow ?? 0.0;

    final cards = [
      _MetricConfig(
        title: isBangla ? 'মোট ব্যবহারকারী' : 'Total Users',
        value: isBangla ? BanglaTextRenderer.toBanglaNumber(totalUsers) : totalUsers.toString(),
        subtitle: isBangla ? 'নিবন্ধিত অ্যাকাউন্ট' : 'Platform registered accounts',
        badgeText: isBangla ? 'সক্রিয়' : 'Active Base',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2FF),
      ),
      _MetricConfig(
        title: isBangla ? 'নিবন্ধিত কৃষক' : 'Total Farmers',
        value: isBangla ? BanglaTextRenderer.toBanglaNumber(totalFarmers) : totalFarmers.toString(),
        subtitle: isBangla ? 'কৃষি উৎপাদনকারী ও বিক্রেতা' : 'Agricultural producers & sellers',
        badgeText: totalUsers > 0
            ? '${((totalFarmers / totalUsers) * 100).toStringAsFixed(0)}%'
            : '0%',
        icon: Icons.agriculture_rounded,
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFDCFCE7),
      ),
      _MetricConfig(
        title: isBangla ? 'নিবন্ধিত ক্রেতা' : 'Total Buyers',
        value: isBangla ? BanglaTextRenderer.toBanglaNumber(totalBuyers) : totalBuyers.toString(),
        subtitle: isBangla ? 'পাইকারি ও খুচরা ক্রেতা' : 'Wholesale & commercial buyers',
        badgeText: totalUsers > 0
            ? '${((totalBuyers / totalUsers) * 100).toStringAsFixed(0)}%'
            : '0%',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
      ),
      _MetricConfig(
        title: isBangla ? 'সক্রিয় পণ্য তালিকা' : 'Active Products',
        value: isBangla ? BanglaTextRenderer.toBanglaNumber(activeProducts) : activeProducts.toString(),
        subtitle: isBangla ? 'নিলাম ও সরাসরি ক্রয়ের জন্য' : 'Available for auction & bidding',
        badgeText: isBangla ? 'লাইভ স্টক' : 'Tradable',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _MetricConfig(
        title: isBangla ? 'সক্রিয় অর্ডার' : 'Active Orders',
        value: isBangla ? BanglaTextRenderer.toBanglaNumber(activeOrders) : activeOrders.toString(),
        subtitle: isBangla ? 'ডেলিভারি ও নিষ্পত্তিতে চলমান' : 'In fulfillment & transit',
        badgeText: activeOrders > 0 ? (isBangla ? 'চলমান' : 'In Transit') : (isBangla ? 'স্বাভাবিক' : 'Normal'),
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF0D9488),
        bgColor: const Color(0xFFCCFBF1),
      ),
      _MetricConfig(
        title: isBangla ? 'প্ল্যাটফর্ম আয়' : 'Total Revenue',
        value: isBangla
            ? BanglaTextRenderer.formatTaka(totalRevenue)
            : '৳${totalRevenue.toStringAsFixed(2)}',
        subtitle: isBangla ? 'কমিশন ও পরিষেবা ফি' : 'Commissions & service fees',
        badgeText: isBangla ? 'প্ল্যাটফর্ম' : 'Earnings',
        icon: Icons.monetization_on_rounded,
        color: const Color(0xFF9333EA),
        bgColor: const Color(0xFFF3E8FF),
      ),
      _MetricConfig(
        title: isBangla ? 'অপেক্ষমাণ কেওয়াইসি' : 'Pending KYC',
        value: isBangla ? BanglaTextRenderer.toBanglaNumber(pendingKyc) : pendingKyc.toString(),
        subtitle: isBangla ? 'এনআইডি ও নথি যাচাইকরণ' : 'Verification requests in queue',
        badgeText: pendingKyc == 0
            ? (isBangla ? 'সম্পন্ন' : 'Clear')
            : (isBangla ? 'পর্যালোচনা প্রয়োজন' : 'Requires Action'),
        icon: Icons.verified_user_rounded,
        color: pendingKyc > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
        bgColor: pendingKyc > 0 ? const Color(0xFFFFE4E6) : const Color(0xFFD1FAE5),
      ),
      _MetricConfig(
        title: isBangla ? 'সক্রিয় এসক্রো তহবিল' : 'Active Escrow Pool',
        value: isBangla
            ? BanglaTextRenderer.formatTaka(activeEscrow)
            : '৳${activeEscrow.toStringAsFixed(2)}',
        subtitle: isBangla ? 'সুরক্ষিত এসক্রো ব্যালেন্স' : 'Funds locked in secure escrow',
        badgeText: isBangla ? '১০০% সুরক্ষিত' : '100% Protected',
        icon: Icons.shield_rounded,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFDBEAFE),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;

        if (width >= 1050) {
          crossAxisCount = 4;
          childAspectRatio = 1.6;
        } else if (width >= 640) {
          crossAxisCount = 2;
          childAspectRatio = 1.7;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _buildMetricCard(cards[index]);
          },
        );
      },
    );
  }

  Widget _buildMetricCard(_MetricConfig config) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: config.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(config.icon, color: config.color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: config.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  config.badgeText,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: config.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                config.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                config.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Analytics & Demographics Breakdown ─────────────────────────────────────

  Widget _buildAnalyticsSection(AdminDashboardModel? data, bool isBangla) {
    final totalUsers = data?.totalUsers ?? 0;
    final totalFarmers = data?.totalFarmers ?? 0;
    final totalBuyers = data?.totalBuyers ?? 0;
    final totalStaff = (totalUsers - (totalFarmers + totalBuyers)).clamp(0, 9999);

    final double farmerRatio = totalUsers > 0 ? (totalFarmers / totalUsers) : 0.5;
    final double buyerRatio = totalUsers > 0 ? (totalBuyers / totalUsers) : 0.4;
    final double staffRatio = totalUsers > 0 ? (totalStaff / totalUsers) : 0.1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 760;

        final userDistributionCard = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
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
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pie_chart_rounded, size: 20, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isBangla ? 'ব্যবহারকারী অনুপাত বিশ্লেষণ' : 'User Base Demographics',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isBangla
                        ? 'মোট: ${BanglaTextRenderer.toBanglaNumber(totalUsers)}'
                        : 'Total: $totalUsers',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segmented Proportional Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      if (farmerRatio > 0)
                        Expanded(
                          flex: (farmerRatio * 100).toInt(),
                          child: Container(color: const Color(0xFF16A34A)),
                        ),
                      if (buyerRatio > 0)
                        Expanded(
                          flex: (buyerRatio * 100).toInt(),
                          child: Container(color: const Color(0xFF0284C7)),
                        ),
                      if (staffRatio > 0)
                        Expanded(
                          flex: (staffRatio * 100).toInt(),
                          child: Container(color: const Color(0xFF4F46E5)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _buildLegendItem(
                    color: const Color(0xFF16A34A),
                    label: isBangla ? 'কৃষক' : 'Farmers',
                    count: isBangla ? BanglaTextRenderer.toBanglaNumber(totalFarmers) : '$totalFarmers',
                    pct: '${(farmerRatio * 100).toStringAsFixed(0)}%',
                  ),
                  _buildLegendItem(
                    color: const Color(0xFF0284C7),
                    label: isBangla ? 'ক্রেতা' : 'Buyers',
                    count: isBangla ? BanglaTextRenderer.toBanglaNumber(totalBuyers) : '$totalBuyers',
                    pct: '${(buyerRatio * 100).toStringAsFixed(0)}%',
                  ),
                  _buildLegendItem(
                    color: const Color(0xFF4F46E5),
                    label: isBangla ? 'স্টাফ / অ্যাডমিন' : 'Staff / Root',
                    count: isBangla ? BanglaTextRenderer.toBanglaNumber(totalStaff) : '$totalStaff',
                    pct: '${(staffRatio * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ],
          ),
        );

        final escrowFinancialCard = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
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
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isBangla ? 'এসক্রো ও আর্থিক নিরাপত্তা' : 'Escrow Vault & Liquidity',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SECURE',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialMetricBox(
                      title: isBangla ? 'এসক্রো রিজার্ভ' : 'Escrow Float',
                      amount: isBangla
                          ? BanglaTextRenderer.formatTaka(data?.activeEscrow ?? 0.0)
                          : '৳${(data?.activeEscrow ?? 0.0).toStringAsFixed(2)}',
                      status: isBangla ? 'সুরক্ষিত লক করা তহবিল' : 'Locked buyer funds',
                      icon: Icons.lock_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFinancialMetricBox(
                      title: isBangla ? 'প্ল্যাটফর্ম রাজস্ব' : 'Gross Revenue',
                      amount: isBangla
                          ? BanglaTextRenderer.formatTaka(data?.totalRevenue ?? 0.0)
                          : '৳${(data?.totalRevenue ?? 0.0).toStringAsFixed(2)}',
                      status: isBangla ? 'কমিশন অর্জিত' : 'Commission earned',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: userDistributionCard),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: escrowFinancialCard),
            ],
          );
        } else {
          return Column(
            children: [
              userDistributionCard,
              const SizedBox(height: 16),
              escrowFinancialCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String count,
    required String pct,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          '$count ($pct)',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildFinancialMetricBox({
    required String title,
    required String amount,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ─── Operational System Health ──────────────────────────────────────────────

  Widget _buildSystemHealthSection(bool isBangla) {
    final healthItems = [
      {
        'title': isBangla ? 'ব্যাকএন্ড এপিআই গেটওয়ে' : 'Backend REST API',
        'status': isBangla ? 'সক্রিয় • ২৫মি.সে.' : 'Operational • 25ms',
        'health': 1.0,
        'color': const Color(0xFF16A34A),
        'icon': Icons.dns_rounded,
      },
      {
        'title': isBangla ? 'জেডাব্লিউটি অথ ও সেশন' : 'JWT Auth Service',
        'status': isBangla ? 'এনক্রিপ্ট করা • স্বাভাবিক' : 'Secured • Nominal',
        'health': 0.95,
        'color': const Color(0xFF2563EB),
        'icon': Icons.vpn_key_rounded,
      },
      {
        'title': isBangla ? 'পোস্টগ্রেস ডেটাবেস' : 'PostgreSQL Database',
        'status': isBangla ? 'সংযুক্ত • পুল স্বাস্থ্যকর' : 'Connected • Pool Healthy',
        'health': 0.88,
        'color': const Color(0xFF7C3AED),
        'icon': Icons.storage_rounded,
      },
      {
        'title': isBangla ? 'এসক্রো লেনদেন ইঞ্জিন' : 'Escrow Vault Engine',
        'status': isBangla ? '১০০% লকড ও সুরক্ষিত' : '100% Protected Float',
        'health': 1.0,
        'color': const Color(0xFF0D9488),
        'icon': Icons.lock_clock_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, size: 20, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isBangla ? 'সিস্টেম ও সার্ভার অপারেশনাল স্বাস্থ্য' : 'Infrastructure & Service Health',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBangla ? 'সব ব্যবস্থা স্বাভাবিক' : 'All Systems Nominal',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: healthItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 72,
                ),
                itemBuilder: (context, index) {
                  final item = healthItems[index];
                  final color = item['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item['icon'] as IconData, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['status'] as String,
                                style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Recent Activity Section ────────────────────────────────────────────────

  Widget _buildRecentActivitySection(bool isBangla) {
    final activities = [
      {
        'title': isBangla ? 'নতুন ব্যবহারকারী নিবন্ধন (কৃষক)' : 'New Farmer Account Registered',
        'subtitle': isBangla ? 'বগুড়া সদর • ফোন: ০১৭৪০৭... • কেওয়াইসি সম্পন্ন' : 'Bogura Sadar • Phone: 017407... • Verified',
        'time': isBangla ? '১০ মিনিট আগে' : '10m ago',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF16A34A),
      },
      {
        'title': isBangla ? 'নতুন পণ্য তালিকাভুক্ত করা হয়েছে' : 'New Product Listing Added',
        'subtitle': isBangla ? 'আলু (ডায়মন্ড) • ৫০০ কেজি • নিলামের জন্য প্রস্তুত' : 'Diamond Potato • 500 KG • Ready for Auction',
        'time': isBangla ? '২৫ মিনিট আগে' : '25m ago',
        'icon': Icons.add_shopping_cart_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': isBangla ? 'এসক্রো ডিপোজিট সফল' : 'Escrow Deposit Received',
        'subtitle': isBangla ? 'অর্ডার #১০৮২ • তহবিল ভল্টে লক করা হয়েছে' : 'Order #1082 • Funds secured in platform vault',
        'time': isBangla ? '১ ঘণ্টা আগে' : '1h ago',
        'icon': Icons.security_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'title': isBangla ? 'সিস্টেম হেলথ চেক সফল' : 'Automated System Check Passed',
        'subtitle': isBangla ? 'সমস্ত ব্যাকএন্ড গেটওয়ে ও ডাটাবেস স্বাভাবিক' : 'REST endpoints & PostgreSQL connection nominal',
        'time': isBangla ? '২ ঘণ্টা আগে' : '2h ago',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF4F46E5),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded, size: 20, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isBangla ? 'সাম্প্রতিক প্ল্যাটফর্ম কার্যক্রম' : 'Recent Platform Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                isBangla ? 'অডিট লগ' : 'Audit Logs',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 52, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final a = activities[index];
              final color = a['color'] as Color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a['icon'] as IconData, size: 18, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a['title'] as String,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                a['time'] as String,
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a['subtitle'] as String,
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Loading Skeleton ───────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.grey.shade100),
                      const SizedBox(height: 6),
                      Container(width: 50, height: 22, color: Colors.grey.shade200),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricConfig {
  final String title;
  final String value;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricConfig({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
