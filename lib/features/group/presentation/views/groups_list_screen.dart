import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../data/models/create_group_request_model.dart';
import '../state/group_provider.dart';
import './group_detail_screen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime? _lastSyncedTime;

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Spices',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final groupProvider = context.read<GroupProvider>();
    final authProvider = context.read<AuthProvider>();

    String? token = authProvider.token;
    if (token == null || token.isEmpty) {
      try {
        token = await StorageService().getAccessToken();
      } catch (_) {}
    }
    token ??= GroupProvider.defaultGroupCurlToken;

    await Future.wait([
      groupProvider.fetchMyGroups(token: token),
      groupProvider.fetchGroups(token: token),
    ]);

    if (mounted) {
      setState(() {
        _lastSyncedTime = DateTime.now();
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadInitialData();
  }

  List<BuyingGroup> _filterGroups(List<BuyingGroup> sourceList) {
    return sourceList.where((g) {
      // Category filter
      if (_selectedCategory != 'All' &&
          g.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = g.name.toLowerCase().contains(query);
        final productMatch = g.productName.toLowerCase().contains(query);
        final locMatch = g.deliveryLocation.toLowerCase().contains(query);
        if (!nameMatch && !productMatch && !locMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = context.watch<AppStateProvider>().isBangla;
    final user = context.watch<AuthProvider>().currentUser;
    final groupProvider = context.watch<GroupProvider>();

    final myGroupsRaw = groupProvider.myGroups.isNotEmpty
        ? groupProvider.myGroups
        : groupProvider.getMyGroups(user?.id);

    final openGroupsRaw = groupProvider.groups.where((g) {
      return g.status == GroupBuyStatus.open;
    }).toList();

    final filteredOpenGroups = _filterGroups(openGroupsRaw);
    final filteredMyGroups = _filterGroups(myGroupsRaw);

    final isLoading = groupProvider.isLoadingMyGroups || groupProvider.isLoadingGroups;

    // KPI Metrics calculation
    final totalPoolQty = myGroupsRaw.fold<double>(
      0,
      (sum, g) => sum + g.targetQuantity,
    );
    final totalJoinedCount = myGroupsRaw.length;
    final totalOpenCount = openGroupsRaw.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla ? 'দলগত ক্রয় (Buying Groups)' : 'Buying Groups',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isBangla
                  ? '${filteredOpenGroups.length} টি উন্মুক্ত গ্রুপ পাওয়া গেছে'
                  : '${filteredOpenGroups.length} open groups available',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // Live API Status Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              ),
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
                const SizedBox(width: 5),
                Text(
                  'cURL v1 API',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isBangla ? 'রিফ্রেশ' : 'Refresh',
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: isLoading ? null : _handleRefresh,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2E7D32),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(isBangla ? 'উন্মুক্ত গ্রুপ' : 'Open Groups'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${openGroupsRaw.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_work_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(isBangla ? 'আমার গ্রুপসমূহ' : 'My Groups'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${myGroupsRaw.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupSheet(context),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 3,
        icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
        label: Text(
          isBangla ? 'নতুন গ্রুপ তৈরি' : 'Create Group',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Live Endpoint & Sync Info Banner ───
            SliverToBoxAdapter(
              child: _buildCurlStatusBanner(isBangla),
            ),

            // ─── KPI Stats Overview ───
            SliverToBoxAdapter(
              child: _buildKpiStatsBar(
                openCount: totalOpenCount,
                joinedCount: totalJoinedCount,
                totalPoolQty: totalPoolQty,
                isBangla: isBangla,
              ),
            ),

            // ─── Search & Category Filters ───
            SliverToBoxAdapter(
              child: _buildSearchAndCategoryFilters(isBangla),
            ),

            // ─── Content List ───
            _tabController.index == 0
                ? _buildGroupSliverList(
                    filteredOpenGroups,
                    user,
                    isMyGroups: false,
                    isBangla: isBangla,
                    isLoading: groupProvider.isLoadingGroups && openGroupsRaw.isEmpty,
                  )
                : _buildGroupSliverList(
                    filteredMyGroups,
                    user,
                    isMyGroups: true,
                    isBangla: isBangla,
                    isLoading: groupProvider.isLoadingMyGroups && myGroupsRaw.isEmpty,
                  ),
          ],
        ),
      ),
    );
  }

  // ─── Live Endpoint Status Banner ──────────────────────────────────────────

  Widget _buildCurlStatusBanner(bool isBangla) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.api_rounded, color: Color(0xFF2E7D32), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'POST /groups  •  GET /groups/my',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _lastSyncedTime != null
                      ? '${isBangla ? "সর্বশেষ সিঙ্ক" : "Last synced"}: ${DateFormat("hh:mm:ss a").format(_lastSyncedTime!)}'
                      : (isBangla ? 'সার্ভারের সাথে সংযুক্ত' : 'Connected to localhost:3000'),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _handleRefresh,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Text(
                    isBangla ? 'সিঙ্ক' : 'Sync',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Stats Bar ────────────────────────────────────────────────────────

  Widget _buildKpiStatsBar({
    required int openCount,
    required int joinedCount,
    required double totalPoolQty,
    required bool isBangla,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'উন্মুক্ত পুল' : 'Open Pools',
              count: '$openCount',
              icon: Icons.public_rounded,
              color: const Color(0xFF2E7D32),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'আমার যুক্ত গ্রুপ' : 'My Groups',
              count: '$joinedCount',
              icon: Icons.group_work_rounded,
              color: const Color(0xFF1565C0),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          Expanded(
            child: _buildKpiItem(
              title: isBangla ? 'মোট লক্ষ্য' : 'Target Volume',
              count: '${totalPoolQty.toInt()} KG',
              icon: Icons.scale_rounded,
              color: const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── Search & Category Filters ────────────────────────────────────────────

  Widget _buildSearchAndCategoryFilters(bool isBangla) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search TextField
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                hintText: isBangla
                    ? 'গ্রুপের নাম, পণ্য বা ডেলিভারি এলাকা দিয়ে খুঁজুন...'
                    : 'Search by group name, product, or location...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Category Chips
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF2E7D32),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─── Group Sliver List ────────────────────────────────────────────────────

  Widget _buildGroupSliverList(
    List<BuyingGroup> groups,
    AppUser? user, {
    required bool isMyGroups,
    required bool isBangla,
    required bool isLoading,
  }) {
    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonCard(),
            childCount: 3,
          ),
        ),
      );
    }

    if (groups.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(isMyGroups, isBangla),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = groups[index];
            return _GroupCard(
              group: group,
              currentUserId: user?.id ?? '',
              isBangla: isBangla,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(groupId: group.id),
                  ),
                ).then((_) {
                  if (mounted) _handleRefresh();
                });
              },
            );
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  // ─── Informative Empty State ──────────────────────────────────────────────

  Widget _buildEmptyState(bool isMyGroups, bool isBangla) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyGroups ? Icons.group_work_outlined : Icons.inventory_2_outlined,
                size: 54,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isMyGroups
                  ? (isBangla ? 'কোনো গ্রুপে যুক্ত হননি' : 'No Groups Joined Yet')
                  : (_selectedCategory == 'All' && _searchQuery.isEmpty
                      ? (isBangla ? 'কোনো উন্মুক্ত গ্রুপ নেই' : 'No Open Groups Available')
                      : (isBangla ? 'কোনো গ্রুপ খুঁজে পাওয়া যায়নি' : 'No Matching Groups Found')),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isMyGroups
                  ? (isBangla
                      ? 'অন্য ক্রেতাদের সাথে দলগতভাবে বড় পরিমাণে পণ্য কিনে পাইকারি দামের সুবিধা পান।'
                      : 'Pool demand with other buyers to unlock wholesale farm prices and bulk savings.')
                  : (_searchQuery.isNotEmpty
                      ? (isBangla ? 'অনুসন্ধান বা ফিল্টার পরিবর্তন করে দেখুন।' : 'Try adjusting your search query or category filter.')
                      : (isBangla ? 'নতুন একটি বাইয়িং গ্রুপ তৈরি করে অন্য ক্রেতাদের আমন্ত্রণ জানান!' : 'Create the first buying group and invite others to join your pool!')),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                isBangla ? 'নতুন গ্রুপ তৈরি করুন' : 'Create Buying Group',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton Loading Card ────────────────────────────────────────────────

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 120, height: 16, color: Colors.grey.shade200),
              Container(width: 60, height: 16, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 8, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 80, height: 22, color: Colors.grey.shade200),
              const SizedBox(width: 8),
              Container(width: 80, height: 22, color: Colors.grey.shade200),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Create Group Bottom Sheet ────────────────────────────────────────────

  void _showCreateGroupSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    // Initial controllers prefilled or blank
    final nameController = TextEditingController(text: '');
    final productController = TextEditingController(text: '');
    final targetQtyController = TextEditingController(text: '');
    final priceController = TextEditingController(text: '');
    final locationController = TextEditingController(text: '');
    final initialContribController = TextEditingController(text: '');

    String selectedCategory = 'Vegetables';
    DateTime selectedExpiry = DateTime.now().add(const Duration(days: 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final groupProvider = context.watch<GroupProvider>();
          final isCreating = groupProvider.isCreatingGroup;

          void populateCurlPreset() {
            setSheetState(() {
              nameController.text = 'Dhaka Potato Bulk Buy';
              productController.text = 'Potatoes (Diamant)';
              selectedCategory = 'Vegetables';
              targetQtyController.text = '1000';
              priceController.text = '25';
              locationController.text = 'Mirpur-10, Dhaka';
              initialContribController.text = '100';
              selectedExpiry = DateTime.utc(2026, 12, 1, 18, 0, 0);
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Quick Preset Chip Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Buying Group',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pool demand with other buyers for wholesale rates',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Preset Banner for cURL Specification
                    InkWell(
                      onTap: populateCurlPreset,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Color(0xFF2E7D32), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚡ Fill Dhaka Potato Bulk Buy (cURL Sample)',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2E7D32)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Group Name
                    _buildTextField(
                      controller: nameController,
                      label: 'Group Name',
                      hint: 'e.g. Dhaka Potato Bulk Buy',
                      icon: Icons.groups_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a group name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Product Name
                    _buildTextField(
                      controller: productController,
                      label: 'Product Name',
                      hint: 'e.g. Potatoes (Diamant)',
                      icon: Icons.eco_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter product name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: _inputDecoration('Category', Icons.category_outlined),
                      items: ['Vegetables', 'Fruits', 'Grains', 'Spices']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => selectedCategory = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Target Quantity & Price/KG Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: targetQtyController,
                            label: 'Target Qty (KG)',
                            hint: '1000',
                            icon: Icons.scale_rounded,
                            keyboard: TextInputType.number,
                            validator: (v) {
                              final num = double.tryParse(v ?? '');
                              if (num == null || num <= 0) return 'Enter target KG';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: priceController,
                            label: 'Price / KG (৳)',
                            hint: '25',
                            icon: Icons.monetization_on_outlined,
                            keyboard: TextInputType.number,
                            validator: (v) {
                              final num = double.tryParse(v ?? '');
                              if (num == null || num <= 0) return 'Enter price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Initial Contribution (KG)
                    _buildTextField(
                      controller: initialContribController,
                      label: 'Initial Contribution (KG)',
                      hint: 'e.g. 100',
                      icon: Icons.volunteer_activism_outlined,
                      keyboard: TextInputType.number,
                      helperText: 'Your initial contribution to kickstart this pool',
                      validator: (v) {
                        final num = double.tryParse(v ?? '');
                        if (num == null || num < 0) return 'Enter valid contribution';
                        final target = double.tryParse(targetQtyController.text) ?? 0;
                        if (target > 0 && num > target) return 'Cannot exceed target';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Delivery Location
                    _buildTextField(
                      controller: locationController,
                      label: 'Delivery Location',
                      hint: 'e.g. Mirpur-10, Dhaka',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter delivery location' : null,
                    ),
                    const SizedBox(height: 12),

                    // Expiry Date Selection
                    Text(
                      'Group Expiry Date',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiry,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedExpiry = DateTime.utc(
                              picked.year,
                              picked.month,
                              picked.day,
                              18,
                              0,
                              0,
                            );
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy, hh:mm a (UTC)').format(selectedExpiry.toUtc()),
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isCreating
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  final request = CreateGroupRequestModel(
                                    name: nameController.text.trim(),
                                    productName: productController.text.trim(),
                                    category: selectedCategory.toLowerCase(),
                                    targetQuantity: double.parse(targetQtyController.text.trim()),
                                    pricePerKg: double.parse(priceController.text.trim()),
                                    deliveryLocation: locationController.text.trim(),
                                    expiryDate: selectedExpiry,
                                    initialContribution: double.tryParse(initialContribController.text.trim()) ?? 0,
                                  );

                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    await context.read<GroupProvider>().createGroup(request);
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    if (!mounted) return;
                                    _tabController.animateTo(1); // Switch to My Groups tab
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Group "${request.name}" created & synced via cURL API!',
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF2E7D32),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error creating group: $e'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isCreating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Creating Group & Fetching /my...'),
                                ],
                              )
                            : Text(
                                'Create Buying Group',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
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
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: _inputDecoration(label, icon, helperText: helperText).copyWith(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
      validator: validator,
    );
  }
}

// ─── Group Card Widget ────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final BuyingGroup group;
  final String currentUserId;
  final bool isBangla;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.currentUserId,
    required this.isBangla,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = group.targetQuantity > 0
        ? (group.filledQuantity / group.targetQuantity).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progress * 100).toInt();

    final now = DateTime.now();
    final difference = group.expiryDate.difference(now);
    final daysLeft = difference.inDays;

    final isCreator = group.createdBy == currentUserId && currentUserId.isNotEmpty;
    final isMember = group.members.any((m) => m.userId == currentUserId && currentUserId.isNotEmpty);

    Color statusColor;
    String statusText;
    switch (group.status) {
      case GroupBuyStatus.open:
        statusColor = const Color(0xFF2E7D32);
        statusText = 'OPEN';
        break;
      case GroupBuyStatus.active:
        statusColor = const Color(0xFF1565C0);
        statusText = 'ACTIVE';
        break;
      case GroupBuyStatus.fulfilled:
        statusColor = const Color(0xFF6A1B9A);
        statusText = 'FULFILLED';
        break;
      case GroupBuyStatus.cancelled:
        statusColor = Colors.grey.shade600;
        statusText = 'CANCELLED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Icon / Initial
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Product Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                group.productName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  group.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Badge & Member Pill
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '👑 Creator',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ] else if (isMember) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '✓ Joined',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar & Quantity commitment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${group.filledQuantity.toInt()} / ${group.targetQuantity.toInt()} KG filled',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 12),

                // Meta Information Row
                Row(
                  children: [
                    // Price/KG
                    _buildMetaChip(
                      icon: Icons.monetization_on_outlined,
                      label: '৳${group.pricePerKg.toInt()}/KG',
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),

                    // Members count
                    _buildMetaChip(
                      icon: Icons.people_outline_rounded,
                      label: '${group.members.length} members',
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),

                    // Expiry Days
                    _buildMetaChip(
                      icon: Icons.timer_outlined,
                      label: daysLeft > 0 ? '$daysLeft days left' : 'Ends soon',
                      color: daysLeft <= 2 ? AppColors.error : Colors.grey.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location Row
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        group.deliveryLocation,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
