import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
  });

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
            ],
          );
        },
      ),
    );
  }
}
