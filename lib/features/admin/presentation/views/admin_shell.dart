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

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const UserManagementScreen(),
    const AdminOrdersScreen(),
    const AdminProductsScreen(),
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
    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Wallet')),
    NavigationRailDestination(icon: Icon(Icons.lock_outline), selectedIcon: Icon(Icons.lock), label: Text('Escrow')),
    NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analytics')),
    NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Reports')),
    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null // Hide AppBar on desktop
          : AppBar(
              title: Text('ChashiBhai Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.surface,
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
    );
  }
}
