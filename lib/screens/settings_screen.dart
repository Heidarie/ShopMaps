import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_controller.dart';
import '../cloud/cloud_localizations.dart';
import '../cloud/supabase_config.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile.adaptive(
                  value: controller.removeCheckedShoppingItems,
                  title: Text(l10n.removeCheckedItemsSetting),
                  subtitle: Text(l10n.removeCheckedItemsSettingDescription),
                  onChanged: controller.setRemoveCheckedShoppingItems,
                ),
              ),
              if (_hasLegalLinks) ...[
                const SizedBox(height: 16),
                Text(
                  CloudLocalizations.of(context).text('legalInformation'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      if (SupabaseConfig.privacyPolicyUrl.isNotEmpty)
                        _LegalLinkTile(
                          icon: Icons.privacy_tip_outlined,
                          label: CloudLocalizations.of(
                            context,
                          ).text('privacyPolicy'),
                          uri: Uri.parse(SupabaseConfig.privacyPolicyUrl),
                        ),
                      if (SupabaseConfig.termsOfServiceUrl.isNotEmpty)
                        _LegalLinkTile(
                          icon: Icons.description_outlined,
                          label: CloudLocalizations.of(
                            context,
                          ).text('termsOfService'),
                          uri: Uri.parse(SupabaseConfig.termsOfServiceUrl),
                        ),
                      if (SupabaseConfig.accountDeletionUrl.isNotEmpty)
                        _LegalLinkTile(
                          icon: Icons.person_remove_outlined,
                          label: CloudLocalizations.of(
                            context,
                          ).text('accountDeletionPage'),
                          uri: Uri.parse(SupabaseConfig.accountDeletionUrl),
                        ),
                      if (SupabaseConfig.supportEmail.isNotEmpty)
                        _LegalLinkTile(
                          icon: Icons.support_agent_outlined,
                          label: CloudLocalizations.of(context).text('support'),
                          uri: Uri(
                            scheme: 'mailto',
                            path: SupabaseConfig.supportEmail,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  bool get _hasLegalLinks =>
      SupabaseConfig.privacyPolicyUrl.isNotEmpty ||
      SupabaseConfig.termsOfServiceUrl.isNotEmpty ||
      SupabaseConfig.accountDeletionUrl.isNotEmpty ||
      SupabaseConfig.supportEmail.isNotEmpty;
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({
    required this.icon,
    required this.label,
    required this.uri,
  });

  final IconData icon;
  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
  }
}
