import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import './admin_dashboard_screen.dart';
import './user_management_screen.dart';
import './admin_orders_screen.dart';
import './admin_products_screen.dart';
import './admin_wallet_screen.dart';
import './admin_escrow_screen.dart';
import './analytics_screen.dart';
import './reports_screen.dart';
import './admin_settings_screen.dart';
import './admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const UserManagementScreen(),
    const AdminOrdersScreen(),
    const AdminProductsScreen(),
    const AdminProfileScreen(),
    const AdminWalletScreen(),
    const AdminEscrowScreen(),
    const AnalyticsScreen(),
    const ReportsScreen(),
    const AdminSettingsScreen(),
  ];

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
    NavigationRailDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: Text('Orders')),
    NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Wallet')),
    NavigationRailDestination(icon: Icon(Icons.lock_outline), selectedIcon: Icon(Icons.lock), label: Text('Escrow')),
    NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analytics')),
    NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Reports')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isDesktop
          ? null // Hide AppBar on desktop
          : AppBar(
              title: _isSearchExpanded
                  ? Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    )
                  : Text((_destinations[_selectedIndex].label as Text).data ?? 'Admin Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              centerTitle: false,
              actions: [
                if (_isSearchExpanded)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = false;
                        _searchController.clear();
                      });
                    },
                  )
                else if (_selectedIndex != 4)
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = true;
                      });
                    },
                  ),
                if (!_isSearchExpanded && _selectedIndex != 4)
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    tooltip: 'Filter Options',
                    onPressed: () => _showFilterOptions(context, _selectedIndex),
                  ),
                const SizedBox(width: 8),
              ],
              elevation: 1,
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        Text('Admin Portal', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ..._destinations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dest = entry.value;
                    return ListTile(
                      leading: _selectedIndex == index ? dest.selectedIcon : dest.icon,
                      title: dest.label,
                      selected: _selectedIndex == index,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  }),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600),
              destinations: _destinations,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
                NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Orders'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
    );
  }

  void _showFilterOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _buildFilterContent(index);
      },
    );
  }

  Widget _buildFilterContent(int index) {
    String pageName = (_destinations[index].label as Text).data ?? 'Filter';
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$pageName Filters', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          if (index == 0) ...[
            _buildFilterOption('Today'),
            _buildFilterOption('This Week'),
            _buildFilterOption('This Month'),
          ] else if (index == 1) ...[
            _buildFilterOption('All Users'),
            _buildFilterOption('Farmers Only'),
            _buildFilterOption('Buyers Only'),
            _buildFilterOption('Pending Verification'),
          ] else if (index == 2) ...[
            _buildFilterOption('All Orders'),
            _buildFilterOption('Pending'),
            _buildFilterOption('Completed'),
            _buildFilterOption('Disputed'),
          ] else if (index == 3) ...[
            _buildFilterOption('All Products'),
            _buildFilterOption('In Stock'),
            _buildFilterOption('Out of Stock'),
            _buildFilterOption('High Demand'),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('No specific filters available for this page.', style: TextStyle(color: Colors.grey)),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

