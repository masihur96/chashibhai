import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedTimeframe = 'This Month';
  int _selectedBarIndex = 4; // Default to May
  bool _showRevenueMode = true; // true = Revenue (৳), false = Volume (KG)

  final List<String> _timeframeOptions = [
    '7 Days',
    '30 Days',
    'This Month',
    'Year 2026',
  ];

  // Monthly data model
  final List<_MonthlyMetric> _monthlyData = const [
    _MonthlyMetric(label: 'Jan', revenue: 14500, volume: 420),
    _MonthlyMetric(label: 'Feb', revenue: 21800, volume: 590),
    _MonthlyMetric(label: 'Mar', revenue: 18200, volume: 480),
    _MonthlyMetric(label: 'Apr', revenue: 31000, volume: 810),
    _MonthlyMetric(label: 'May', revenue: 42500, volume: 1120),
    _MonthlyMetric(label: 'Jun', revenue: 36000, volume: 940),
    _MonthlyMetric(label: 'Jul', revenue: 29500, volume: 780),
  ];

  void _openDrawer() {
    ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold == null || !scaffold.hasDrawer) {
      scaffold = context.findRootAncestorStateOfType<ScaffoldState>();
    }
    scaffold?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currencyFmt = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: RefreshIndicator(
        color: AppColors.primary,
        displacement: 60,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero SliverAppBar (Consistent with FarmerDashboard) ───────
            _buildHeroAppBar(context),

            // ── Main Dashboard Content ─────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 20,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeframe Pill Selector & Refresh Info
                        _buildFilterRow(),
                        const SizedBox(height: 20),

                        // Executive Summary Cards (4 KPIs)
                        _buildKpiMetricsGrid(currencyFmt),
                        const SizedBox(height: 24),

                        // Main Interactive Chart: Revenue & Volume Trends
                        _buildInteractiveChartCard(currencyFmt),
                        const SizedBox(height: 24),

                        // Two column layout on Desktop, stacked on Mobile
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildCategoryBreakdownCard(currencyFmt),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: _buildOrderFulfillmentCard(),
                              ),
                            ],
                          )
                        else ...[
                          _buildCategoryBreakdownCard(currencyFmt),
                          const SizedBox(height: 20),
                          _buildOrderFulfillmentCard(),
                        ],
                        const SizedBox(height: 24),

                        // Top Performing Commodities Table
                        _buildTopCommoditiesCard(currencyFmt),
                        const SizedBox(height: 24),

                        // Market Insights & Pricing Intelligence
                        _buildMarketInsightsCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero SliverAppBar ────────────────────────────────────────────────────────
  // Matches FarmerDashboard hero design with gradient and pinned collapse.

  Widget _buildHeroAppBar(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return SliverAppBar(
      key: const ValueKey('analytics-hero-appbar'),
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: 180,
      collapsedHeight: kToolbarHeight,
      backgroundColor: const Color(0xFF1B5E20),
      surfaceTintColor: Colors.transparent,
      forceElevated: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black38,
      leading: canPop
          ? const BackButton(color: Colors.white)
          : IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Menu',
              onPressed: _openDrawer,
            ),
      title: Text(
        'ChaShiBhai Analytics',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.4,
        ),
      ),
      actions: [
        // Live Indicator Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          tooltip: 'Refresh Analytics',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Analytics refreshed with latest transactions',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _headerBg(),
      ),
    );
  }

  Widget _headerBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Icon Avatar Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Executive Intelligence',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Business Analytics',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Revenue, demand & pricing trends',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Trailing KPI Pill (matching _earningsPill in FarmerDashboard)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Growth Rate',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded, color: Color(0xFF4ADE80), size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '+18.4%',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
    );
  }

  // ─── Filter Row ──────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _timeframeOptions.map((opt) {
          final isSelected = _selectedTimeframe == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeframe = opt),
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
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  // ─── KPI Metrics Grid ────────────────────────────────────────────────────────

  Widget _buildKpiMetricsGrid(NumberFormat currencyFmt) {
    final kpis = [
      _KpiItem(
        title: 'Gross Revenue (GMV)',
        value: currencyFmt.format(184250),
        trend: '+14.2%',
        isPositive: true,
        period: 'vs last period',
        icon: Icons.monetization_on_rounded,
        color: AppColors.primary,
      ),
      _KpiItem(
        title: 'Total Volume Traded',
        value: '4,850 KG',
        trend: '+8.5%',
        isPositive: true,
        period: 'vs last period',
        icon: Icons.scale_rounded,
        color: const Color(0xFFF57C00),
      ),
      _KpiItem(
        title: 'Fulfilled Deals',
        value: '38 Deals',
        trend: '94% rate',
        isPositive: true,
        period: '32 completed',
        icon: Icons.handshake_rounded,
        color: const Color(0xFF1565C0),
      ),
      _KpiItem(
        title: 'Avg. Realized Price',
        value: '৳ 38.00 / KG',
        trend: '+3.1%',
        isPositive: true,
        period: 'optimal margin',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 750 ? 4 : (constraints.maxWidth >= 450 ? 2 : 1);
        final cardAspectRatio = crossAxisCount == 4 ? 1.45 : (crossAxisCount == 2 ? 1.6 : 2.5);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: cardAspectRatio,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) => _buildKpiCard(kpis[index]),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.08),
            blurRadius: 14,
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
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 11,
                      color: item.isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.trend,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.isPositive ? AppColors.success : AppColors.error,
                      ),
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
                item.value,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.period,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Interactive Chart: Revenue & Volume Trends ──────────────────────────────

  Widget _buildInteractiveChartCard(NumberFormat currencyFmt) {
    final maxMetric = _showRevenueMode
        ? _monthlyData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b)
        : _monthlyData.map((e) => e.volume.toDouble()).reduce((a, b) => a > b ? a : b);

    final selectedMetric = _monthlyData[_selectedBarIndex];

    return Container(
      padding: const EdgeInsets.all(20),
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
          // Header with switch toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Trajectory',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap any column to inspect performance details',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              // Segmented Toggle for Revenue vs Volume
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn('Revenue', _showRevenueMode, () {
                      setState(() => _showRevenueMode = true);
                    }),
                    _buildToggleBtn('Volume', !_showRevenueMode, () {
                      setState(() => _showRevenueMode = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Selected Point Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${selectedMetric.label} 2026:',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 8),
                Text(
                  _showRevenueMode
                      ? currencyFmt.format(selectedMetric.revenue)
                      : '${selectedMetric.volume} KG',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Spacer(),
                Text(
                  'Peak performance +22%',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bar Chart Canvas
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_monthlyData.length, (index) {
                final item = _monthlyData[index];
                final value = _showRevenueMode ? item.revenue.toDouble() : item.volume.toDouble();
                final heightFactor = (value / maxMetric).clamp(0.08, 1.0);
                final isSelected = index == _selectedBarIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBarIndex = index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip value over bar
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected ? 1.0 : 0.6,
                          child: Text(
                            _showRevenueMode ? '${(item.revenue / 1000).toStringAsFixed(1)}k' : '${item.volume}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Animated Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          height: 140 * heightFactor,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isSelected
                                  ? [const Color(0xFF1B5E20), AppColors.primary]
                                  : [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                        ),
                        const SizedBox(height: 8),

                        // Month Label
                        Text(
                          item.label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.textPrimary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // Footnote Insights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Peak Month', 'May (৳42.5k)', Colors.green.shade700),
              _buildMiniMetric('Lowest Month', 'Jan (৳14.5k)', Colors.orange.shade800),
              _buildMiniMetric('Monthly Average', '৳27.6k', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ─── Crop Category Breakdown ─────────────────────────────────────────────────

  Widget _buildCategoryBreakdownCard(NumberFormat currencyFmt) {
    final categories = const [
      _CategoryShare(name: 'Rice & Paddy', share: 45, revenue: 82900, color: Color(0xFF2E7D32), icon: Icons.grain),
      _CategoryShare(name: 'Vegetables', share: 28, revenue: 51590, color: Color(0xFFF57C00), icon: Icons.eco),
      _CategoryShare(name: 'Fruits', share: 15, revenue: 27630, color: Color(0xFFD81B60), icon: Icons.apple_rounded),
      _CategoryShare(name: 'Grains & Spices', share: 12, revenue: 22130, color: Color(0xFF1565C0), icon: Icons.spa_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue by Crop Category',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-segment progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: categories.map((c) {
                  return Expanded(
                    flex: c.share,
                    child: Container(color: c.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category Tiles List
          Column(
            children: categories.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(c.icon, color: c.color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${c.share}% of total volume', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      currencyFmt.format(c.revenue),
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

  // ─── Order Pipeline & Fulfillment Funnel ─────────────────────────────────────

  Widget _buildOrderFulfillmentCard() {
    final stages = const [
      _FulfillmentStage(name: 'Completed & Delivered', count: 32, percentage: 84, color: AppColors.success),
      _FulfillmentStage(name: 'Active Negotiation', count: 4, percentage: 11, color: Color(0xFF1565C0)),
      _FulfillmentStage(name: 'In-Bidding Auction', count: 2, percentage: 5, color: Color(0xFFF57C00)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deal Fulfillment Pipeline',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(Icons.inventory_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '38 Total orders tracked across trading channels',
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Column(
            children: stages.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${s.count} orders (${s.percentage}%)',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: s.color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(s.color),
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

  // ─── Top Performing Commodities Table ────────────────────────────────────────

  Widget _buildTopCommoditiesCard(NumberFormat currencyFmt) {
    final commodities = const [
      _TopCommodity(name: 'Boro Rice Premium', category: 'Rice', volume: '2,200 KG', avgPrice: 48, revenue: 105600),
      _TopCommodity(name: 'Miniket Rice Super', category: 'Rice', volume: '1,400 KG', avgPrice: 65, revenue: 91000),
      _TopCommodity(name: 'Red Onion (Deshi)', category: 'Vegetable', volume: '750 KG', avgPrice: 58, revenue: 43500),
      _TopCommodity(name: 'Diamond Potato', category: 'Vegetable', volume: '850 KG', avgPrice: 22, revenue: 18700),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Performing Commodities',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Ranked by Revenue',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 8,
              headingTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12),
              dataTextStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary),
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Volume')),
                DataColumn(label: Text('Avg Price')),
                DataColumn(label: Text('Total Revenue')),
              ],
              rows: commodities.map((c) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(Text(c.category)),
                    DataCell(Text(c.volume)),
                    DataCell(Text(currencyFmt.format(c.avgPrice))),
                    DataCell(Text(currencyFmt.format(c.revenue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Market Insights & Pricing Intelligence ──────────────────────────────────

  Widget _buildMarketInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.lightbulb_outline_rounded, color: const Color(0xFFF57C00), size: 22),
              const SizedBox(width: 8),
              Text(
                'Market Intelligence & Actionable Insights',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInsightItem(
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            title: 'Surging Demand for Boro Rice in Bogura & Rajshahi',
            description:
                'Buyer inquiries have increased by 24% over the past 7 days. Placing new listings this week has a 92% match rate within 48 hours.',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            icon: Icons.access_time_rounded,
            color: const Color(0xFF1565C0),
            title: 'Optimal Auction Closing Window',
            description:
                'Auctions scheduled to close between Wednesday and Friday consistently attract 35% higher bids compared to weekends.',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            icon: Icons.price_check_rounded,
            color: const Color(0xFF6A1B9A),
            title: 'Price Benchmark Recommendation',
            description:
                'Recommended minimum price for Grade-A Paddy is currently ৳48 - ৳52 / KG based on recent accepted transactions.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _KpiItem {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final String period;
  final IconData icon;
  final Color color;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
    required this.period,
    required this.icon,
    required this.color,
  });
}

class _MonthlyMetric {
  final String label;
  final int revenue;
  final int volume;

  const _MonthlyMetric({required this.label, required this.revenue, required this.volume});
}

class _CategoryShare {
  final String name;
  final int share;
  final int revenue;
  final Color color;
  final IconData icon;

  const _CategoryShare({
    required this.name,
    required this.share,
    required this.revenue,
    required this.color,
    required this.icon,
  });
}

class _FulfillmentStage {
  final String name;
  final int count;
  final int percentage;
  final Color color;

  const _FulfillmentStage({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class _TopCommodity {
  final String name;
  final String category;
  final String volume;
  final int avgPrice;
  final int revenue;

  const _TopCommodity({
    required this.name,
    required this.category,
    required this.volume,
    required this.avgPrice,
    required this.revenue,
  });
}
