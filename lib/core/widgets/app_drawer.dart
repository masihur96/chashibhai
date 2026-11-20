import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../features/account/presentation/state/app_state_provider.dart';
import '../../features/account/presentation/views/profile_screen.dart';
import '../../features/account/presentation/views/settings_screen.dart';
import '../../features/buyer/presentation/views/negotiations_list_screen.dart';
import '../../features/buyer/presentation/views/my_bids_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../models/models.dart';
import '../utils/localization.dart';
import 'language_toggle_button.dart';

class AppDrawer extends StatelessWidget {
  final String? userName;
  final String? userPhone;
  final String? avatarUrl;
  final VoidCallback? onLogout;

  const AppDrawer({
    super.key,
    this.userName,
    this.userPhone,
    this.avatarUrl,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final String name = userName ??
        (user?.name.isNotEmpty == true && user!.name != 'User'
            ? user!.name
            : (user?.phone.isNotEmpty == true
                ? user!.phone
                : (languageCode == 'bn' ? 'ব্যবহারকারী' : 'User')));
    final String phone = userPhone ?? user?.phone ?? '';
    final String? avatar = avatarUrl ?? user?.avatarUrl;

    String roleName = 'buyer'.tr(languageCode);
    if (user?.role == UserRole.farmer) {
      roleName = 'farmer'.tr(languageCode);
    } else if (user?.role == UserRole.admin) {
      roleName = 'Admin';
    }

    return Drawer(
      child: Column(
        children: [
          // Header showing user data
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            accountName: Text(
              name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (phone.isNotEmpty)
                  Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleName.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
              child: (avatar == null || avatar.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 26, color: theme.primaryColor, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            onDetailsPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text('home'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text('profile'.tr(languageCode)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text('orders'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.handshake_outlined),
            title: const Text('Negotiations'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NegotiationsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('My Bids'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBidsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text('wallet'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text('settings'.tr(languageCode)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Divider(),
          // Language Switch Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: Colors.grey),
                    const SizedBox(width: 16),
                    Text(
                      'language'.tr(languageCode),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const LanguageToggleButton(compact: true),
              ],
            ),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('logout'.tr(languageCode), style: const TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              if (onLogout != null) {
                onLogout!();
              } else {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
