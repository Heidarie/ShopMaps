import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';

Future<bool> showDeleteCategoryPrompt({
  required BuildContext context,
  required String categoryLabel,
  required String rawCategoryName,
  required CategoryUsageSummary usage,
}) async {
  final l10n = AppLocalizations.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.deleteCategory),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(categoryLabel),
              if (categoryLabel != rawCategoryName) ...[
                const SizedBox(height: 4),
                Text(
                  rawCategoryName,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Text(l10n.deleteCategoryConfirmMessage),
              if (usage.groceryLists.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.deleteCategoryUsageLists,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final listUsage in usage.groceryLists)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '- ${listUsage.listName} (${l10n.itemsCount(listUsage.itemCount)})',
                    ),
                  ),
              ],
              if (usage.marketLayouts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.deleteCategoryUsageMarkets,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final layoutUsage in usage.marketLayouts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('- ${layoutUsage.layoutName}'),
                  ),
              ],
              if (usage.hasUsages) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.deleteCategoryRemovesItems,
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
