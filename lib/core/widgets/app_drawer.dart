import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/localization.dart';
import 'language_toggle_button.dart';
import '../../features/account/presentation/state/app_state_provider.dart';

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

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            accountName: Text(userName ?? (languageCode == 'bn' ? 'ব্যবহারকারী' : 'User')),
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
            title: Text('home'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text('orders'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text('wallet'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text('settings'.tr(languageCode)),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          // Language Switch Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
