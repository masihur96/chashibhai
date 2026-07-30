import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../auth/presentation/state/auth_provider.dart';
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
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Vegetables',
    'Grains',
    'Fruits',
    'Spices',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupProvider>().groups;
    final myGroups = context.watch<GroupProvider>().getMyGroups(
      context.watch<AuthProvider>().currentUser?.id,
    );
    final user = context.watch<AuthProvider>().currentUser;

    final openGroups = groups.where((g) {
      final matchesCat =
          _selectedCategory == 'All' || g.category == _selectedCategory;
      return g.status == GroupBuyStatus.open && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buying Groups',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Open Groups (${openGroups.length})'),
            Tab(text: 'My Groups (${myGroups.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupList(openGroups, user),
          _buildGroupList(myGroups, user, isMyGroups: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupSheet(context),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: Text(
          'Create Group',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList(
    List<BuyingGroup> groups,
    AppUser? user, {
    bool isMyGroups = false,
  }) {
    return Column(
      children: [
        if (!isMyGroups) _buildCategoryFilter(),
        Expanded(
          child: groups.isEmpty
              ? _buildEmptyState(isMyGroups)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return _GroupCard(
                      group: groups[index],
                      currentUserId: user?.id ?? '',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupDetailScreen(groupId: groups[index].id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = cat == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategory = cat);
                },
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMyGroups) {
    return EmptyStateWidget(
      icon: isMyGroups ? Icons.group_off_outlined : Icons.search_off_outlined,
      title: isMyGroups
          ? 'You haven\'t joined any group yet'
          : 'No groups in this category',
      subtitle: isMyGroups
          ? 'Create or join a buying group to save more!'
          : 'Try a different category or create one',
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String productName = '';
    String category = 'Vegetables';
    double targetQty = 0;
    double pricePerKg = 0;
    String location = '';
    int days = 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Buying Group',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pool with other buyers to get bulk discounts',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 24),
                _formField(
                  hint: 'Group Name',
                  icon: Icons.group,
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 14),
                _formField(
                  hint: 'Product Name',
                  icon: Icons.eco_outlined,
                  onChanged: (v) => productName = v,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _inputDecoration(
                    'Category',
                    Icons.category_outlined,
                  ),
                  items: ['Vegetables', 'Fruits', 'Grains', 'Spices']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => category = v!,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _formField(
                        hint: 'Target Qty (KG)',
                        icon: Icons.scale,
                        keyboard: TextInputType.number,
                        onChanged: (v) => targetQty = double.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _formField(
                        hint: 'Price/KG (৳)',
                        icon: Icons.monetization_on_outlined,
                        keyboard: TextInputType.number,
                        onChanged: (v) => pricePerKg = double.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _formField(
                  hint: 'Delivery Location',
                  icon: Icons.location_on_outlined,
                  onChanged: (v) => location = v,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: days,
                  decoration: _inputDecoration(
                    'Group Active For',
                    Icons.timer_outlined,
                  ),
                  items: [3, 5, 7, 14, 30]
                      .map(
                        (d) =>
                            DropdownMenuItem(value: d, child: Text('$d days')),
                      )
                      .toList(),
                  onChanged: (v) => days = v!,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final user = context.read<AuthProvider>().currentUser;
                        final newGroup = BuyingGroup(
                          id: 'g${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          productName: productName,
                          category: category,
                          targetQuantity: targetQty,
                          filledQuantity: 0,
                          pricePerKg: pricePerKg,
                          deliveryLocation: location,
                          createdBy: user?.id ?? 'u1',
                          members: [
                            GroupMember(
                              userId: user?.id ?? 'u1',
                              name: user?.name ?? 'You',
                              contributionQuantity: 0,
                              phone: user?.phone ?? '',
                            ),
                          ],
                          messages: [],
                          expiryDate: DateTime.now().add(Duration(days: days)),
                        );
                        context.read<GroupProvider>().setGroups([
                          ...context.read<GroupProvider>().groups,
                          newGroup,
                        ]);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Group "$name" created! Share it with buyers.',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Create Group',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );

  Widget _formField({
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType keyboard = TextInputType.text,
  }) => TextFormField(
    keyboardType: keyboard,
    decoration: _inputDecoration(hint, icon),
    onChanged: onChanged,
    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
  );
}

// ─── Group Card Widget ────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final BuyingGroup group;
  final String currentUserId;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.currentUserId,
    required this.onTap,
  });

  Color get _statusColor {
    switch (group.status) {
      case GroupBuyStatus.open:
        return const Color(0xFF2E7D32);
      case GroupBuyStatus.active:
        return Colors.blue;
      case GroupBuyStatus.fulfilled:
        return Colors.grey;
      case GroupBuyStatus.cancelled:
        return Colors.red;
    }
  }

  String get _statusLabel {
    switch (group.status) {
      case GroupBuyStatus.open:
        return 'OPEN';
      case GroupBuyStatus.active:
        return 'ACTIVE';
      case GroupBuyStatus.fulfilled:
        return 'FULFILLED';
      case GroupBuyStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = group.filledQuantity / group.targetQuantity;
    final daysLeft = group.expiryDate.difference(DateTime.now()).inDays;
    final isMember = group.members.any((m) => m.userId == currentUserId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.productName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (isMember) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Joined',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${group.filledQuantity.toInt()} / ${group.targetQuantity.toInt()} KG filled',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Info row
                  Row(
                    children: [
                      _infoChip(
                        Icons.people_outline,
                        '${group.members.length} members',
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        Icons.monetization_on_outlined,
                        '৳${group.pricePerKg}/KG',
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        Icons.timer_outlined,
                        '${daysLeft}d left',
                        color: daysLeft <= 1 ? Colors.orange : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.deliveryLocation,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey[700]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
