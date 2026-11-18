import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/localization.dart';
import '../core/widgets/language_toggle_button.dart';
import 'account/presentation/state/app_state_provider.dart';

class SettingManagementScreen extends StatelessWidget {
  const SettingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr(languageCode)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr(languageCode)),
            subtitle: Text(languageCode == 'bn' ? 'বাংলা' : 'English'),
            trailing: const LanguageToggleButton(compact: true),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text('push_notifications'.tr(languageCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text('biometric'.tr(languageCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
