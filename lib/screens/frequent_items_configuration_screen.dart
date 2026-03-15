import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';

class FrequentItemsConfigurationScreen extends StatelessWidget {
  const FrequentItemsConfigurationScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final frequentItems = controller.getFrequentItemsForConfiguration();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.topArticles),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${controller.favoriteFrequentItemCount}/${controller.maxFavoriteFrequentItems}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: frequentItems.isEmpty
                    ? Center(child: Text(l10n.emptyFrequentItems))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: frequentItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = frequentItems[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.itemName),
                              subtitle: Text(
                                '${l10n.categoryLabel(item.category)} • ${item.occurrenceCount}x',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.isFavorite) ...[
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'favorite') {
                                        final updated = await controller.setFrequentItemFavorite(
                                          itemName: item.itemName,
                                          isFavorite: !item.isFavorite,
                                        );
                                        if (!updated && context.mounted && !item.isFavorite) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.favoriteLimitReached(
                                                  controller.maxFavoriteFrequentItems,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      final shouldDelete = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: Text(l10n.delete),
                                              content: Text(item.itemName),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, false),
                                                  child: Text(l10n.cancel),
                                                ),
                                                TextButton.icon(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Theme.of(dialogContext)
                                                        .colorScheme
                                                        .error,
                                                  ),
                                                  onPressed: () => Navigator.pop(dialogContext, true),
                                                  icon: const Icon(Icons.delete_outline),
                                                  label: Text(l10n.delete),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (!shouldDelete) {
                                        return;
                                      }

                                      await controller.deleteFrequentItem(item.itemName);
                                    },
                                    itemBuilder: (menuContext) => [
                                      PopupMenuItem<String>(
                                        value: 'favorite',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              item.isFavorite
                                                  ? Icons.favorite_outline_rounded
                                                  : Icons.favorite_border_rounded,
                                              size: 18,
                                              color: Theme.of(menuContext).colorScheme.error,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.isFavorite
                                                  ? l10n.removeFromFavorites
                                                  : l10n.addToFavorites,
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Theme.of(menuContext).colorScheme.error,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.delete,
                                              style: TextStyle(
                                                color: Theme.of(menuContext).colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
