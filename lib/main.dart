import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import './features/auth/presentation/state/auth_provider.dart';
import './features/buyer/presentation/state/product_provider.dart';
import './features/group/presentation/state/group_provider.dart';
import './features/buyer/presentation/state/demand_provider.dart';
import './features/wallet/presentation/state/order_provider.dart';
import './features/account/presentation/state/app_state_provider.dart';
import './features/account/presentation/state/review_provider.dart';
import './features/admin/presentation/providers/admin_dashboard_provider.dart';
import './features/admin/presentation/providers/admin_user_provider.dart';

import './core/models/models.dart';
import './features/buyer/presentation/views/buyer_home.dart';
import './features/farmer/presentation/views/farmer_dashboard.dart';
import './features/wallet/presentation/views/wallet_screen.dart';
import './features/buyer/presentation/views/post_demand_screen.dart';
import './features/buyer/presentation/views/product_details.dart';
import './features/auth/presentation/views/login_screen.dart';
import './features/wallet/presentation/views/transactions_screen.dart';
import './features/account/presentation/views/profile_screen.dart';
import './features/account/presentation/views/settings_screen.dart';
import './features/account/presentation/views/support_screen.dart';
import './features/account/presentation/views/about_screen.dart';
import './features/group/presentation/views/groups_list_screen.dart';
import './core/utils/localization.dart';
import './core/widgets/language_toggle_button.dart';
import './features/admin/presentation/views/admin_shell.dart';
import './features/buyer/presentation/state/negotiation_provider.dart';
import './features/notification/presentation/state/notification_provider.dart';

import './core/utils/storage_service.dart';
import './features/splash/presentation/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => DemandProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NegotiationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;

    return MaterialApp(
      title: 'ChashiBhai',
      debugShowCheckedModeBanner: false,
      locale: Locale(languageCode),
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFFFA000),
          surface: const Color(0xFFF8F9FA),
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
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
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          indicatorColor: const Color(0xFF2E7D32).withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12);
            }
            return const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF2E7D32), size: 26);
            }
            return const IconThemeData(color: Colors.grey, size: 24);
          }),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    if (user == null) {
      return const LoginScreen();
    }

    return const RoleWrapper();
  }
}

class RoleWrapper extends StatelessWidget {
  final UserRole? initialRole;
  const RoleWrapper({super.key, this.initialRole});

  /// Navigates to the appropriate module based on role, replacing all prior routes:
  /// - UserRole.farmer -> Farmer module (FarmerDashboard)
  /// - UserRole.buyer  -> Buyer module (BuyerHomeScreen)
  /// - UserRole.admin  -> Admin module (AdminShell)
  static void navigate(BuildContext context, UserRole role) {
    Widget target;
    switch (role) {
      case UserRole.farmer:
        target = const RoleWrapper(initialRole: UserRole.farmer);
        break;
      case UserRole.buyer:
        target = const RoleWrapper(initialRole: UserRole.buyer);
        break;
      case UserRole.admin:
        target = const AdminShell();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final role = initialRole ?? authProvider.userRole;

    if (role == UserRole.admin) {
      return const AdminShell();
    }

    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Refined Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                              ? Text(
                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (user?.isVerified == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'verified'.tr(languageCode),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name.isNotEmpty == true && user!.name != 'User'
                        ? user!.name
                        : (user?.phone.isNotEmpty == true
                            ? user!.phone
                            : (languageCode == 'bn' ? 'ব্যবহারকারী' : 'User')),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.phone != null && user!.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          user.phone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (user?.email != null && user!.email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          user.email!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role == UserRole.farmer
                          ? 'farmer'.tr(languageCode).toUpperCase()
                          : user?.role == UserRole.admin
                              ? 'ADMIN'
                              : 'buyer'.tr(languageCode).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${'wallet_balance'.tr(languageCode)}: ৳${user?.walletBalance.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                    _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'wallet'.tr(languageCode),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'transactions'.tr(languageCode),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups_outlined,
                    title: 'Buying Groups',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupsListScreen()));
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 30),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'profile'.tr(languageCode),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'settings'.tr(languageCode),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 30),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'help_support'.tr(languageCode),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'about'.tr(languageCode),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language_rounded, color: Color(0xFF2E7D32), size: 24),
                            const SizedBox(width: 16),
                            Text(
                              'language'.tr(languageCode),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                        const LanguageToggleButton(compact: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer / Logout
            Padding(
              padding: const EdgeInsets.all(20),
              child: ListTile(
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                ),
                tileColor: Colors.red.withOpacity(0.05),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text(
                  'sign_out'.tr(languageCode),
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),

    ),
      body: role == UserRole.buyer 
          ? const BuyerHomeScreen() 
          : const FarmerDashboard(),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
