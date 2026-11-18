import 'package:flutter/material.dart';

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

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            accountName: Text(userName ?? 'ব্যবহারকারী'),
            accountEmail: Text(userPhone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (userName != null && userName!.isNotEmpty) ? userName![0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 24, color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('হোম (Home)'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('অর্ডারসমূহ (Orders)'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('ওয়ালেট (Wallet)'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('সেটিংস (Settings)'),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('লগআউট (Logout)', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onLogout?.call();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
