import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_providers.dart';
import 'core/models.dart';
import 'screens/buyer/buyer_home.dart';
import 'screens/farmer/farmer_dashboard.dart';
import 'widgets/wallet_screen.dart';
import 'screens/buyer/post_demand_screen.dart';
import 'screens/buyer/product_details.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ChashiBhai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Forest Green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFFFA000), // Amber
          surface: const Color(0xFFF1F8E9),
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const RoleWrapper(),
    );
  }
}

class RoleWrapper extends ConsumerWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Masihur Rahman',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Level 4 Trader',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Switch Role'),
              subtitle: Text('Current: ${role.name.toUpperCase()}'),
              onTap: () {
                ref.read(userRoleProvider.notifier).state =
                    role == UserRole.buyer ? UserRole.farmer : UserRole.buyer;
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Transactions'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: role == UserRole.buyer ? const BuyerHomeScreen() : const FarmerDashboard(),
    );
  }
}
